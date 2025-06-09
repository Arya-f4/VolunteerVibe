import 'package:flutter/material.dart';

// Tambahkan import untuk screen baru di bagian atas file
import 'social_sharing_screen.dart';
import 'volunteer_hours_screen.dart';
import 'gamification_screen.dart';
import 'organization_register_screen.dart';

class ProfileScreen extends StatelessWidget {
  final List<Map<String, dynamic>> achievements = [
    {
      'title': 'First Timer',
      'description': 'Complete your first volunteer event',
      'icon': Icons.star,
      'color': Color(0xFFFFD700),
      'earned': true,
    },
    {
      'title': 'Community Helper',
      'description': 'Complete 5 volunteer events',
      'icon': Icons.people,
      'color': Color(0xFF6C63FF),
      'earned': true,
    },
    {
      'title': 'Environmental Warrior',
      'description': 'Complete 3 environmental events',
      'icon': Icons.eco,
      'color': Color(0xFF10B981),
      'earned': false,
    },
    {
      'title': 'Time Master',
      'description': 'Log 50+ volunteer hours',
      'icon': Icons.access_time,
      'color': Color(0xFFED8936),
      'earned': true,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
                    _buildRecentActivities(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Column(
      children: [
        Container(
          width: 120,
          height: 120,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF6C63FF), Color(0xFF9F7AEA)],
            ),
            borderRadius: BorderRadius.circular(60),
            boxShadow: [
              BoxShadow(
                color: Color(0xFF6C63FF).withOpacity(0.3),
                blurRadius: 20,
                offset: Offset(0, 10),
              ),
            ],
          ),
          child: Icon(
            Icons.person,
            color: Colors.white,
            size: 60,
          ),
        ),
        SizedBox(height: 16),
        Text(
          'Alex Johnson',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2D3748),
          ),
        ),
        Text(
          'alex.johnson@email.com',
          style: TextStyle(
            fontSize: 16,
            color: Color(0xFF718096),
          ),
        ),
        SizedBox(height: 8),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: Color(0xFF6C63FF).withOpacity(0.1),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            'Active Volunteer',
            style: TextStyle(
              color: Color(0xFF6C63FF),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatsSection() {
    return Container(
      padding: EdgeInsets.all(24),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'My Impact',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2D3748),
            ),
          ),
          SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  '1,250',
                  'Total Points',
                  Icons.star,
                  Color(0xFFFFD700),
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  '12',
                  'Events Joined',
                  Icons.event,
                  Color(0xFF6C63FF),
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildStatItem(
                  '48',
                  'Hours Logged',
                  Icons.access_time,
                  Color(0xFF10B981),
                ),
              ),
              Expanded(
                child: _buildStatItem(
                  '4',
                  'Badges Earned',
                  Icons.emoji_events,
                  Color(0xFFED8936),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String value, String label, IconData icon, Color color) {
    return Column(
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(25),
          ),
          child: Icon(icon, color: color, size: 24),
        ),
        SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2D3748),
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Color(0xFF718096),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildAchievementsSection() {
    return Container(
      padding: EdgeInsets.all(24),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Achievements',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2D3748),
                ),
              ),
              Spacer(),
              Text(
                '3/4 earned',
                style: TextStyle(
                  color: Color(0xFF718096),
                  fontSize: 14,
                ),
              ),
            ],
          ),
          SizedBox(height: 20),
          GridView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.2,
            ),
            itemCount: achievements.length,
            itemBuilder: (context, index) {
              final achievement = achievements[index];
              return _buildAchievementCard(achievement);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildAchievementCard(Map<String, dynamic> achievement) {
    final isEarned = achievement['earned'] as bool;
    
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isEarned ? achievement['color'].withOpacity(0.1) : Color(0xFFF7FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isEarned ? achievement['color'].withOpacity(0.3) : Color(0xFFE2E8F0),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isEarned ? achievement['color'] : Color(0xFFE2E8F0),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              achievement['icon'],
              color: isEarned ? Colors.white : Color(0xFF718096),
              size: 20,
            ),
          ),
          SizedBox(height: 8),
          Text(
            achievement['title'],
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: isEarned ? Color(0xFF2D3748) : Color(0xFF718096),
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 4),
          Text(
            achievement['description'],
            style: TextStyle(
              fontSize: 10,
              color: Color(0xFF718096),
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildRecentActivities() {
    return Container(
      padding: EdgeInsets.all(24),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Recent Activities',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2D3748),
            ),
          ),
          SizedBox(height: 20),
          _buildActivityItem(
            'Beach Cleanup Drive',
            'Completed • Dec 10, 2024',
            Icons.eco,
            Color(0xFF10B981),
            '+50 points',
          ),
          _buildActivityItem(
            'Food Bank Volunteer',
            'Completed • Dec 5, 2024',
            Icons.people,
            Color(0xFF6C63FF),
            '+40 points',
          ),
          _buildActivityItem(
            'Reading Program for Kids',
            'Registered • Dec 20, 2024',
            Icons.school,
            Color(0xFFED8936),
            'Upcoming',
          ),
        ],
      ),
    );
  }

  Widget _buildActivityItem(String title, String subtitle, IconData icon, Color color, String points) {
    return Padding(
      padding: EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2D3748),
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF718096),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: points.contains('points') ? Color(0xFFFFD700).withOpacity(0.1) : color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              points,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: points.contains('points') ? Color(0xFFFFD700) : color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Dalam method _buildProfileOption, update untuk menambahkan navigasi:
Widget _buildProfileOption(BuildContext context, String title, IconData icon, {bool isLogout = false}) {
  return Container(
    margin: EdgeInsets.only(bottom: 12),
    child: ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: isLogout ? Colors.red.withOpacity(0.1) : Color(0xFF6C63FF).withOpacity(0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Icon(
          icon,
          color: isLogout ? Colors.red : Color(0xFF6C63FF),
          size: 20,
        ),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontWeight: FontWeight.w500,
          color: isLogout ? Colors.red : Color(0xFF2D3748),
        ),
      ),
      trailing: Icon(
        Icons.arrow_forward_ios,
        size: 16,
        color: Color(0xFF718096),
      ),
      onTap: () {
        if (isLogout) {
          Navigator.pushReplacementNamed(context, '/welcome');
        } else {
          switch (title) {
            case 'My Events':
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => VolunteerHoursScreen()),
              );
              break;
            case 'Achievements':
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => GamificationScreen()),
              );
              break;
            case 'Social Sharing':
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => SocialSharingScreen()),
              );
              break;
            case 'Organization Portal':
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => OrganizationRegisterScreen()),
              );
              break;
            default:
              // Handle other options
              break;
          }
        }
      },
    ),
  );
}

// Update _buildProfileContent() untuk menambahkan opsi baru:
Widget _buildProfileContent(BuildContext context) {
  return Padding(
    padding: EdgeInsets.all(24.0),
    child: Column(
      children: [
        Text(
          'Profile',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        SizedBox(height: 24),
        Container(
          width: 100,
          height: 100,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF6C63FF), Color(0xFF9F7AEA)],
            ),
            borderRadius: BorderRadius.circular(50),
          ),
          child: Icon(
            Icons.person,
            color: Colors.white,
            size: 48,
          ),
        ),
        SizedBox(height: 16),
        Text(
          'Alex Johnson',
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        Text(
          'alex.johnson@email.com',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        SizedBox(height: 32),
        _buildProfileOption(context, 'My Events', Icons.event),
        _buildProfileOption(context, 'Achievements', Icons.emoji_events),
        _buildProfileOption(context, 'Social Sharing', Icons.share),
        _buildProfileOption(context, 'Organization Portal', Icons.business),
        _buildProfileOption(context, 'Settings', Icons.settings),
        _buildProfileOption(context, 'Help & Support', Icons.help),
        _buildProfileOption(context, 'Logout', Icons.logout, isLogout: true),
      ],
    ),
  );
}
}
