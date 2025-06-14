import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:volunteervibe/services/pocketbase_service.dart';
import 'package:volunteervibe/screens/search_screen.dart';
import 'package:volunteervibe/screens/gamification_screen.dart';
import 'package:volunteervibe/screens/profile_screen.dart';

class VolunteerHoursScreen extends StatefulWidget {
  @override
  _VolunteerHoursScreenState createState() => _VolunteerHoursScreenState();
}

class _VolunteerHoursScreenState extends State<VolunteerHoursScreen> {
  final PocketBaseService _pbService = PocketBaseService();
  int _bottomNavIndex = 3;

  bool _isLoading = true;
  List<RecordModel> _hourLogs = [];

  String _selectedPeriod = 'This Month';
  final List<String> _periods = ['This Week', 'This Month', 'This Year', 'All Time'];

  @override
  void initState() {
    super.initState();
    _loadLogs();
  }

  Future<void> _loadLogs() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    
    final userId = _pbService.getCurrentUser()?.id;
    if (userId == null) {
      if (mounted) setState(() => _isLoading = false);
      return;
    }

    final logs = await _pbService.fetchHourLogs(userId);
    if (mounted) {
      setState(() {
        _hourLogs = logs;
        _isLoading = false;
      });
    }
  }

  double get _totalHours {
    return _hourLogs.fold(0.0, (sum, log) {
      final event = log.expand['event_id']?.first;
      final hours = event?.getDoubleValue('duration_hours') ?? 0.0;
      return sum + hours;
    });
  }

  double get _verifiedHours {
    return _hourLogs
        .where((log) => log.getBoolValue('is_verified') == true)
        .fold(0.0, (sum, log) {
          final event = log.expand['event_id']?.first;
          final hours = event?.getDoubleValue('duration_hours') ?? 0.0;
          return sum + hours;
        });
  }

  double get _pendingHours {
     return _hourLogs
        .where((log) => log.getBoolValue('is_verified') == false)
        .fold(0.0, (sum, log) {
          final event = log.expand['event_id']?.first;
          final hours = event?.getDoubleValue('duration_hours') ?? 0.0;
          return sum + hours;
        });
  }
  
  int get _totalEvents {
    return _hourLogs.length;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF7FAFC),
      appBar: AppBar(
        title: Text('Volunteer Hours', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2D3748))),
        backgroundColor: Colors.white,
        elevation: 1,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: Color(0xFF2D3748)),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(icon: Icon(Icons.add_circle_outline, color: Color(0xFF6C63FF)), onPressed: () {}),
          IconButton(icon: Icon(Icons.download_outlined, color: Color(0xFF6C63FF)), onPressed: () {}),
        ],
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadLogs,
          color: Color(0xFF6C63FF),
          child: _isLoading
              ? Center(child: CircularProgressIndicator(color: Color(0xFF6C63FF)))
              : Column(
                  children: [
                    _buildHoursSummary(),
                    _buildPeriodSelector(),
                    Expanded(child: _buildHoursLog()),
                  ],
                ),
        ),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildHoursSummary() {
    return Container(
      margin: EdgeInsets.fromLTRB(24, 24, 24, 16),
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [Color(0xFF6C63FF), Color(0xFF9F7AEA)], begin: Alignment.topLeft, end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Color(0xFF6C63FF).withOpacity(0.3), blurRadius: 20, offset: Offset(0, 10))],
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
                    Text('Total Hours Logged', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                    Text(_selectedPeriod, style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.9))),
                  ],
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(20)),
                child: Text('${_totalHours.toStringAsFixed(1)}h', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ],
          ),
          SizedBox(height: 24),
          Row(
            children: [
              Expanded(child: _buildSummaryItem('Verified', '${_verifiedHours.toStringAsFixed(1)}h', Icons.verified_user_rounded, Color(0xFF10B981))),
              SizedBox(width: 16),
              Expanded(child: _buildSummaryItem('Pending', '${_pendingHours.toStringAsFixed(1)}h', Icons.pending_actions_rounded, Color(0xFFED8936))),
              SizedBox(width: 16),
              Expanded(child: _buildSummaryItem('Events', '$_totalEvents', Icons.event_note_rounded, Color(0xFFE53E3E))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
      child: Column(children: [
        Icon(icon, color: color, size: 24),
        SizedBox(height: 8),
        Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white)),
        Text(label, style: TextStyle(fontSize: 12, color: Colors.white.withOpacity(0.9))),
      ]),
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
              labelStyle: TextStyle(color: isSelected ? Colors.white : Color(0xFF4A5568), fontWeight: FontWeight.w600, fontSize: 14),
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
    if (_hourLogs.isEmpty) {
      return Expanded(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.history_toggle_off, size: 60, color: Colors.grey.shade400),
              SizedBox(height: 16),
              Text("No volunteer hours logged yet.", style: TextStyle(fontSize: 16, color: Colors.grey.shade600)),
            ],
          )
        ),
      );
    }
    return Container(
      padding: EdgeInsets.fromLTRB(24, 16, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Text('Hours Log', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2D3748))),
            Spacer(),
            InkWell(
              onTap: () {},
              borderRadius: BorderRadius.circular(8),
              child: Padding(
                padding: const EdgeInsets.all(4.0),
                child: Row(children: [
                  Icon(Icons.filter_list_rounded, color: Color(0xFF6C63FF), size: 20),
                  SizedBox(width: 4),
                  Text('Filter', style: TextStyle(color: Color(0xFF6C63FF), fontWeight: FontWeight.w600)),
                ]),
              ),
            ),
          ]),
          SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.zero,
              itemCount: _hourLogs.length,
              itemBuilder: (context, index) => _buildLogCard(_hourLogs[index]),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogCard(RecordModel log) {
    final event = log.expand['event_id']?.first;
    if (event == null) return SizedBox.shrink();

    final organization = event.expand['organization_id']?.first;
    final category = event.expand['categories_id']?.first;
    final String title = event.getStringValue('title', 'No Title');
    final String orgName = organization?.getStringValue('name', 'Unknown Org') ?? 'Unknown Org';
    final DateTime eventDate = DateTime.parse(event.getStringValue('date'));
    final double hours = event.getDoubleValue('duration_hours', 0.0);
    final bool isVerified = log.getBoolValue('is_verified');
    final String status = isVerified ? 'Verified' : 'Pending';
    final String categoryName = category?.getStringValue('name') ?? 'Community';

    return Container(
      margin: EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: Offset(0, 4))]),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {},
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              children: [
                Row(children: [
                  Container(
                    width: 50, height: 50,
                    decoration: BoxDecoration(color: _getCategoryColor(categoryName).withOpacity(0.1), borderRadius: BorderRadius.circular(25)),
                    child: Icon(_getCategoryIcon(categoryName), color: _getCategoryColor(categoryName), size: 24),
                  ),
                  SizedBox(width: 16),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF2D3748))),
                    Text(orgName, style: TextStyle(color: Color(0xFF718096), fontSize: 14)),
                  ])),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(color: isVerified ? Color(0xFF10B981).withOpacity(0.1) : Color(0xFFED8936).withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                    child: Text(status, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: isVerified ? Color(0xFF10B981) : Color(0xFFED8936))),
                  ),
                ]),
                Divider(height: 32, color: Colors.grey.shade200),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                  Row(children: [
                    Icon(Icons.calendar_today, size: 16, color: Color(0xFF718096)),
                    SizedBox(width: 8),
                    Text(DateFormat('MMM dd, yyyy').format(eventDate), style: TextStyle(color: Color(0xFF718096), fontSize: 14)),
                  ]),
                  Row(children: [
                    Icon(Icons.timer_outlined, size: 16, color: Color(0xFF6C63FF)),
                    SizedBox(width: 8),
                    Text('${hours.toStringAsFixed(1)} hours', style: TextStyle(color: Color(0xFF6C63FF), fontSize: 14, fontWeight: FontWeight.w600)),
                  ]),
                ]),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Environment': return Color(0xFF10B981);
      case 'Education': return Color(0xFF6C63FF);
      case 'Health': return Color(0xFFE53E3E);
      case 'Community': return Color(0xFFED8936);
      case 'Animals': return Color(0xFF9F7AEA);
      default: return Color(0xFF718096);
    }
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Environment': return Icons.eco_rounded;
      case 'Education': return Icons.school_rounded;
      case 'Health': return Icons.health_and_safety_rounded;
      case 'Community': return Icons.people_rounded;
      case 'Animals': return Icons.pets_rounded;
      default: return Icons.volunteer_activism_rounded;
    }
  }
  
  Widget _buildBottomNavigationBar() {
    return Container(
      decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 20, offset: Offset(0, -5))]),
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
            case 0: Navigator.popUntil(context, (route) => route.isFirst); break;
            case 1: Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => SearchScreen())); break;
            case 2: Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => GamificationScreen())); break;
            case 3: break; // Already here
            case 4: Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => ProfileScreen())); break;
          }
        },
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(color: isActive ? activeColor.withOpacity(0.1) : Colors.transparent, borderRadius: BorderRadius.circular(12)),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: isActive ? activeColor : inactiveColor, size: 24),
              SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(color: isActive ? activeColor : inactiveColor, fontSize: 11, fontWeight: isActive ? FontWeight.w600 : FontWeight.w500),
                overflow: TextOverflow.ellipsis,
                maxLines: 1,
              ),
            ],
          ),
        ),
      ),
    );
  }
}