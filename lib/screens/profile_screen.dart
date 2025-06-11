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
class ProfileScreen extends StatefulWidget {
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  // Service
  final PocketBaseService _pbService = PocketBaseService();

  // State
  bool _isLoading = true;
  String _userName = 'Guest';
  String _userEmail = '...';
  String? _userAvatarUrl;
  int _userPoints = 0;
  int _eventsJoined = 0;

  final List<Map<String, dynamic>> _achievements = [
    {'title': 'First Timer','icon': Icons.star, 'color': Color(0xFFFFD700), 'earned': true},
    {'title': 'Community Helper','icon': Icons.people, 'color': Color(0xFF6C63FF), 'earned': true},
    {'title': 'Time Master', 'icon': Icons.access_time_filled, 'color': Color(0xFFED8936), 'earned': true},
    {'title': 'Environmental Warrior','icon': Icons.eco, 'color': Color(0xFF10B981), 'earned': false},
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
      // --- PERBAIKAN DI SINI ---
      _userEmail = userRecord.getStringValue('email'); // Menggunakan getStringValue
      _userPoints = userRecord.getIntValue('points', 0);
      final avatarFilename = userRecord.getStringValue('avatar');
      _userAvatarUrl = _pbService.getFileUrl(userRecord, avatarFilename);
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
            radius: 55,
            backgroundColor: Colors.transparent,
            backgroundImage: _userAvatarUrl != null ? NetworkImage(_userAvatarUrl!) : null,
            child: _userAvatarUrl == null ? Icon(Icons.person, color: Colors.white, size: 60) : null,
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
          ? SizedBox(height: 28, child: Center(child: SizedBox(width:14, height:14, child: CircularProgressIndicator(strokeWidth:2))))
          : Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF2D3748))),
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
      message: "${achievement['title']}\n${achievement['description']}",
      child: Opacity(
        opacity: isEarned ? 1.0 : 0.4,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 25,
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
       padding: EdgeInsets.symmetric(vertical: 12),
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
      trailing: Icon(Icons.arrow_forward_ios, size: 16, color: Color(0xFF718096)),
      onTap: () {
        if (isLogout) {
          _pbService.logout(); // Panggil service yang sudah diperbaiki
          Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
        } else if (title == 'Register as Organization') {
           Navigator.push(context, MaterialPageRoute(builder: (context) => LoginPage()));
        }
      },
    );
  }

  Widget _buildBottomNavigationBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white, 
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: Offset(0, -5))]
      ),
      child: BottomNavigationBar(
        currentIndex: 4, // Index 'Profile' selalu aktif di halaman ini
        onTap: (index) {
          if (index == 4) return;
          if (index == 0) {
            Navigator.popUntil(context, (route) => route.isFirst);
          } else {
             switch (index) {
               case 1: Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => SearchScreen())); break;
               case 2: Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => GamificationScreen())); break;
               case 3: Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => VolunteerHoursScreen())); break;
             }
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