import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:volunteervibe/services/pocketbase_service.dart';

// Import halaman lain untuk navigasi
import 'home_screen.dart';
import 'profile_screen.dart';
import 'search_screen.dart';
import 'gamification_screen.dart';
import 'volunteer_hours_screen.dart';

class OrganizationDashboard extends StatefulWidget {
  @override
  _OrganizationDashboardState createState() => _OrganizationDashboardState();
}

class _OrganizationDashboardState extends State<OrganizationDashboard> {
  // Service
  final PocketBaseService _pbService = PocketBaseService();

  // State
  bool _isLoading = true;
  RecordModel? _organization;
  List<RecordModel> _organizationEvents = [];
  
  // Stats
  int _activeEventsCount = 0;
  int _totalVolunteers = 0;
  int _completedEventsCount = 0;

  @override
  void initState() {
    super.initState();
    _loadDashboardData();
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);
    
    try {
      final orgRecord = _pbService.getCurrentUser();
      
      if (orgRecord != null && orgRecord.collectionName == 'organization') {
        _organization = orgRecord;
        _organizationEvents = await _pbService.fetchEventsByOrganization(organizationId: _organization!.id);
        _calculateStats();
      } else {
        _organization = null;
      }
    } catch(e) {
      print("Error loading dashboard data: $e");
      _organization = null;
    } finally {
      if(mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _calculateStats() {
    final now = DateTime.now();
    int active = 0;
    int completed = 0;
    int volunteers = 0;

    for (var event in _organizationEvents) {
      final eventDate = DateTime.parse(event.getStringValue('date'));
      if (eventDate.isAfter(now)) {
        active++;
      } else {
        completed++;
      }
      volunteers += (event.getListValue<String>('participant_id')).length;
    }

    setState(() {
      _activeEventsCount = active;
      _completedEventsCount = completed;
      _totalVolunteers = volunteers;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text('Organization Dashboard', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2D3748))),
        backgroundColor: Colors.white,
        elevation: 1,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: Color(0xFF2D3748)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _buildBody(),
      // --- BOTTOM NAVIGATION BAR DITAMBAHKAN DI SINI ---
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator());
    }

    if (_organization == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.lock_person, color: Colors.orange, size: 60),
              SizedBox(height: 16),
              Text(
                'Access Denied',
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 8),
              Text(
                'You must be logged in as an organization to view this page.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadDashboardData,
      child: ListView(
        padding: EdgeInsets.all(24.0),
        children: [
          _buildOrganizationHeader(),
          SizedBox(height: 24),
          _buildStatsCards(),
          SizedBox(height: 24),
          Row(
            children: [
              Text('My Events', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF2D3748))),
              Spacer(),
              ElevatedButton.icon(
                onPressed: () => _showCreateEventDialog(),
                icon: Icon(Icons.add, size: 18),
                label: Text('Create Event'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF6C63FF),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          _organizationEvents.isEmpty
            ? Padding(
                padding: const EdgeInsets.symmetric(vertical: 48.0),
                child: Center(child: Text("You haven't created any events yet.", style: TextStyle(color: Colors.grey[600]))),
              )
            : ListView.separated(
                physics: NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                itemCount: _organizationEvents.length,
                itemBuilder: (context, index) {
                  return _buildEventCard(_organizationEvents[index]);
                },
                separatorBuilder: (context, index) => SizedBox(height: 16),
              ),
        ],
      ),
    );
  }

  Widget _buildOrganizationHeader() {
    String orgName = _organization?.getStringValue('name') ?? 'Loading...';
    String orgEmail = _organization?.getStringValue('email') ?? '...';
    String? avatarUrl = _pbService.getFileUrl(_organization!, _organization!.getStringValue('avatar'));

    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [Color(0xFF6C63FF), Color(0xFF9F7AEA)]),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 30,
            backgroundColor: Colors.white,
            backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
            child: avatarUrl == null ? Icon(Icons.business, color: Color(0xFF6C63FF), size: 30) : null,
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(orgName, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                Text(orgEmail, style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.9))),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCards() {
    return Row(
      children: [
        Expanded(child: _buildStatCard('Active Events', _activeEventsCount.toString(), Icons.event, Color(0xFF6C63FF))),
        SizedBox(width: 16),
        Expanded(child: _buildStatCard('Total Volunteers', _totalVolunteers.toString(), Icons.people, Color(0xFF10B981))),
        SizedBox(width: 16),
        Expanded(child: _buildStatCard('Completed', _completedEventsCount.toString(), Icons.check_circle, Color(0xFFED8936))),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: Offset(0, 4))],
      ),
      child: Column(
        children: [
          Container(width: 40, height: 40, decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(20)), child: Icon(icon, color: color, size: 20)),
          SizedBox(height: 8),
          Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF2D3748))),
          Text(title, style: TextStyle(fontSize: 12, color: Color(0xFF718096)), textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _buildEventCard(RecordModel event) {
    final now = DateTime.now();
    final eventDate = DateTime.parse(event.getStringValue('date'));
    final bool isActive = eventDate.isAfter(now);
    final int participantCount = event.getListValue<String>('participant_id').length;
    final int maxParticipants = event.getIntValue('max_participant', 0);

    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(event.getStringValue('title'), style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF2D3748)))),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isActive ? Color(0xFF10B981).withOpacity(0.1) : Color(0xFF718096).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  isActive ? 'Active' : 'Completed',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: isActive ? Color(0xFF10B981) : Color(0xFF718096)),
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Text(DateFormat('MMM dd, yyyy').format(eventDate), style: TextStyle(color: Color(0xFF718096), fontSize: 14)),
          SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: LinearProgressIndicator(
                  value: maxParticipants > 0 ? participantCount / maxParticipants : 0,
                  backgroundColor: Color(0xFFE2E8F0),
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF10B981)),
                ),
              ),
              SizedBox(width: 12),
              Text('$participantCount/$maxParticipants', style: TextStyle(color: Color(0xFF718096), fontSize: 12, fontWeight: FontWeight.w500)),
            ],
          ),
          Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(onPressed: () {}, icon: Icon(Icons.visibility, size: 16), label: Text('View Details'), style: TextButton.styleFrom(foregroundColor: Color(0xFF6C63FF))),
              SizedBox(width: 8),
              TextButton.icon(onPressed: () {}, icon: Icon(Icons.edit, size: 16), label: Text('Edit'), style: TextButton.styleFrom(foregroundColor: Color(0xFF718096))),
            ],
          ),
        ],
      ),
    );
  }

  void _showCreateEventDialog() {
    final _formKey = GlobalKey<FormState>();
    final _titleController = TextEditingController();
    final _descriptionController = TextEditingController();
    final _locationController = TextEditingController();
    final _maxParticipantController = TextEditingController();
    final _pointsController = TextEditingController();
    DateTime _selectedDate = DateTime.now();

    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('Create New Event', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2D3748))),
          content: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(controller: _titleController, decoration: InputDecoration(labelText: 'Event Title', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))), validator: (v) => v!.isEmpty ? 'Title is required' : null),
                  SizedBox(height: 16),
                  TextFormField(controller: _descriptionController, maxLines: 3, decoration: InputDecoration(labelText: 'Description', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))), validator: (v) => v!.isEmpty ? 'Description is required' : null),
                  SizedBox(height: 16),
                  TextFormField(controller: _locationController, decoration: InputDecoration(labelText: 'Location (lat,lon)', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))), validator: (v) => v!.isEmpty ? 'Location is required' : null),
                  SizedBox(height: 16),
                  TextFormField(controller: _maxParticipantController, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: 'Max Participants', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))), validator: (v) => v!.isEmpty ? 'Required' : null),
                  SizedBox(height: 16),
                  TextFormField(controller: _pointsController, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: 'Points', border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))), validator: (v) => v!.isEmpty ? 'Required' : null),
                  SizedBox(height: 16),
                  TextButton.icon(
                    onPressed: () async {
                      final pickedDate = await showDatePicker(context: context, initialDate: _selectedDate, firstDate: DateTime.now(), lastDate: DateTime(2030));
                      if (pickedDate != null) {
                        final pickedTime = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(_selectedDate));
                        if(pickedTime != null) {
                          _selectedDate = DateTime(pickedDate.year, pickedDate.month, pickedDate.day, pickedTime.hour, pickedTime.minute);
                        }
                      }
                    }, 
                    icon: Icon(Icons.calendar_today), 
                    label: Text('Select Date & Time')
                  )
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: Text('Cancel', style: TextStyle(color: Color(0xFF718096)))),
            ElevatedButton(
              onPressed: () async {
                if (_formKey.currentState!.validate() && _organization != null) {
                  final latlon = _locationController.text.split(',');
                  final body = <String, dynamic>{
                    "title": _titleController.text,
                    "description": _descriptionController.text,
                    "date": _selectedDate.toIso8601String(),
                    "location": {"lat": double.tryParse(latlon[0].trim()), "lon": double.tryParse(latlon[1].trim())},
                    "max_participant": int.tryParse(_maxParticipantController.text),
                    "point_event": int.tryParse(_pointsController.text),
                    "organization_id": _organization!.id,
                  };

                  final record = await _pbService.createEvent(body: body);
                  Navigator.of(dialogContext).pop();

                  if (record != null) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Event created successfully!'), backgroundColor: Color(0xFF10B981)));
                    _loadDashboardData();
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to create event.'), backgroundColor: Colors.red));
                  }
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: Color(0xFF6C63FF), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
              child: Text('Create Event', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  // --- WIDGET UNTUK BOTTOM NAVIGATION BAR ---
  Widget _buildBottomNavigationBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white, 
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: Offset(0, -5))]
      ),
      child: BottomNavigationBar(
        // Karena ini bukan halaman utama, kita tidak menandai item mana pun sebagai aktif
        // dengan memberikan index di luar jangkauan atau tidak menyetelnya sama sekali.
        // Namun, untuk menghindari error, kita set ke index yang tidak ada di logika utama kita, misal 0
        // atau lebih baik tidak menyorot apa pun. Cara mudah adalah set ke 0.
        currentIndex: 0, 
        onTap: (index) {
          // Navigasi ke halaman lain
          switch (index) {
            case 0: // Home
              // Kembali ke halaman paling awal (home)
              Navigator.popUntil(context, (route) => route.isFirst);
              break;
            case 1: 
              Navigator.push(context, MaterialPageRoute(builder: (context) => SearchScreen()));
              break;
            case 2: 
              Navigator.push(context, MaterialPageRoute(builder: (context) => GamificationScreen()));
              break;
            case 3: 
              Navigator.push(context, MaterialPageRoute(builder: (context) => VolunteerHoursScreen()));
              break;
            case 4: 
              Navigator.push(context, MaterialPageRoute(builder: (context) => ProfileScreen()));
              break;
          }
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.transparent,
        selectedItemColor: Color(0xFF6C63FF),
        unselectedItemColor: Color(0xFF718096),
        elevation: 0,
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.home_filled), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Search'),
          BottomNavigationBarItem(icon: Icon(Icons.emoji_events_outlined), label: 'Rewards'),
          BottomNavigationBarItem(icon: Icon(Icons.access_time), label: 'Hours'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Profile'),
        ],
      ),
    );
  }
}