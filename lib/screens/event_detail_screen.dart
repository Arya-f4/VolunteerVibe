import 'package:flutter/material.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:intl/intl.dart';
import 'package:volunteervibe/pocketbase_client.dart';
import 'package:volunteervibe/services/pocketbase_service.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart' as latlng;

class EventDetailScreen extends StatefulWidget {
  final RecordModel event;

  const EventDetailScreen({Key? key, required this.event}) : super(key: key);

  @override
  State<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends State<EventDetailScreen> {
  final PocketBaseService _pbService = PocketBaseService();
  late RecordModel _currentEvent;
  
  bool _isLoading = true;
  bool _isProcessing = false;
  String? _userStatus;

  final MapController _mapController = MapController();
  latlng.LatLng? _eventLocation;

  @override
  void initState() {
    super.initState();
    _currentEvent = widget.event;
    _initializeData();
  }
  
  void _initializeData() {
    _parseLocation();
    _checkUserStatus();
  }
  
  @override
  void dispose() {
    _mapController.dispose();
    super.dispose();
  }

  void _parseLocation() {
    final locationString = _currentEvent.getStringValue('location');
    if (locationString.isNotEmpty) {
      try {
        final parts = locationString.split(',');
        if (parts.length == 2) {
          final lat = double.tryParse(parts[0].trim());
          final lon = double.tryParse(parts[1].trim());
          if (lat != null && lon != null) {
            _eventLocation = latlng.LatLng(lat, lon);
          }
        }
      } catch (e) {
        print("Failed to parse location string: $e");
        _eventLocation = null;
      }
    }
  }

  Future<void> _checkUserStatus() async {
    setState(() => _isLoading = true);
    try {
      final userId = pb.authStore.model?.id;
      if (userId == null) return;
      final result = await _pbService.checkUserRegistrationStatus(_currentEvent.id, userId);
      if (mounted) {
        setState(() {
          _userStatus = result['status'];
        });
      }
    } catch (e) {
      print("Failed to check user status: $e");
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _joinEvent() async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);
    try {
      final userId = pb.authStore.model.id;
      final eventId = _currentEvent.id;

      final existingStatus = await _pbService.checkUserRegistrationStatus(eventId, userId);
      if (existingStatus['status'] != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Anda sudah mengirim permintaan untuk acara ini."), backgroundColor: Colors.orange),
        );
        setState(() {
          _userStatus = existingStatus['status'];
          _isProcessing = false;
        });
        return;
      }
      
      await _pbService.createEventSession(eventId: eventId, userId: userId);
      setState(() => _userStatus = 'waiting');
      Navigator.of(context).pop();
      _showSuccessDialog(context);
    } catch (e) {
      print('Error joining event: $e');
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Gagal mengirim permintaan. Coba lagi."), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final organization = _currentEvent.expand['organization_id']?.first;
    final category = _currentEvent.expand['categories_id']?.first;
    final title = _currentEvent.getStringValue('title', 'No Title');
    final description = _currentEvent.getStringValue('description', 'No description available.');
    final orgName = organization?.getStringValue('name', 'Unknown Organization') ?? 'Unknown Organization';
    final categoryName = category?.getStringValue('name', 'Uncategorized') ?? 'Uncategorized';
    
    final maxParticipants = _currentEvent.getIntValue('max_participant', 0);
    final currentParticipants = _currentEvent.getListValue<String>('participant_id').length;
    
    final DateTime eventDate = DateTime.parse(_currentEvent.getStringValue('date'));
    final String dateFormatted = DateFormat('EEEE, MMM dd, yy').format(eventDate.toLocal());
    final String timeFormatted = DateFormat('h:mm a').format(eventDate.toLocal());

    String? orgAvatarUrl;
    if (organization != null) {
      final orgAvatarFilename = organization.getStringValue('avatar');
      if (orgAvatarFilename.isNotEmpty) {
        orgAvatarUrl = pb.getFileUrl(organization, orgAvatarFilename).toString();
      }
    }

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 250,
            pinned: true,
            stretch: true,
            backgroundColor: Color(0xFF1E293B),
            leading: IconButton(
              icon: Icon(Icons.arrow_back_ios, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              IconButton(icon: Icon(Icons.share, color: Colors.white), onPressed: () {}),
              IconButton(icon: Icon(Icons.favorite_border, color: Colors.white), onPressed: () {}),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  if (orgAvatarUrl != null)
                    Image.network(
                      orgAvatarUrl,
                      fit: BoxFit.cover,
                      loadingBuilder: (context, child, loadingProgress) {
                        if (loadingProgress == null) return child;
                        return Center(child: CircularProgressIndicator(color: Colors.white));
                      },
                      errorBuilder: (context, error, stackTrace) => Container(color: Colors.grey.shade400, child: Icon(Icons.business_rounded, size: 80, color: Colors.white.withOpacity(0.7))),
                    )
                  else
                    Container(color: Colors.grey.shade400, child: Icon(Icons.business_rounded, size: 80, color: Colors.white.withOpacity(0.7))),
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Colors.transparent, Colors.black54],
                        stops: [0.5, 1.0],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF2D3748))),
                  SizedBox(height: 8),
                  Text('Organized by $orgName', style: TextStyle(fontSize: 16, color: Color(0xFF718096), fontWeight: FontWeight.w500)),
                  SizedBox(height: 16),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(color: Color(0xFF6C63FF).withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                    child: Text(categoryName, style: TextStyle(color: Color(0xFF6C63FF), fontWeight: FontWeight.w600)),
                  ),
                  SizedBox(height: 24),
                  _buildDateTimeCard(dateFormatted, timeFormatted),
                  SizedBox(height: 24),
                  if (_eventLocation != null) _buildLocationMap(),
                  SizedBox(height: 24),
                  _buildParticipantsCard(currentParticipants, maxParticipants),
                  SizedBox(height: 24),
                  _buildDescriptionCard(description),
                  SizedBox(height: 32),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _isLoading
          ? Padding(
              padding: const EdgeInsets.all(24.0),
              child: Center(heightFactor: 1.0, child: CircularProgressIndicator(color: Color(0xFF6C63FF))),
            )
          : _buildBottomBar(context, title),
    );
  }

  Widget _buildDateTimeCard(String date, String time) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: Offset(0, 4))]),
      child: Column(
        children: [
          _buildInfoRow(Icons.calendar_today_outlined, 'Date', date),
          SizedBox(height: 16),
          _buildInfoRow(Icons.access_time_outlined, 'Time', time),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Container(width: 40, height: 40, decoration: BoxDecoration(color: Color(0xFF6C63FF).withOpacity(0.1), borderRadius: BorderRadius.circular(20)), child: Icon(icon, color: Color(0xFF6C63FF), size: 20)),
        SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(fontSize: 12, color: Color(0xFF718096), fontWeight: FontWeight.w500)),
              Text(value, style: TextStyle(fontSize: 16, color: Color(0xFF2D3748), fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLocationMap() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [Icon(Icons.location_on_outlined, color: Color(0xFF6C63FF)), SizedBox(width: 8), Text('Location', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2D3748)))]),
        SizedBox(height: 16),
        Container(
          height: 200,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: Offset(0, 4))]
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: _eventLocation!,
                initialZoom: 15.0,
                interactionOptions: InteractionOptions(flags: InteractiveFlag.none), // Membuat peta tidak interaktif
              ),
              children: [
                TileLayer(urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png'),
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _eventLocation!,
                      width: 80.0,
                      height: 80.0,
                      child: Icon(Icons.location_pin, color: Colors.red, size: 40),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildParticipantsCard(int current, int max) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: Offset(0, 4))]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [Icon(Icons.people_outline, color: Color(0xFF6C63FF)), SizedBox(width: 8), Text('Participants', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2D3748)))]),
          SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: ClipRRect(borderRadius: BorderRadius.circular(10), child: LinearProgressIndicator(value: max > 0 ? current / max : 0, backgroundColor: Color(0xFFE2E8F0), valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF10B981)), minHeight: 8))),
              SizedBox(width: 16),
              Text('$current/$max', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2D3748))),
            ],
          ),
          SizedBox(height: 8),
          Text('${max - current} spots remaining', style: TextStyle(color: Color(0xFF718096), fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildDescriptionCard(String description) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: Offset(0, 4))]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [Icon(Icons.description_outlined, color: Color(0xFF6C63FF)), SizedBox(width: 8), Text('About this event', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2D3748)))]),
          SizedBox(height: 16),
          Text(description, style: TextStyle(fontSize: 16, color: Color(0xFF4A5568), height: 1.6)),
        ],
      ),
    );
  }
  
  Widget _buildBottomBar(BuildContext context, String title) {
    bool isActionable = _userStatus == null;
    String buttonText = 'Join This Event';
    Color buttonColor = Color(0xFF6C63FF);

    if (_userStatus == 'accepted') {
      buttonText = 'Anda Sudah Terdaftar';
      buttonColor = Color(0xFF38A169);
    } else if (_userStatus == 'waiting') {
      buttonText = 'Permintaan Terkirim';
      buttonColor = Colors.orange;
    }

    return Container(
      padding: EdgeInsets.fromLTRB(24, 12, 24, 24),
      decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: Offset(0, -5))]),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: isActionable ? () => _showRegistrationDialog(context, title) : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: buttonColor,
              padding: EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              disabledBackgroundColor: buttonColor,
              disabledForegroundColor: Colors.white,
            ),
            child: Text(buttonText, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
          ),
        ),
      ),
    );
  }

  void _showRegistrationDialog(BuildContext context, String title) {
    showDialog(
      context: context,
      barrierDismissible: !_isProcessing,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return Dialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(padding: EdgeInsets.all(16), decoration: BoxDecoration(color: Color(0xFF6C63FF).withOpacity(0.1), shape: BoxShape.circle), child: Icon(Icons.event_available_outlined, color: Color(0xFF6C63FF), size: 40)),
                    SizedBox(height: 20),
                    Text('Kirim Permintaan Bergabung?', textAlign: TextAlign.center, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF2D3748))),
                    SizedBox(height: 12),
                    Text('Permintaan Anda untuk bergabung di acara "$title" akan dikirim ke penyelenggara.', textAlign: TextAlign.center, style: TextStyle(fontSize: 16, color: Color(0xFF4A5568))),
                    SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(child: TextButton(onPressed: _isProcessing ? null : () => Navigator.of(context).pop(), child: Text('Batal', style: TextStyle(color: Color(0xFF718096), fontWeight: FontWeight.bold, fontSize: 16)))),
                        SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: _isProcessing ? null : _joinEvent,
                            style: ElevatedButton.styleFrom(backgroundColor: Color(0xFF6C63FF), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), padding: EdgeInsets.symmetric(vertical: 12)),
                            child: _isProcessing 
                                ? SizedBox(height: 24, width: 24, child: CircularProgressIndicator(strokeWidth: 3, color: Colors.white))
                                : Text('Kirim Permintaan', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showSuccessDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(width: 80, height: 80, decoration: BoxDecoration(color: Color(0xFF10B981).withOpacity(0.1), borderRadius: BorderRadius.circular(40)), child: Icon(Icons.check_circle, color: Color(0xFF10B981), size: 40)),
              SizedBox(height: 16),
              Text('Permintaan Terkirim!', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2D3748))),
              SizedBox(height: 8),
              Text('Permintaan Anda untuk bergabung telah dikirim. Mohon tunggu persetujuan dari penyelenggara.', textAlign: TextAlign.center, style: TextStyle(color: Color(0xFF4A5568))),
            ],
          ),
          actions: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(backgroundColor: Color(0xFF6C63FF), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                child: Text('Luar Biasa!', style: TextStyle(color: Colors.white)),
              ),
            ),
          ],
        );
      },
    );
  }
}