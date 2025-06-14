import 'package:flutter/material.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:intl/intl.dart';
import 'package:volunteervibe/pocketbase_client.dart';
import 'package:volunteervibe/services/pocketbase_service.dart'; // Pastikan path ini benar

class EventDetailScreen extends StatefulWidget {
  final RecordModel event;

  const EventDetailScreen({Key? key, required this.event}) : super(key: key);

  @override
  State<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends State<EventDetailScreen> {
  final PocketBaseService _pbService = PocketBaseService();
  late RecordModel _currentEvent;
  
  bool _isLoading = true; // Untuk loading status awal
  bool _isProcessing = false; // Untuk proses klik tombol
  String? _userStatus; // Status pengguna: 'waiting', 'accepted', atau null

  @override
  void initState() {
    super.initState();
    _currentEvent = widget.event;
    _checkUserStatus(); // Cek status pendaftaran saat layar dimuat
  }

  Future<void> _checkUserStatus() async {
    setState(() => _isLoading = true);
    try {
      final userId = pb.authStore.model.id;
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
    String locationDisplay = _currentEvent.getStringValue('location', 'Location not specified');
    final points = _currentEvent.getIntValue('point_event', 0);
    final maxParticipants = _currentEvent.getIntValue('max_participant', 0);
    final currentParticipants = _currentEvent.getListValue<String>('participant_id').length;
    final DateTime eventDate = DateTime.parse(_currentEvent.getStringValue('date'));
    final String dateFormatted = DateFormat('EEEE, MMM dd, yyyy').format(eventDate);
    final String timeFormatted = DateFormat('h:mm a').format(eventDate);
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
            expandedHeight: 300,
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
                        stops: [0.6, 1.0],
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
                  _buildInfoCard(context, dateFormatted, timeFormatted, locationDisplay),
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

  Widget _buildInfoCard(BuildContext context, String date, String time, String location) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: Offset(0, 4))]),
      child: Column(
        children: [
          _buildInfoRow(Icons.calendar_today_outlined, 'Date', date),
          SizedBox(height: 16),
          _buildInfoRow(Icons.access_time_outlined, 'Time', time),
          SizedBox(height: 16),
          _buildInfoRow(Icons.location_on_outlined, 'Location', location),
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
      buttonColor = Color(0xFF38A169); // Green for accepted
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