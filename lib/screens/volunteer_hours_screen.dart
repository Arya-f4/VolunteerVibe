import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';

// --- Impor untuk Navigasi ---
import 'package:volunteervibe/screens/search_screen.dart';
import 'package:volunteervibe/screens/gamification_screen.dart';
import 'package:volunteervibe/screens/profile_screen.dart';

class VolunteerHoursScreen extends StatefulWidget {
  @override
  _VolunteerHoursScreenState createState() => _VolunteerHoursScreenState();
}

class _VolunteerHoursScreenState extends State<VolunteerHoursScreen> {
  // --- State untuk Bottom Bar ---
  int _bottomNavIndex = 3; // 3 adalah index untuk "Hours"

  final List<Map<String, dynamic>> _volunteerLogs = [
    {
      'title': 'Beach Cleanup Drive',
      'organization': 'Ocean Warriors',
      'date': 'Dec 10, 2024',
      'startTime': '9:00 AM',
      'endTime': '1:00 PM',
      'hours': 4.0,
      'status': 'Verified',
      'category': 'Environment',
      'supervisor': 'Sarah Johnson',
      'notes': 'Cleaned 2km of beach, collected 50kg of trash',
    },
    {
      'title': 'Food Bank Volunteer',
      'organization': 'Community Kitchen',
      'date': 'Dec 5, 2024',
      'startTime': '2:00 PM',
      'endTime': '5:00 PM',
      'hours': 3.0,
      'status': 'Verified',
      'category': 'Community',
      'supervisor': 'Mike Chen',
      'notes': 'Served 150 meals to families in need',
    },
    {
      'title': 'Reading Program for Kids',
      'organization': 'Bright Futures',
      'date': 'Nov 28, 2024',
      'startTime': '10:00 AM',
      'endTime': '1:00 PM',
      'hours': 3.0,
      'status': 'Verified',
      'category': 'Education',
      'supervisor': 'Lisa Wang',
      'notes': 'Read with 8 children, helped with homework',
    },
    {
      'title': 'Senior Care Visit',
      'organization': 'Golden Years',
      'date': 'Nov 20, 2024',
      'startTime': '1:00 PM',
      'endTime': '4:00 PM',
      'hours': 3.0,
      'status': 'Pending',
      'category': 'Health',
      'supervisor': 'Dr. Amanda Smith',
      'notes': 'Spent time with 12 elderly residents',
    },
  ];

  String _selectedPeriod = 'This Month';
  final List<String> _periods = ['This Week', 'This Month', 'This Year', 'All Time'];

  double get _totalHours {
    return _volunteerLogs.fold(0.0, (sum, log) => sum + log['hours']);
  }

  double get _verifiedHours {
    return _volunteerLogs
        .where((log) => log['status'] == 'Verified')
        .fold(0.0, (sum, log) => sum + log['hours']);
  }

  double get _pendingHours {
    return _volunteerLogs
        .where((log) => log['status'] == 'Pending')
        .fold(0.0, (sum, log) => sum + log['hours']);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF7FAFC), // Warna latar belakang yang lebih soft
      appBar: AppBar(
        title: Text(
          'Volunteer Hours',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF2D3748),
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 1, // Memberi sedikit bayangan untuk memisahkan dari konten
        automaticallyImplyLeading: false, // Sembunyikan tombol kembali default
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: Color(0xFF2D3748)),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.add_circle_outline, color: Color(0xFF6C63FF)),
            onPressed: _showAddHoursDialog,
            tooltip: 'Log New Hours',
          ),
          IconButton(
            icon: Icon(Icons.download_outlined, color: Color(0xFF6C63FF)),
            onPressed: _exportHours,
            tooltip: 'Export Hours',
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            _buildHoursSummary(),
            _buildPeriodSelector(),
            Expanded(
              child: _buildHoursLog(),
            ),
          ],
        ),
      ),
      // --- BOTTOM NAVIGATION BAR DITAMBAHKAN DI SINI ---
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  // --- START: KODE BOTTOM BAR ---

  Widget _buildBottomNavigationBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildCompactNavItem(Icons.home_rounded, 'Home', 0),
              _buildCompactNavItem(Icons.search_rounded, 'Search', 1),
              _buildCompactNavItem(Icons.emoji_events_rounded, 'Rewards', 2),
              _buildCompactNavItem(Icons.schedule_rounded, 'Hours', 3),
              _buildCompactNavItem(Icons.person_rounded, 'Profile', 4),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCompactNavItem(IconData icon, String label, int index) {
    final activeColor = Color(0xFF6C63FF);
    final inactiveColor = Color(0xFF718096);
    final bool isActive = _bottomNavIndex == index;

    return Flexible(
      child: GestureDetector(
        onTap: () {
          if (index == _bottomNavIndex) return;

          switch (index) {
            case 0:
              Navigator.popUntil(context, (route) => route.isFirst);
              break;
            case 1:
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => SearchScreen()));
              break;
            case 2:
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => GamificationScreen()));
              break;
            case 3:
              // Sudah di halaman ini
              break;
            case 4:
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => ProfileScreen()));
              break;
          }
        },
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            color: isActive ? activeColor.withOpacity(0.1) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: isActive ? activeColor : inactiveColor,
                size: 24,
              ),
              SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: isActive ? activeColor : inactiveColor,
                  fontSize: 11,
                  fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                ),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // --- END: KODE BOTTOM BAR ---
  
  Widget _buildHoursSummary() {
    return Container(
      margin: EdgeInsets.fromLTRB(24, 24, 24, 16),
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF6C63FF), Color(0xFF9F7AEA)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Color(0xFF6C63FF).withOpacity(0.3),
            blurRadius: 20,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.access_time_filled_rounded, color: Colors.white, size: 32),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total Hours Logged',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      _selectedPeriod,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '${_totalHours.toStringAsFixed(1)}h',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _buildSummaryItem(
                  'Verified',
                  '${_verifiedHours.toStringAsFixed(1)}h',
                  Icons.verified_user_rounded,
                  Color(0xFF10B981),
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: _buildSummaryItem(
                  'Pending',
                  '${_pendingHours.toStringAsFixed(1)}h',
                  Icons.pending_actions_rounded,
                  Color(0xFFED8936),
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: _buildSummaryItem(
                  'Events',
                  '${_volunteerLogs.length}',
                  Icons.event_note_rounded,
                  Color(0xFFE53E3E),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withOpacity(0.9),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodSelector() {
    return Container(
      height: 40,
      margin: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _periods.length,
        itemBuilder: (context, index) {
          final period = _periods[index];
          final isSelected = _selectedPeriod == period;
          
          return Padding(
            padding: EdgeInsets.only(right: 12),
            child: ActionChip(
              label: Text(period),
              labelStyle: TextStyle(
                  color: isSelected ? Colors.white : Color(0xFF4A5568),
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
              ),
              backgroundColor: isSelected ? Color(0xFF6C63FF) : Colors.white,
              onPressed: () => setState(() => _selectedPeriod = period),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              side: BorderSide(color: isSelected ? Color(0xFF6C63FF) : Color(0xFFE2E8F0)),
            )
          );
        },
      ),
    );
  }

  Widget _buildHoursLog() {
    return Container(
      padding: EdgeInsets.fromLTRB(24, 16, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Hours Log',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2D3748),
                ),
              ),
              Spacer(),
              InkWell(
                onTap: _showFilterDialog,
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.all(4.0),
                  child: Row(
                    children: [
                      Icon(Icons.filter_list_rounded, color: Color(0xFF6C63FF), size: 20),
                      SizedBox(width: 4),
                      Text(
                        'Filter',
                        style: TextStyle(
                          color: Color(0xFF6C63FF),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.zero,
              itemCount: _volunteerLogs.length,
              itemBuilder: (context, index) {
                return _buildLogCard(_volunteerLogs[index]);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogCard(Map<String, dynamic> log) {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _showLogDetails(log),
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: _getCategoryColor(log['category']).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(25),
                      ),
                      child: Icon(
                        _getCategoryIcon(log['category']),
                        color: _getCategoryColor(log['category']),
                        size: 24,
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            log['title'],
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2D3748),
                            ),
                          ),
                          Text(
                            log['organization'],
                            style: TextStyle(
                              color: Color(0xFF718096),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: log['status'] == 'Verified'
                            ? Color(0xFF10B981).withOpacity(0.1)
                            : Color(0xFFED8936).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        log['status'],
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: log['status'] == 'Verified'
                              ? Color(0xFF10B981)
                              : Color(0xFFED8936),
                        ),
                      ),
                    ),
                  ],
                ),
                Divider(height: 32, color: Colors.grey.shade200),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.calendar_today, size: 16, color: Color(0xFF718096)),
                        SizedBox(width: 8),
                        Text(
                          log['date'],
                          style: TextStyle(color: Color(0xFF718096), fontSize: 14),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Icon(Icons.timer_outlined, size: 16, color: Color(0xFF6C63FF)),
                        SizedBox(width: 8),
                        Text(
                          '${log['hours']} hours',
                          style: TextStyle(
                            color: Color(0xFF6C63FF),
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showLogDetails(Map<String, dynamic> log) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        margin: EdgeInsets.all(8),
        height: MediaQuery.of(context).size.height * 0.75,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Text(
                    'Hour Log Details',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2D3748),
                    ),
                  ),
                  Spacer(),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.close),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDetailItem('Event', log['title']),
                    _buildDetailItem('Organization', log['organization']),
                    _buildDetailItem('Date', log['date']),
                    _buildDetailItem('Time', '${log['startTime']} - ${log['endTime']}'),
                    _buildDetailItem('Duration', '${log['hours']} hours'),
                    _buildDetailItem('Category', log['category']),
                    _buildDetailItem('Supervisor', log['supervisor']),
                    _buildDetailItem('Status', log['status']),
                    _buildDetailItem('Notes', log['notes']),
                    SizedBox(height: 24),
                    if (log['status'] == 'Pending')
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          icon: Icon(Icons.send_rounded, size: 18),
                          label: Text('Request Verification'),
                          onPressed: () => _requestVerification(log),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFF6C63FF),
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF718096),
            ),
          ),
          SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              color: Color(0xFF2D3748),
            ),
          ),
        ],
      ),
    );
  }

 void _showAddHoursDialog() {
    final _titleController = TextEditingController();
    final _organizationController = TextEditingController();
    final _supervisorController = TextEditingController();
    final _notesController = TextEditingController();
    DateTime _selectedDate = DateTime.now();
    TimeOfDay _startTime = TimeOfDay.now();
    TimeOfDay _endTime = TimeOfDay.now().replacing(hour: TimeOfDay.now().hour + 2);
    String _selectedCategory = 'Community';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text('Log Volunteer Hours'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _titleController,
                decoration: InputDecoration(
                  labelText: 'Event Title',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              SizedBox(height: 16),
              TextField(
                controller: _organizationController,
                decoration: InputDecoration(
                  labelText: 'Organization',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _selectedCategory,
                decoration: InputDecoration(
                  labelText: 'Category',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                items: ['Environment', 'Education', 'Health', 'Community', 'Animals']
                    .map((category) => DropdownMenuItem(
                          value: category,
                          child: Text(category),
                        ))
                    .toList(),
                onChanged: (value) {
                  _selectedCategory = value!;
                },
              ),
              SizedBox(height: 16),
              TextField(
                controller: _supervisorController,
                decoration: InputDecoration(
                  labelText: 'Supervisor Name',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              SizedBox(height: 16),
              TextField(
                controller: _notesController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Notes (optional)',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Hours logged successfully!'),
                  backgroundColor: Color(0xFF10B981),
                ),
              );
            },
            child: Text('Log Hours'),
          ),
        ],
      ),
    );
  }

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Filter Hours'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: Text('All'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              title: Text('Verified Only'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              title: Text('Pending Only'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              title: Text('By Category'),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  void _exportHours() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Export Hours'),
        content: Text('Export your volunteer hours as PDF or CSV?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('PDF exported successfully!'),
                  backgroundColor: Color(0xFF6C63FF),
                ),
              );
            },
            child: Text('PDF'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('CSV exported successfully!'),
                  backgroundColor: Color(0xFF6C63FF),
                ),
              );
            },
            child: Text('CSV'),
          ),
        ],
      ),
    );
  }

  void _requestVerification(Map<String, dynamic> log) {
    Navigator.pop(context);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Request Verification'),
        content: Text('Send verification request to ${log['supervisor']}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Verification request sent!'),
                  backgroundColor: Color(0xFF6C63FF),
                ),
              );
            },
            child: Text('Send Request'),
          ),
        ],
      ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Environment':
        return Color(0xFF10B981);
      case 'Education':
        return Color(0xFF6C63FF);
      case 'Health':
        return Color(0xFFE53E3E);
      case 'Community':
        return Color(0xFFED8936);
      case 'Animals':
        return Color(0xFF9F7AEA);
      default:
        return Color(0xFF718096);
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Environment':
        return Icons.eco_rounded;
      case 'Education':
        return Icons.school_rounded;
      case 'Health':
        return Icons.health_and_safety_rounded;
      case 'Community':
        return Icons.people_rounded;
      case 'Animals':
        return Icons.pets_rounded;
      default:
        return Icons.volunteer_activism_rounded;
    }
  }
}