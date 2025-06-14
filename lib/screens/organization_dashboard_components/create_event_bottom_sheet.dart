import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:volunteervibe/services/pocketbase_service.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as latlng;
import 'package:volunteervibe/services/location_service.dart';

class CreateEventBottomSheet extends StatefulWidget {
  final RecordModel organization;
  final VoidCallback onEventCreated;

  const CreateEventBottomSheet({
    Key? key,
    required this.organization,
    required this.onEventCreated,
  }) : super(key: key);

  @override
  _CreateEventBottomSheetState createState() => _CreateEventBottomSheetState();
}

class _CreateEventBottomSheetState extends State<CreateEventBottomSheet> {
  final PocketBaseService _pbService = PocketBaseService();
  final _formKey = GlobalKey<FormState>();
  final _pageController = PageController();
  
  final LocationService _locationService = LocationService();
  final MapController _mapController = MapController();
  
  // Controllers
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _maxParticipantController = TextEditingController();
  final _pointsController = TextEditingController();
  final _durationController = TextEditingController();

  // State
  int _currentStep = 0;
  bool _isLoading = false;
  DateTime _selectedDate = DateTime.now().add(Duration(days: 1));
  TimeOfDay _selectedTime = TimeOfDay(hour: 9, minute: 0);
  
  List<RecordModel> _fetchedCategories = [];
  String? _selectedCategoryId;
  
  latlng.LatLng _selectedLocation = latlng.LatLng(-7.2575, 112.7521); // Default: Surabaya
  String _locationAddress = "Memuat lokasi...";

  @override
  void initState() {
    super.initState();
    _initializeData();
  }
  
  void _initializeData() async {
    await _loadCategories();
    await _initializeLocation();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _maxParticipantController.dispose();
    _pointsController.dispose();
    _durationController.dispose();
    _pageController.dispose();
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _loadCategories() async {
    final categories = await _pbService.fetchEventCategories();
    if (mounted) {
      setState(() {
        _fetchedCategories = categories;
      });
    }
  }

  Future<void> _initializeLocation() async {
    try {
      final position = await _locationService.getCurrentPosition();
      if (mounted) {
        setState(() {
          _selectedLocation = latlng.LatLng(position.latitude, position.longitude);
          _locationAddress = "Lokasi Anda saat ini terdeteksi";
        });
        _mapController.move(_selectedLocation, 15.0);
      }
    } catch (e) {
      print("Could not get current location: $e");
      if (mounted) {
        setState(() {
          _locationAddress = "Gagal mendapatkan lokasi, gunakan default.";
        });
      }
    }
  }
  
  void _updateLocation(latlng.LatLng location) {
    setState(() {
      _selectedLocation = location;
      _locationAddress = "${location.latitude.toStringAsFixed(5)}, ${location.longitude.toStringAsFixed(5)}";
    });
    _mapController.move(location, _mapController.camera.zoom);
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Container(
        height: MediaQuery.of(context).size.height * 0.9,
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        child: Column(
          children: [
            _buildHeader(),
            _buildProgressIndicator(),
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: NeverScrollableScrollPhysics(),
                children: [
                  _buildBasicInfoStep(),
                  _buildDetailsStep(),
                  _buildDateTimeStep(),
                  _buildReviewStep(),
                ],
              ),
            ),
            _buildBottomButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: EdgeInsets.fromLTRB(24, 24, 16, 24),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(color: Color(0xFF6C63FF).withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
            child: Icon(Icons.event_note, color: Color(0xFF6C63FF), size: 24),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Create New Event', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF2D3748))),
                Text('Step ${_currentStep + 1} of 4', style: TextStyle(fontSize: 14, color: Color(0xFF718096))),
              ],
            ),
          ),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(Icons.close, color: Color(0xFF718096)),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        children: List.generate(4, (index) {
          return Expanded(
            child: AnimatedContainer(
              duration: Duration(milliseconds: 300),
              height: 4,
              margin: EdgeInsets.symmetric(horizontal: 2),
              decoration: BoxDecoration(
                color: index <= _currentStep ? Color(0xFF6C63FF) : Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _buildBasicInfoStep() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Basic Information', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2D3748))),
          SizedBox(height: 24),
          _buildTextField(
            controller: _titleController,
            label: 'Event Title',
            hint: 'Enter a compelling event title',
            icon: Icons.title,
            validator: (value) => value == null || value.isEmpty ? 'Title is required' : null,
          ),
          SizedBox(height: 20),
          _buildTextField(
            controller: _descriptionController,
            label: 'Description',
            hint: 'Describe what volunteers will do',
            icon: Icons.description,
            maxLines: 4,
            validator: (value) => value == null || value.isEmpty ? 'Description is required' : null,
          ),
          SizedBox(height: 20),
          _buildCategorySelector(),
        ],
      ),
    );
  }

  Widget _buildDetailsStep() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Event Details & Location', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          SizedBox(height: 24),
          _buildLocationPicker(),
          SizedBox(height: 20),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _buildTextField(
                  controller: _maxParticipantController,
                  label: 'Max Participants',
                  hint: 'e.g., 50',
                  icon: Icons.people,
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Required';
                    if (int.tryParse(value) == null) return 'Invalid number';
                    return null;
                  },
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: _buildTextField(
                  controller: _durationController,
                  label: 'Duration (Hours)',
                  hint: 'e.g., 3',
                  icon: Icons.hourglass_bottom,
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value == null || value.isEmpty) return 'Required';
                    if (int.tryParse(value) == null) return 'Invalid number';
                    return null;
                  },
                ),
              ),
            ],
          ),
          SizedBox(height: 20),
          _buildTextField(
            controller: _pointsController,
            label: 'Points Reward',
            hint: 'e.g., 100',
            icon: Icons.star,
            keyboardType: TextInputType.number,
            validator: (value) {
              if (value == null || value.isEmpty) return 'Required';
              if (int.tryParse(value) == null) return 'Invalid number';
              return null;
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDateTimeStep() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Date & Time', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2D3748))),
          SizedBox(height: 24),
          _buildDateTimeSelector(),
        ],
      ),
    );
  }

  Widget _buildReviewStep() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Review & Create', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2D3748))),
          SizedBox(height: 24),
          _buildReviewCard(),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? hint,
    required IconData icon,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF4A5568))),
        SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, color: Color(0xFF718096)),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Color(0xFFE2E8F0))),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Color(0xFFE2E8F0))),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Color(0xFF6C63FF), width: 2)),
            errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.red, width: 1.5)),
            focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.red, width: 2)),
            filled: true,
            fillColor: Colors.white,
          ),
        ),
      ],
    );
  }
  
  Widget _buildLocationPicker() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Pilih Lokasi Event (Tap Peta)", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF4A5568))),
        SizedBox(height: 8),
        Container(
          height: 250,
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade300)),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: _selectedLocation,
                initialZoom: 13.0,
                onTap: (_, point) => _updateLocation(point),
              ),
              children: [
                TileLayer(urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png'),
                MarkerLayer(
                  markers: [Marker(point: _selectedLocation, child: Icon(Icons.location_pin, color: Colors.red, size: 40.0))],
                ),
              ],
            ),
          ),
        ),
        SizedBox(height: 8),
        Text("Lokasi: $_locationAddress", style: TextStyle(color: Colors.grey.shade700, fontStyle: FontStyle.italic)),
      ],
    );
  }

  Widget _buildCategorySelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Category', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF4A5568))),
        SizedBox(height: 12),
        if (_fetchedCategories.isEmpty)
          Center(child: CircularProgressIndicator(color: Color(0xFF6C63FF)))
        else
          DropdownButtonFormField<String>(
            value: _selectedCategoryId,
            hint: Text('Select a category'),
            items: _fetchedCategories.map((category) => DropdownMenuItem<String>(
              value: category.id,
              child: Text(category.getStringValue('name')),
            )).toList(),
            onChanged: (value) => setState(() => _selectedCategoryId = value),
            validator: (value) => value == null ? 'Category is required' : null,
            decoration: InputDecoration(
              prefixIcon: Icon(Icons.category, color: Color(0xFF718096)),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Color(0xFFE2E8F0))),
            ),
          ),
      ],
    );
  }

  Widget _buildDateTimeSelector() {
    return Row(
      children: [
        Expanded(child: _buildDateSelector()),
        SizedBox(width: 16),
        Expanded(child: _buildTimeSelector()),
      ],
    );
  }

  Widget _buildDateSelector() {
    return InkWell(
      onTap: _selectDate,
      child: Container(
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade300)),
        child: Row(
          children: [
            Icon(Icons.calendar_today, color: Color(0xFF6C63FF)),
            SizedBox(width: 8),
            Expanded(child: Text(DateFormat('dd MMM yy').format(_selectedDate), style: TextStyle(fontSize: 16))),
          ],
        ),
      ),
    );
  }
  
  Widget _buildTimeSelector() {
    return InkWell(
      onTap: _selectTime,
      child: Container(
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade300)),
        child: Row(
          children: [
            Icon(Icons.access_time, color: Color(0xFF6C63FF)),
            SizedBox(width: 8),
            Expanded(child: Text(_selectedTime.format(context), style: TextStyle(fontSize: 16))),
          ],
        ),
      ),
    );
  }

  Widget _buildReviewCard() {
    final eventDateTime = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day, _selectedTime.hour, _selectedTime.minute);
    final categoryName = _fetchedCategories.firstWhere((cat) => cat.id == _selectedCategoryId, orElse: () => RecordModel()).getStringValue('name', 'N/A');
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(color: Color(0xFFF8FAFC), borderRadius: BorderRadius.circular(16), border: Border.all(color: Color(0xFFE2E8F0))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(_titleController.text, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF2D3748))),
          SizedBox(height: 8),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(color: Color(0xFF6C63FF).withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
            child: Text(categoryName, style: TextStyle(color: Color(0xFF6C63FF), fontSize: 12, fontWeight: FontWeight.w600)),
          ),
          SizedBox(height: 16),
          Text(_descriptionController.text, style: TextStyle(color: Color(0xFF4A5568), fontSize: 14, height: 1.5)),
          SizedBox(height: 20),
          _buildReviewItem(Icons.calendar_today, 'Date & Time', DateFormat('MMM dd, yy • HH:mm').format(eventDateTime)),
          _buildReviewItem(Icons.location_on, 'Location', _locationAddress),
          _buildReviewItem(Icons.people, 'Max Participants', _maxParticipantController.text),
          _buildReviewItem(Icons.star, 'Points Reward', _pointsController.text),
          _buildReviewItem(Icons.hourglass_bottom, 'Duration', '${_durationController.text} hours'),
        ],
      ),
    );
  }

  Widget _buildReviewItem(IconData icon, String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Icon(icon, size: 16, color: Color(0xFF718096)),
          SizedBox(width: 12),
          Text(label, style: TextStyle(color: Color(0xFF718096), fontSize: 14)),
          Spacer(),
          Expanded(child: Text(value, style: TextStyle(color: Color(0xFF2D3748), fontSize: 14, fontWeight: FontWeight.w500), textAlign: TextAlign.end, overflow: TextOverflow.ellipsis)),
        ],
      ),
    );
  }

  Widget _buildBottomButtons() {
    return Container(
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: Color(0xFFE2E8F0)))),
      child: Row(
        children: [
          if (_currentStep > 0)
            Expanded(
              child: OutlinedButton(onPressed: _previousStep, child: Text('Previous'), style: OutlinedButton.styleFrom(side: BorderSide(color: Color(0xFF6C63FF)), foregroundColor: Color(0xFF6C63FF), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), padding: EdgeInsets.symmetric(vertical: 16))),
            ),
          if (_currentStep > 0) SizedBox(width: 16),
          Expanded(
            child: ElevatedButton(
              onPressed: _isLoading ? null : _nextStep,
              style: ElevatedButton.styleFrom(backgroundColor: Color(0xFF6C63FF), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), padding: EdgeInsets.symmetric(vertical: 16)),
              child: _isLoading
                  ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : Text(_currentStep == 3 ? 'Create Event' : 'Next', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }

  void _nextStep() {
    if (!_formKey.currentState!.validate()) {
       ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Please correct the errors before proceeding.'), backgroundColor: Colors.orange));
       return;
    }
    if (_currentStep == 0 && _selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Please select a category.'), backgroundColor: Colors.orange));
      return;
    }
    if (_currentStep < 3) {
      setState(() => _currentStep++);
      _pageController.animateToPage(_currentStep, duration: Duration(milliseconds: 400), curve: Curves.easeInOut);
    } else {
      _createEvent();
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() => _currentStep--);
      _pageController.animateToPage(_currentStep, duration: Duration(milliseconds: 400), curve: Curves.easeInOut);
    }
  }
  
  Future<void> _selectDate() async {
    final pickedDate = await showDatePicker(context: context, initialDate: _selectedDate, firstDate: DateTime.now(), lastDate: DateTime(2030), builder: (context, child) => Theme(data: Theme.of(context).copyWith(colorScheme: ColorScheme.light(primary: Color(0xFF6C63FF))), child: child!));
    if (pickedDate != null) setState(() => _selectedDate = pickedDate);
  }

  Future<void> _selectTime() async {
    final pickedTime = await showTimePicker(context: context, initialTime: _selectedTime, builder: (context, child) => Theme(data: Theme.of(context).copyWith(colorScheme: ColorScheme.light(primary: Color(0xFF6C63FF))), child: child!));
    if (pickedTime != null) setState(() => _selectedTime = pickedTime);
  }

  Future<void> _createEvent() async {
    if (!_formKey.currentState!.validate() || _selectedCategoryId == null) return;
    
    setState(() => _isLoading = true);
    try {
      final eventDateTime = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day, _selectedTime.hour, _selectedTime.minute);
      
      final body = <String, dynamic>{
        "title": _titleController.text,
        "description": _descriptionController.text,
        "date": eventDateTime.toIso8601String(),
        "location": "${_selectedLocation.latitude},${_selectedLocation.longitude}",
        "max_participant": int.tryParse(_maxParticipantController.text) ?? 0,
        "point_event": int.tryParse(_pointsController.text) ?? 0,
        "duration_hours": int.tryParse(_durationController.text) ?? 0,
        "organization_id": widget.organization.id,
        "categories_id": _selectedCategoryId,
      };

      final record = await _pbService.createEvent(body: body);

      if (record != null) {
        Navigator.pop(context);
        widget.onEventCreated();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Event created successfully!'), backgroundColor: Color(0xFF10B981), behavior: SnackBarBehavior.floating),
        );
      } else {
        throw Exception('Failed to create event record.');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal membuat event: Periksa kembali format input Anda.'), backgroundColor: Colors.red, behavior: SnackBarBehavior.floating),
      );
    } finally {
      if(mounted) setState(() => _isLoading = false);
    }
  }
}