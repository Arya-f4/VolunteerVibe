import 'package:flutter/material.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:intl/intl.dart';
import 'package:volunteervibe/pocketbase_client.dart';

class EventDetailScreen extends StatelessWidget {
  final RecordModel event;

  const EventDetailScreen({Key? key, required this.event}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // --- Mengambil data dari RecordModel ---
    final organization = event.expand['organization_id']?.first;
    final category = event.expand['categories_id']?.first;

    final title = event.getStringValue('title', 'No Title');
    final description = event.getStringValue('description', 'No description available.');
    final orgName = organization?.getStringValue('name', 'Unknown Organization') ?? 'Unknown Organization';
    final categoryName = category?.getStringValue('name', 'Uncategorized') ?? 'Uncategorized';
    final location = event.getStringValue('location', 'No location specified');
    final points = event.getIntValue('point_event', 0);
    final maxParticipants = event.getIntValue('max_participant', 0);
    final currentParticipants = event.getListValue<String>('participant_id').length;
    
    final DateTime eventDate = DateTime.parse(event.getStringValue('date'));
    final String dateFormatted = DateFormat('EEEE, MMM dd, yyyy').format(eventDate);
    final String timeFormatted = DateFormat('h:mm a').format(eventDate);

    String? orgAvatarUrl;
    if (organization != null) {
      final orgAvatarFilename = organization.getStringValue('avatar');
      if (orgAvatarFilename.isNotEmpty) {
        orgAvatarUrl = pb.getFileUrl(organization, orgAvatarFilename).toString();
      }
    }
    // --- Akhir pengambilan data ---

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
              // --- PERUBAHAN DI SINI: Properti 'title' dan 'centerTitle' dihapus ---
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
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          color: Colors.grey.shade400,
                          child: Icon(Icons.business_rounded, size: 80, color: Colors.white.withOpacity(0.7)),
                        );
                      },
                    )
                  else
                    Container(
                      color: Colors.grey.shade400,
                      child: Icon(Icons.business_rounded, size: 80, color: Colors.white.withOpacity(0.7)),
                    ),

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
                  Positioned(
                    bottom: 20,
                    right: 20,
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(color: Colors.white.withOpacity(0.9), borderRadius: BorderRadius.circular(20)),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.star, color: Color(0xFFFFD700), size: 20),
                          SizedBox(width: 4),
                          Text('$points points', style: TextStyle(color: Color(0xFF6C63FF), fontWeight: FontWeight.bold)),
                        ],
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
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(title, style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF2D3748))),
                      ),
                      SizedBox(width: 16),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(color: Color(0xFF6C63FF).withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                        child: Text(categoryName, style: TextStyle(color: Color(0xFF6C63FF), fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Organized by $orgName',
                    style: TextStyle(fontSize: 16, color: Color(0xFF718096), fontWeight: FontWeight.w500),
                  ),
                  SizedBox(height: 24),
                  _buildInfoCard(context, dateFormatted, timeFormatted, location),
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
      bottomNavigationBar: _buildBottomBar(context, title, points),
    );
  }

  // --- Sisa kode tidak ada perubahan ---

  Widget _buildInfoCard(BuildContext context, String date, String time, String location) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: Offset(0, 4))]),
      child: Column(
        children: [
          _buildInfoRow(Icons.calendar_today, 'Date', date),
          SizedBox(height: 16),
          _buildInfoRow(Icons.access_time, 'Time', time),
          SizedBox(height: 16),
          _buildInfoRow(Icons.location_on, 'Location', location),
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Container(
          width: 40, height: 40,
          decoration: BoxDecoration(color: Color(0xFF6C63FF).withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
          child: Icon(icon, color: Color(0xFF6C63FF), size: 20),
        ),
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
          Row(children: [Icon(Icons.people, color: Color(0xFF6C63FF)), SizedBox(width: 8), Text('Participants', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2D3748)))]),
          SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: max > 0 ? current / max : 0,
                    backgroundColor: Color(0xFFE2E8F0),
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF10B981)),
                    minHeight: 8,
                  ),
                ),
              ),
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
          Row(children: [Icon(Icons.description, color: Color(0xFF6C63FF)), SizedBox(width: 8), Text('About this event', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2D3748)))]),
          SizedBox(height: 16),
          Text(description, style: TextStyle(fontSize: 16, color: Color(0xFF4A5568), height: 1.6)),
        ],
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context, String title, int points) {
    return Container(
      padding: EdgeInsets.fromLTRB(24, 12, 24, 24),
      decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: Offset(0, -5))]),
      child: SafeArea(
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => _showRegistrationDialog(context, title, points),
            style: ElevatedButton.styleFrom(backgroundColor: Color(0xFF6C63FF), padding: EdgeInsets.symmetric(vertical: 16), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
            child: Text('Join This Event', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
          ),
        ),
      ),
    );
  }

  void _showRegistrationDialog(BuildContext context, String title, int points) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('Confirm Registration', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2D3748))),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Are you sure you want to join "$title"?', style: TextStyle(color: Color(0xFF4A5568))),
              SizedBox(height: 16),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(color: Color(0xFF6C63FF).withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                child: Row(
                  children: [
                    Icon(Icons.star, color: Color(0xFFFFD700), size: 20),
                    SizedBox(width: 8),
                    Text('You will earn $points points', style: TextStyle(color: Color(0xFF6C63FF), fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel', style: TextStyle(color: Color(0xFF718096))),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _showSuccessDialog(context);
              },
              style: ElevatedButton.styleFrom(backgroundColor: Color(0xFF6C63FF), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
              child: Text('Join Event', style: TextStyle(color: Colors.white)),
            ),
          ],
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
              Text('Registration Successful!', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2D3748))),
              SizedBox(height: 8),
              Text('Check your notifications for updates.', textAlign: TextAlign.center, style: TextStyle(color: Color(0xFF4A5568))),
            ],
          ),
          actions: [
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).pop();
                },
                style: ElevatedButton.styleFrom(backgroundColor: Color(0xFF6C63FF), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
                child: Text('Great!', style: TextStyle(color: Colors.white)),
              ),
            ),
          ],
        );
      },
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Environment': return Icons.eco;
      case 'Education': return Icons.school;
      case 'Health': return Icons.health_and_safety;
      case 'Community': return Icons.people;
      case 'Animals': return Icons.pets;
      default: return Icons.volunteer_activism;
    }
  }
}