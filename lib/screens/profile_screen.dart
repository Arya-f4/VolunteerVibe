import 'package:flutter/material.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:volunteervibe/services/pocketbase_service.dart';
import 'package:volunteervibe/screens/search_screen.dart';
import 'package:volunteervibe/screens/gamification_screen.dart';
import 'package:volunteervibe/screens/volunteer_hours_screen.dart';
import 'package:volunteervibe/screens/organization_register_screen.dart';
import 'package:volunteervibe/auth/login_page.dart';
import 'package:volunteervibe/screens/edit_profile_screen.dart';

class ProfileScreen extends StatefulWidget {
  final bool fromHomeScreen;

  const ProfileScreen({
    Key? key,
    this.fromHomeScreen = false,
  }) : super(key: key);

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final PocketBaseService _pbService = PocketBaseService();

  bool _isLoading = true;
  String _userName = 'Guest';
  String _userEmail = '...';
  String? _userAvatarUrl;
  int _userPoints = 0;
  int _eventsJoined = 0;

  List<RecordModel> _allPossibleAchievements = [];
  List<String> _earnedAchievementIds = [];

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final userRecord = await _pbService.fetchCurrentUserWithAchievements();
      final allAchievements = await _pbService.fetchAllAchievements();

      if (mounted) {
        if (userRecord != null) {
          _userName = userRecord.getStringValue('name', 'Guest');
          _userEmail = userRecord.getStringValue('email', 'no-email@example.com');
          _userPoints = userRecord.getIntValue('points', 0);
          final avatarFilename = userRecord.getStringValue('avatar');
          if (avatarFilename.isNotEmpty) {
            _userAvatarUrl = _pbService.getFileUrl(userRecord, avatarFilename);
          } else {
            _userAvatarUrl = null;
          }
          _earnedAchievementIds = userRecord.getListValue<String>('achievment_id');
          _eventsJoined = await _pbService.getEventsJoinedCount(userRecord.id);
        }
        
        _allPossibleAchievements = allAchievements;
      }
    } catch (e) {
      print("Error loading profile data: $e");
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.fromHomeScreen) {
      return RefreshIndicator(
        onRefresh: _loadProfileData,
        color: Color(0xFF6C63FF),
        child: _buildProfileContentBody(),
      );
    }
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
          child: _buildProfileContentBody(),
        ),
      ),
    );
  }

  Widget _buildProfileContentBody() {
    return _isLoading
        ? Center(child: CircularProgressIndicator(color: Color(0xFF6C63FF)))
        : CustomScrollView(
            physics: BouncingScrollPhysics(),
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
            radius: 56,
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
        Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF2D3748))),
        SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 12, color: Color(0xFF718096)), textAlign: TextAlign.center),
      ],
    );
  }
  
  Widget _buildAchievementsSection() {
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
              Text('${_earnedAchievementIds.length}/${_allPossibleAchievements.length} earned', style: TextStyle(color: Color(0xFF718096), fontSize: 14)),
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
            itemCount: _allPossibleAchievements.length,
            itemBuilder: (context, index) {
              final achievement = _allPossibleAchievements[index];
              return _buildAchievementCard(achievement);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAchievementCard(RecordModel achievement) {
    final bool isEarned = _earnedAchievementIds.contains(achievement.id);
    final String name = achievement.getStringValue('badge_name');
    final String description = achievement.getStringValue('description');
    final String iconUrl = _pbService.getFileUrl(achievement, achievement.getStringValue('icon')) ?? '';

    final Color unearnedColor = Colors.grey.shade400;
    final Color earnedColor = Color(0xFF6C63FF);

    return Tooltip(
      message: '$name\n"$description"',
      padding: EdgeInsets.all(12),
      textStyle: TextStyle(color: Colors.white, fontSize: 14),
      decoration: BoxDecoration(color: Colors.black.withOpacity(0.8), borderRadius: BorderRadius.circular(8)),
      child: Opacity(
        opacity: isEarned ? 1.0 : 0.4,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: isEarned ? earnedColor.withOpacity(0.15) : unearnedColor.withOpacity(0.15),
              child: Image.network(
                iconUrl,
                width: 32,
                height: 32,
                errorBuilder: (context, error, stackTrace) => Icon(Icons.shield, color: isEarned ? earnedColor : unearnedColor),
              ),
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
      onTap: () async {
        if (isLogout) {
          _pbService.logout();
          Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (context) => LoginPage()), (route) => false);
        } else if (title == 'Register as Organization') {
          Navigator.push(context, MaterialPageRoute(builder: (context) => OrganizationRegisterScreen()));
        } else if (title == 'Edit Profile') {
          final bool? profileUpdated = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => EditProfileScreen(
                currentName: _userName,
                currentAvatarUrl: _userAvatarUrl,
              ),
            ),
          );
          if (profileUpdated == true) {
            _loadProfileData();
          }
        }
      },
    );
  }
}