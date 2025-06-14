import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pocketbase/pocketbase.dart';
import 'event_details_screen.dart'; // Pastikan path ini benar
import 'event_participants_screen.dart'; // Pastikan path ini benar

class EnhancedEventCard extends StatelessWidget {
  final RecordModel event;
  final int waitingCount;

  const EnhancedEventCard({
    Key? key, 
    required this.event,
    this.waitingCount = 0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // --- [LOGIKA BARU] Logika untuk menentukan status event ---
    final now = DateTime.now();
    final eventDate = DateTime.parse(event.getStringValue('date'));
    
    // Normalisasi tanggal ke tengah malam untuk perbandingan yang akurat
    final today = DateTime(now.year, now.month, now.day);
    final eventDay = DateTime(eventDate.year, eventDate.month, eventDate.day);

    String statusText;
    Color statusColor;

    if (eventDay.isAtSameMomentAs(today)) {
      statusText = 'In Progress';
      statusColor = Color(0xFF4299E1); // Biru untuk 'In Progress'
    } else if (eventDay.isAfter(today)) {
      statusText = 'Upcoming';
      statusColor = Color(0xFF10B981); // Hijau untuk 'Upcoming'
    } else {
      statusText = 'Completed';
      statusColor = Color(0xFF718096); // Abu-abu untuk 'Completed'
    }
    // --- Akhir dari Logika Baru ---

    final int participantCount = event.getListValue<String>('participant_id').length;
    final int maxParticipants = event.getIntValue('max_participant', 1);
    final double progress = maxParticipants > 0 ? participantCount / maxParticipants : 0;

    return Container(
      margin: EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        event.getStringValue('title'),
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2D3748)),
                      ),
                    ),
                    SizedBox(width: 8),
                    // [MODIFIKASI] Chip status sekarang menggunakan variabel baru
                    Chip(
                      label: Text(statusText),
                      labelStyle: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                      backgroundColor: statusColor,
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      visualDensity: VisualDensity.compact,
                    ),
                    PopupMenuButton<String>(
                      icon: Icon(Icons.more_vert, color: Color(0xFF718096)),
                      onSelected: (value) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => EventDetailsScreen(event: event),
                          ),
                        );
                      },
                      itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
                        const PopupMenuItem<String>(
                          value: 'edit',
                          child: ListTile(leading: Icon(Icons.edit), title: Text('Edit/Delete')),
                        ),
                      ],
                    ),
                  ],
                ),
                SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.calendar_today, size: 16, color: Color(0xFF718096)),
                    SizedBox(width: 8),
                    Text(
                      DateFormat('MMM dd, yyyy • HH:mm').format(eventDate.toLocal()),
                      style: TextStyle(color: Color(0xFF718096), fontSize: 14),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                Row(children: [
                  Icon(Icons.people, size: 16, color: Color(0xFF718096)),
                  SizedBox(width: 8),
                  Text('Participants', style: TextStyle(color: Color(0xFF718096), fontSize: 14)),
                  Spacer(),
                  Text('$participantCount/$maxParticipants', style: TextStyle(color: Color(0xFF2D3748), fontSize: 14, fontWeight: FontWeight.w600)),
                ]),
                SizedBox(height: 8),
                LinearProgressIndicator(
                  value: progress,
                  backgroundColor: Color(0xFFE2E8F0),
                  // [MODIFIKASI] Warna progress bar disesuaikan dengan status
                  valueColor: AlwaysStoppedAnimation<Color>(
                    statusText == 'Completed' ? Colors.grey : Color(0xFF6C63FF),
                  ),
                  minHeight: 6,
                  borderRadius: BorderRadius.circular(3),
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            decoration: BoxDecoration(
              color: Color(0xFFF8FAFC),
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
            ),
            child: Center(
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  TextButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => EventParticipantsScreen(event: event)),
                      );
                    },
                    icon: Icon(Icons.visibility, size: 20),
                    label: Text('View Participants'),
                    style: TextButton.styleFrom(
                      foregroundColor: Color(0xFF6C63FF),
                      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                    ),
                  ),
                  if (waitingCount > 0)
                    Positioned(
                      top: -5,
                      right: -5,
                      child: Container(
                        padding: EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                        constraints: BoxConstraints(minWidth: 22, minHeight: 22),
                        child: Center(
                          child: Text(
                            '$waitingCount',
                            style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}