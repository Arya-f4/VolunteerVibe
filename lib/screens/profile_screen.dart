// File: lib/screens/profile_screen.dart

import 'package:flutter/material.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:volunteervibe/services/pocketbase_service.dart';

import 'home_screen.dart';
import 'search_screen.dart';
import 'gamification_screen.dart';
import 'volunteer_hours_screen.dart';
import 'organization_register_screen.dart';
import '../auth/login_page.dart';
import 'edit_profile_screen.dart'; // Import the new screen

class ProfileScreen extends StatefulWidget {
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // Service
  final PocketBaseService _pbService = PocketBaseService();

  // --- State untuk Bottom Bar ---
  int _bottomNavIndex = 4; // 4 adalah index untuk "Profile"

  // State
  bool _isLoading = true;
  String _userName = 'Guest';
  String _userEmail = '...';
  String? _userAvatarUrl;
  int _userPoints = 0;
  int _eventsJoined = 0;

  final List<Map<String, dynamic>> _achievements = [
    {'title': 'First Timer','icon': Icons.star, 'color': Color(0xFFFFD700), 'earned': true, 'description': 'Complete your first volunteer event'},
    {'title': 'Community Helper','icon': Icons.people, 'color': Color(0xFF6C63FF), 'earned': true, 'description': 'Join 3 community events'},
    {'title': 'Time Master', 'icon': Icons.access_time_filled, 'color': Color(0xFFED8936), 'earned': true, 'description': 'Log over 20 hours'},
    {'title': 'Environmental Warrior','icon': Icons.eco, 'color': Color(0xFF10B981), 'earned': false, 'description': 'Join an environmental event'},
  ];
  
  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    setState(() => _isLoading = true);
    final userRecord = _pbService.getCurrentUser();
    if (userRecord != null) {
      _userName = userRecord.getStringValue('name', 'Guest');
      _userEmail = userRecord.getStringValue('email', 'no-email@example.com');
      _userPoints = userRecord.getIntValue('points', 0);
      final avatarFilename = userRecord.getStringValue('avatar');
      if (avatarFilename.isNotEmpty) {
        _userAvatarUrl = _pbService.getFileUrl(userRecord, avatarFilename);
      }
      _eventsJoined = await _pbService.getEventsJoinedCount(userRecord.id);
    }
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text('My Profile', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2D3748))),
        backgroundColor: Colors.white,
        elevation: 1,
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadProfileData,
          color: Color(0xFF6C63FF),
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(24.0),
                  child: Column(
                    children: [
                      _buildProfileHeader(),
                      SizedBox(height: 32),
                      _buildStatsSection(),
                      SizedBox(height: 32),
                      _buildAchievementsSection(),
                      SizedBox(height: 32),
                      _buildOptions(context)
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildProfileHeader() {
    return Column(
      children: [
        Container(
          width: 120, height: 120,
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [Color(0xFF6C63FF), Color(0xFF9F7AEA)], begin: Alignment.topLeft, end: Alignment.bottomRight),
            borderRadius: BorderRadius.circular(60),
            boxShadow: [BoxShadow(color: Color(0xFF6C63FF).withOpacity(0.3), blurRadius: 20, offset: Offset(0, 10))],
          ),
          child: CircleAvatar(
            radius: 56, // Sedikit lebih kecil agar border gradient terlihat
            backgroundColor: Colors.white,
            child: CircleAvatar(
              radius: 52,
              backgroundColor: Colors.grey.shade200,
              backgroundImage: _userAvatarUrl != null ? NetworkImage(_userAvatarUrl!) : null,
              child: _userAvatarUrl == null ? Icon(Icons.person, color: Colors.white, size: 60) : null,
            ),
          ),
        ),
        SizedBox(height: 16),
        Text(_userName, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF2D3748))),
        Text(_userEmail, style: TextStyle(fontSize: 16, color: Color(0xFF718096))),
      ],
    );
  }

  Widget _buildStatsSection() {
    return Container(
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15, offset: Offset(0, 5))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('My Impact', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF2D3748))),
          SizedBox(height: 20),
          Row(
            children: [
              Expanded(child: _buildStatItem(_userPoints.toString(), 'Total Points', Icons.star, Colors.orange)),
              Expanded(child: _buildStatItem(_eventsJoined.toString(), 'Events Joined', Icons.event, Color(0xFF6C63FF))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String value, String label, IconData icon, Color color) {
    return Column(
      children: [
        CircleAvatar(radius: 25, backgroundColor: color.withOpacity(0.1), child: Icon(icon, color: color, size: 24)),
        SizedBox(height: 8),
        _isLoading
          ? SizedBox(height: 28, child: Center(child: SizedBox(width:14, height:14, child: CircularProgressIndicator(strokeWidth:2, color: color,))))
          : Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF2D3748))),
        SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 12, color: Color(0xFF718096)), textAlign: TextAlign.center),
      ],
    );
  }
  
  Widget _buildAchievementsSection() {
    int earnedCount = _achievements.where((a) => a['earned'] == true).length;
    return Container(
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15, offset: Offset(0, 5))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Achievements', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF2D3748))),
              Spacer(),
              Text('$earnedCount/${_achievements.length} earned', style: TextStyle(color: Color(0xFF718096), fontSize: 14)),
            ],
          ),
          SizedBox(height: 20),
          GridView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4, 
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
            ),
            itemCount: _achievements.length,
            itemBuilder: (context, index) {
              final achievement = _achievements[index];
              return _buildAchievementCard(achievement);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAchievementCard(Map<String, dynamic> achievement) {
    final bool isEarned = achievement['earned'];
    return Tooltip(
      message: achievement['title'],
      child: Opacity(
        opacity: isEarned ? 1.0 : 0.4,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: isEarned ? (achievement['color'] as Color).withOpacity(0.15) : Color(0xFFE2E8F0),
              child: Icon(achievement['icon'], color: isEarned ? achievement['color'] : Color(0xFF718096)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptions(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15, offset: Offset(0, 5))],
      ),
      child: Column(
        children: [
          _buildProfileOption(context, 'Edit Profile', Icons.edit_outlined),
          _buildProfileOption(context, 'Register as Organization', Icons.business),
          _buildProfileOption(context, 'Logout', Icons.logout, isLogout: true),
        ],
      ),
    );
  }
  
  Widget _buildProfileOption(BuildContext context, String title, IconData icon, {bool isLogout = false}) {
    return ListTile(
      leading: Icon(icon, color: isLogout ? Colors.red : Color(0xFF4A5568)),
      title: Text(title, style: TextStyle(fontWeight: FontWeight.w500, color: isLogout ? Colors.red : Color(0xFF2D3748))),
      trailing: isLogout ? null : Icon(Icons.arrow_forward_ios, size: 16, color: Color(0xFF718096)),
      onTap: () async { // Made async to await for navigation result
        if (isLogout) {
          _pbService.logout();
          Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => LoginPage()), (route) => false);
        } else if (title == 'Register as Organization') {
          Navigator.push(context, MaterialPageRoute(builder: (context) => OrganizationRegisterScreen()));
        } else if (title == 'Edit Profile') {
          // Navigate to EditProfileScreen and await for a result
          final bool? profileUpdated = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => EditProfileScreen(
                currentName: _userName,
                currentAvatarUrl: _userAvatarUrl,
              ),
            ),
          );
          // If profileUpdated is true, reload profile data
          if (profileUpdated == true) {
            _loadProfileData();
          }
        }
      },
    );
  }

  // --- START: KODE BOTTOM BAR YANG DIPERBARUI ---

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

          // Menggunakan logika navigasi yang sudah ada sebelumnya
          if (index == 0) {
            // Kembali ke home screen. Jika ProfileScreen adalah bagian dari tumpukan
            // HomeScreen, maka pop() sudah cukup. Jika tidak, gunakan popUntil.
            // Di sini kita asumsikan ProfileScreen dibuka dari HomeScreen.
            Navigator.pop(context); 
          } else {
              switch (index) {
                case 1: Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => SearchScreen())); break;
                case 2: Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => GamificationScreen())); break;
                case 3: Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => VolunteerHoursScreen())); break;
              }
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
}