import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pocketbase/pocketbase.dart';
import 'event_participants_screen.dart';
import 'package:volunteervibe/services/pocketbase_service.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as latLng;
import 'package:geolocator/geolocator.dart';
import 'package:volunteervibe/services/location_service.dart';

class EventDetailsScreen extends StatefulWidget {
  final RecordModel event;

  const EventDetailsScreen({Key? key, required this.event}) : super(key: key);

  @override
  _EventDetailsScreenState createState() => _EventDetailsScreenState();
}

class _EventDetailsScreenState extends State<EventDetailsScreen> 
    with TickerProviderStateMixin {
  final PocketBaseService _pbService = PocketBaseService();
  final LocationService _locationService = LocationService();
  final _formKey = GlobalKey<FormState>();
  
  // Animation Controllers
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late AnimationController _scaleController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;
  
  bool _isEditing = false;
  bool _isLoading = false;
  bool _isSaving = false;

  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _locationController;
  late TextEditingController _maxParticipantController;
  late TextEditingController _pointsController;
  late DateTime _selectedDate;
  late TimeOfDay _selectedTime;
  late String _selectedCategoryId;
  late latLng.LatLng _selectedLocation;
  late MapController _mapController;

  List<RecordModel> _categories = [];

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _initializeControllers();
    _loadCategories();
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: Duration(milliseconds: 800),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: Duration(milliseconds: 600),
      vsync: this,
    );
    _scaleController = AnimationController(
      duration: Duration(milliseconds: 400),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );
    _slideAnimation = Tween<Offset>(begin: Offset(0, 0.3), end: Offset.zero).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
    );
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _scaleController, curve: Curves.elasticOut),
    );

    _fadeController.forward();
    _slideController.forward();
    _scaleController.forward();
  }

  void _initializeControllers() {
    _titleController = TextEditingController(text: widget.event.getStringValue('title') ?? '');
    _descriptionController = TextEditingController(text: widget.event.getStringValue('description') ?? '');
    
    final location = widget.event.data['location'] ?? {'lat': -7.2575, 'lon': 112.7521};
    _locationController = TextEditingController(text: '${location['lat']},${location['lon']}');
    _selectedLocation = latLng.LatLng(location['lat'] ?? -7.2575, location['lon'] ?? 112.7521);
    
    _maxParticipantController = TextEditingController(
      text: widget.event.getIntValue('max_participant', 0).toString()
    );
    _pointsController = TextEditingController(
      text: widget.event.getIntValue('point_event', 0).toString()
    );
    
    _selectedDate = DateTime.parse(
      widget.event.getStringValue('date') ?? DateTime.now().toIso8601String()
    );
    _selectedTime = TimeOfDay.fromDateTime(_selectedDate);
    _selectedCategoryId = widget.event.getStringValue('categories_id') ?? '';
    _mapController = MapController();
  }

  Future<void> _loadCategories() async {
    try {
      final categories = await _pbService.fetchEventCategories();
      setState(() {
        _categories = categories;
        if (_selectedCategoryId.isEmpty && categories.isNotEmpty) {
          _selectedCategoryId = categories.first.id;
        }
      });
    } catch (e) {
      print('Error loading categories: $e');
    }
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    _scaleController.dispose();
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _maxParticipantController.dispose();
    _pointsController.dispose();
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    
    try {
      final eventDateTime = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day,
        _selectedTime.hour,
        _selectedTime.minute,
      );

      final body = <String, dynamic>{
        "title": _titleController.text.trim(),
        "description": _descriptionController.text.trim(),
        "date": eventDateTime.toIso8601String(),
        "location": {
          "lat": _selectedLocation.latitude, 
          "lon": _selectedLocation.longitude
        },
        "max_participant": int.tryParse(_maxParticipantController.text) ?? 0,
        "point_event": int.tryParse(_pointsController.text) ?? 0,
        "categories_id": _selectedCategoryId,
      };

      await _pbService.updateEvent(widget.event.id, body);
      
      setState(() => _isEditing = false);
      
      // Success animation
      _scaleController.reset();
      _scaleController.forward();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 12),
              Text('Event updated successfully!'),
            ],
          ),
          backgroundColor: Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.error, color: Colors.white),
              SizedBox(width: 12),
              Expanded(child: Text('Failed to update event: $e')),
            ],
          ),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    } finally {
      setState(() => _isSaving = false);
    }
  }

  Future<void> _deleteEvent() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.warning, color: Colors.red, size: 28),
            SizedBox(width: 12),
            Text('Delete Event'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Are you sure you want to delete this event?',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            SizedBox(height: 8),
            Text(
              'This action cannot be undone and all participant data will be lost.',
              style: TextStyle(color: Color(0xFF718096), fontSize: 14),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel'),
            style: TextButton.styleFrom(
              foregroundColor: Color(0xFF718096),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      setState(() => _isLoading = true);
      try {
        await _pbService.deleteEvent(widget.event.id);
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 12),
                Text('Event deleted successfully!'),
              ],
            ),
            backgroundColor: Color(0xFF10B981),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.error, color: Colors.white),
                SizedBox(width: 12),
                Expanded(child: Text('Failed to delete event: $e')),
              ],
            ),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

  void _updateLocation(latLng.LatLng latLng) {
    if (!_isEditing) return;
    setState(() {
      _selectedLocation = latLng;
      _locationController.text = '${latLng.latitude.toStringAsFixed(6)},${latLng.longitude.toStringAsFixed(6)}';
      _mapController.move(latLng, _mapController.camera.zoom);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF8FAFC),
      body: CustomScrollView(
        slivers: [
          _buildSliverAppBar(),
          SliverToBoxAdapter(
            child: _isLoading
                ? _buildLoadingState()
                : FadeTransition(
                    opacity: _fadeAnimation,
                    child: SlideTransition(
                      position: _slideAnimation,
                      child: _buildContent(),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 150,
      floating: false,
      pinned: true,
      backgroundColor: Color(0xFF6C63FF),
      foregroundColor: Colors.white,
      elevation: 0,
      leading: IconButton(
        icon: Icon(Icons.arrow_back_ios, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        if (!_isEditing)
          IconButton(
            icon: Icon(Icons.edit, color: Colors.white),
            onPressed: () => setState(() => _isEditing = true),
          ),
        if (_isEditing)
          IconButton(
            icon: Icon(Icons.close, color: Colors.white),
            onPressed: () => setState(() => _isEditing = false),
          ),
        PopupMenuButton<String>(
          icon: Icon(Icons.more_vert, color: Colors.white),
          onSelected: (value) {
            if (value == 'delete') _deleteEvent();
          },
          itemBuilder: (context) => [
            PopupMenuItem(
              value: 'delete',
              child: Row(
                children: [
                  Icon(Icons.delete, color: Colors.red, size: 20),
                  SizedBox(width: 12),
                  Text('Delete Event', style: TextStyle(color: Colors.red)),
                ],
              ),
            ),
          ],
        ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF6C63FF),
                Color(0xFF9F7AEA),
                Color(0xFF667EEA),
              ],
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.event, color: Colors.white, size: 16),
                        SizedBox(width: 6),
                        Text(
                          'Event Management',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Container(
      height: MediaQuery.of(context).size.height * 0.6,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6C63FF)),
            ),
            SizedBox(height: 16),
            Text(
              'Processing...',
              style: TextStyle(
                color: Color(0xFF718096),
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent() {
    return Padding(
      padding: EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('Event Information', Icons.info_outline),
            SizedBox(height: 20),
            _buildEnhancedTextField(
              controller: _titleController,
              label: 'Event Title',
              icon: Icons.title,
              readOnly: !_isEditing,
              validator: (value) => value?.trim().isEmpty ?? true ? 'Title is required' : null,
            ),
            SizedBox(height: 20),
            _buildEnhancedTextField(
              controller: _descriptionController,
              label: 'Description',
              icon: Icons.description,
              readOnly: !_isEditing,
              validator: (value) => value?.trim().isEmpty ?? true ? 'Description is required' : null,
            ),
            SizedBox(height: 32),
            _buildSectionHeader('Location & Details', Icons.location_on),
            SizedBox(height: 20),
            _buildLocationField(),
            SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: _buildEnhancedTextField(
                    controller: _maxParticipantController,
                    label: 'Max Participants',
                    icon: Icons.people,
                    keyboardType: TextInputType.number,
                    readOnly: !_isEditing,
                    validator: (value) {
                      if (value?.trim().isEmpty ?? true) return 'Required';
                      final num = int.tryParse(value!);
                      if (num == null || num <= 0) return 'Must be > 0';
                      return null;
                    },
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: _buildEnhancedTextField(
                    controller: _pointsController,
                    label: 'Points Reward',
                    icon: Icons.star,
                    keyboardType: TextInputType.number,
                    readOnly: !_isEditing,
                    validator: (value) {
                      if (value?.trim().isEmpty ?? true) return 'Required';
                      final num = int.tryParse(value!);
                      if (num == null || num < 0) return 'Must be ≥ 0';
                      return null;
                    },
                  ),
                ),
              ],
            ),
            SizedBox(height: 20),
            _buildDateTimeField(),
            SizedBox(height: 20),
            _buildCategorySelector(),
            SizedBox(height: 32),
            _buildActionButtons(),
            SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Color(0xFF6C63FF).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: Color(0xFF6C63FF), size: 20),
        ),
        SizedBox(width: 12),
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2D3748),
          ),
        ),
      ],
    );
  }

  Widget _buildEnhancedTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    int maxLines = 1,
    bool readOnly = false,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF4A5568),
          ),
        ),
        SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          readOnly: readOnly,
          validator: readOnly ? null : validator,
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: Color(0xFF718096)),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: Color(0xFFE2E8F0)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: Color(0xFFE2E8F0)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: Color(0xFF6C63FF), width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: Colors.red, width: 2),
            ),
            filled: true,
            fillColor: readOnly ? Color(0xFFF8FAFC) : Colors.white,
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
        ),
      ],
    );
  }

  Widget _buildLocationField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Location',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF4A5568),
          ),
        ),
        SizedBox(height: 8),
        if (!_isEditing)
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                Icon(Icons.location_on, color: Color(0xFF718096)),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _locationController.text.isEmpty ? 'Not set' : _locationController.text,
                    style: TextStyle(fontSize: 16, color: Color(0xFF2D3748)),
                  ),
                ),
              ],
            ),
          ),
        if (_isEditing)
          Column(
            children: [
              Container(
                height: 250,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Color(0xFFE2E8F0)),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: FlutterMap(
                    mapController: _mapController,
                    options: MapOptions(
                      center: _selectedLocation,
                      zoom: 13.0,
                      onTap: (_, latLngPoint) => _updateLocation(latLngPoint),
                    ),
                    children: [
                      TileLayer(
                        urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        subdomains: ['a', 'b', 'c'],
                      ),
                      MarkerLayer(
                        markers: [
                          Marker(
                            point: _selectedLocation,
                            width: 80.0,
                            height: 80.0,
                            child: Icon(
                              Icons.location_pin,
                              color: Color(0xFF6C63FF),
                              size: 40.0,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 12),
              TextFormField(
                controller: _locationController,
                readOnly: true,
                decoration: InputDecoration(
                  prefixIcon: Icon(Icons.location_on, color: Color(0xFF718096)),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                    borderSide: BorderSide(color: Color(0xFFE2E8F0)),
                  ),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                ),
                validator: (value) => value?.isEmpty ?? true ? 'Location is required' : null,
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildDateTimeField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Date & Time',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF4A5568),
          ),
        ),
        SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: _isEditing ? () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate,
                    firstDate: DateTime.now(),
                    lastDate: DateTime(2030),
                    builder: (context, child) {
                      return Theme(
                        data: Theme.of(context).copyWith(
                          colorScheme: ColorScheme.light(
                            primary: Color(0xFF6C63FF),
                          ),
                        ),
                        child: child!,
                      );
                    },
                  );
                  if (picked != null) setState(() => _selectedDate = picked);
                } : null,
                child: Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _isEditing ? Colors.white : Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.calendar_today, color: Color(0xFF718096)),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          DateFormat('EEEE, MMMM dd, yyyy').format(_selectedDate),
                          style: TextStyle(fontSize: 16, color: Color(0xFF2D3748)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: InkWell(
                onTap: _isEditing ? () async {
                  final picked = await showTimePicker(
                    context: context,
                    initialTime: _selectedTime,
                    builder: (context, child) {
                      return Theme(
                        data: Theme.of(context).copyWith(
                          colorScheme: ColorScheme.light(
                            primary: Color(0xFF6C63FF),
                          ),
                        ),
                        child: child!,
                      );
                    },
                  );
                  if (picked != null) setState(() => _selectedTime = picked);
                } : null,
                child: Container(
                  padding: EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _isEditing ? Colors.white : Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Color(0xFFE2E8F0)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.access_time, color: Color(0xFF718096)),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _selectedTime.format(context),
                          style: TextStyle(fontSize: 16, color: Color(0xFF2D3748)),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCategorySelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Category',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Color(0xFF4A5568),
          ),
        ),
        SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _selectedCategoryId.isNotEmpty ? _selectedCategoryId : null,
          items: _categories.map((category) {
            return DropdownMenuItem<String>(
              value: category.id,
              child: Text(category.getStringValue('name') ?? 'Unknown'),
            );
          }).toList(),
          onChanged: _isEditing
              ? (value) => setState(() => _selectedCategoryId = value ?? '')
              : null,
          decoration: InputDecoration(
            prefixIcon: Icon(Icons.category, color: Color(0xFF718096)),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: Color(0xFFE2E8F0)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: Color(0xFFE2E8F0)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: BorderSide(color: Color(0xFF6C63FF), width: 2),
            ),
            filled: true,
            fillColor: _isEditing ? Colors.white : Color(0xFFF8FAFC),
            contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          ),
          validator: _isEditing ? (value) => value == null ? 'Category is required' : null : null,
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    if (!_isEditing) {
      return Column(
        children: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => setState(() => _isEditing = true),
              icon: Icon(Icons.edit, size: 20),
              label: Text('Edit Event'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF6C63FF),
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 2,
              ),
            ),
          ),
          SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EventParticipantsScreen(event: widget.event),
                  ),
                );
              },
              icon: Icon(Icons.people, size: 20),
              label: Text('View Participants'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Color(0xFF6C63FF),
                side: BorderSide(color: Color(0xFF6C63FF), width: 2),
                padding: EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
        ],
      );
    }

    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: () => setState(() => _isEditing = false),
            style: OutlinedButton.styleFrom(
              foregroundColor: Color(0xFF718096),
              side: BorderSide(color: Color(0xFF718096)),
              padding: EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: Text('Cancel'),
          ),
        ),
        SizedBox(width: 16),
        Expanded(
          flex: 2,
          child: ElevatedButton(
            onPressed: _isSaving ? null : _saveChanges,
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF6C63FF),
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 2,
            ),
            child: _isSaving
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 2,
                    ),
                  )
                : Text(
                    'Save Changes',
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
          ),
        ),
      ],
    );
  }
}