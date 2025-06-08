import 'package:flutter/material.dart';
import '../../utils/app_colors.dart';
import '../../models/event.dart';

class TrackParticipantsScreen extends StatefulWidget {
  final Event event;

  TrackParticipantsScreen({required this.event});

  @override
  _TrackParticipantsScreenState createState() => _TrackParticipantsScreenState();
}

class _TrackParticipantsScreenState extends State<TrackParticipantsScreen> {
  List<Participant> participants = [
    Participant(
      userID: 1,
      name: "John Doe",
      email: "john.doe@email.com",
      registrationDate: DateTime(2024, 12, 10),
      attended: true,
    ),
    Participant(
      userID: 2,
      name: "Jane Smith",
      email: "jane.smith@email.com",
      registrationDate: DateTime(2024, 12, 11),
      attended: true,
    ),
    Participant(
      userID: 3,
      name: "Mike Johnson",
      email: "mike.johnson@email.com",
      registrationDate: DateTime(2024, 12, 12),
      attended: false,
    ),
    Participant(
      userID: 4,
      name: "Sarah Wilson",
      email: "sarah.wilson@email.com",
      registrationDate: DateTime(2024, 12, 13),
      attended: false,
    ),
  ];

  String _searchQuery = '';
  String _filterStatus = 'All';

  List<Participant> get filteredParticipants {
    return participants.where((participant) {
      bool matchesSearch = participant.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          participant.email.toLowerCase().contains(_searchQuery.toLowerCase());
      
      bool matchesFilter = _filterStatus == 'All' ||
          (_filterStatus == 'Attended' && participant.attended) ||
          (_filterStatus == 'Not Attended' && !participant.attended);
      
      return matchesSearch && matchesFilter;
    }).toList();
  }

  int get attendedCount => participants.where((p) => p.attended).length;
  int get notAttendedCount => participants.where((p) => !p.attended).length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Track Participants'),
        actions: [
          IconButton(
            icon: Icon(Icons.download),
            onPressed: () {
              _exportParticipants();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Event Info Header
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(16),
            margin: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.event.title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.calendar_today, size: 16, color: AppColors.textSecondary),
                    SizedBox(width: 8),
                    Text(
                      '${widget.event.formattedDate} at ${widget.event.formattedTime}',
                      style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.location_on, size: 16, color: AppColors.textSecondary),
                    SizedBox(width: 8),
                    Text(
                      widget.event.location,
                      style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Statistics Cards
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Total Registered',
                    '${participants.length}',
                    Icons.people,
                    AppColors.primary,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    'Attended',
                    '$attendedCount',
                    Icons.check_circle,
                    AppColors.success,
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    'Not Attended',
                    '$notAttendedCount',
                    Icons.cancel,
                    AppColors.error,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 16),

          // Search and Filter
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: TextField(
                      onChanged: (value) {
                        setState(() {
                          _searchQuery = value;
                        });
                      },
                      decoration: InputDecoration(
                        hintText: 'Search participants...',
                        prefixIcon: Icon(Icons.search, color: AppColors.textSecondary),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: _filterStatus,
                        isExpanded: true,
                        onChanged: (String? newValue) {
                          setState(() {
                            _filterStatus = newValue!;
                          });
                        },
                        items: ['All', 'Attended', 'Not Attended']
                            .map<DropdownMenuItem<String>>((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(
                              value,
                              style: TextStyle(fontSize: 14),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 16),

          // Participants List
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.symmetric(horizontal: 16),
              itemCount: filteredParticipants.length,
              itemBuilder: (context, index) {
                return _buildParticipantCard(filteredParticipants[index]);
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showMarkAttendanceDialog();
        },
        backgroundColor: AppColors.primary,
        child: Icon(Icons.check, color: Colors.white),
      ),
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            size: 24,
            color: color,
          ),
          SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildParticipantCard(Participant participant) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: participant.attended ? AppColors.success : AppColors.surfaceLight,
            child: Text(
              participant.name.split(' ').map((e) => e[0]).join(''),
              style: TextStyle(
                color: participant.attended ? Colors.white : AppColors.textSecondary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  participant.name,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  participant.email,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Registered: ${participant.registrationDate.day}/${participant.registrationDate.month}/${participant.registrationDate.year}',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Column(
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: participant.attended 
                      ? AppColors.success.withOpacity(0.1)
                      : AppColors.error.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  participant.attended ? 'Attended' : 'Not Attended',
                  style: TextStyle(
                    fontSize: 12,
                    color: participant.attended ? AppColors.success : AppColors.error,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              SizedBox(height: 8),
              GestureDetector(
                onTap: () {
                  setState(() {
                    participant = Participant(
                      userID: participant.userID,
                      name: participant.name,
                      email: participant.email,
                      registrationDate: participant.registrationDate,
                      attended: !participant.attended,
                    );
                    // Update the participant in the list
                    int index = participants.indexWhere((p) => p.userID == participant.userID);
                    if (index != -1) {
                      participants[index] = participant;
                    }
                  });
                },
                child: Icon(
                  participant.attended ? Icons.check_circle : Icons.radio_button_unchecked,
                  color: participant.attended ? AppColors.success : AppColors.textSecondary,
                  size: 24,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showMarkAttendanceDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Mark All Attendance'),
          content: Text('Do you want to mark all participants as attended?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  participants = participants.map((p) => Participant(
                    userID: p.userID,
                    name: p.name,
                    email: p.email,
                    registrationDate: p.registrationDate,
                    attended: true,
                  )).toList();
                });
                Navigator.of(context).pop();
              },
              child: Text('Mark All'),
            ),
          ],
        );
      },
    );
  }

  void _exportParticipants() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Export Participants'),
          content: Text('Participant data has been exported successfully!'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text('OK'),
            ),
          ],
        );
      },
    );
  }
}
