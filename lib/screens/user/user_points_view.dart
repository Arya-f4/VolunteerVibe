import 'package:flutter/material.dart';
import '../../utils/app_colors.dart';
import '../../models/event.dart';

class UserPointsView extends StatelessWidget {
  final User user;

  UserPointsView({required this.user});

  final List<Map<String, dynamic>> pointsHistory = [
    {
      'eventName': 'Beach Cleanup Drive',
      'points': 50,
      'date': DateTime(2024, 12, 10),
      'type': 'earned',
    },
    {
      'eventName': 'Food Bank Volunteer',
      'points': 40,
      'date': DateTime(2024, 12, 5),
      'type': 'earned',
    },
    {
      'eventName': 'Youth Mentoring Program',
      'points': 60,
      'date': DateTime(2024, 11, 28),
      'type': 'earned',
    },
    {
      'eventName': 'Reward Redemption',
      'points': -25,
      'date': DateTime(2024, 11, 20),
      'type': 'redeemed',
    },
  ];

  final List<Map<String, dynamic>> achievements = [
    {
      'title': 'First Timer',
      'description': 'Complete your first volunteer event',
      'icon': '🌟',
      'earned': true,
      'points': 25,
    },
    {
      'title': 'Team Player',
      'description': 'Participate in 5 community events',
      'icon': '🤝',
      'earned': true,
      'points': 50,
    },
    {
      'title': 'Eco Warrior',
      'description': 'Join 3 environmental events',
      'icon': '🌱',
      'earned': true,
      'points': 75,
    },
    {
      'title': 'Mentor Master',
      'description': 'Complete 10 education events',
      'icon': '👨‍🏫',
      'earned': false,
      'points': 100,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Points Overview Card
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [AppColors.primary, AppColors.primaryDark],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.emoji_events,
                  size: 48,
                  color: Colors.white,
                ),
                SizedBox(height: 12),
                Text(
                  '${user.points}',
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                Text(
                  'Total Points',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
                SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildStatItem('${user.completedEvents.length}', 'Events\nCompleted'),
                    _buildStatItem('${user.registeredEvents.length}', 'Upcoming\nEvents'),
                    _buildStatItem('${achievements.where((a) => a['earned']).length}', 'Achievements\nUnlocked'),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(height: 24),

          // Quick Stats
          Row(
            children: [
              Expanded(
                child: _buildQuickStatCard(
                  'This Month',
                  '150',
                  'Points Earned',
                  Icons.trending_up,
                  AppColors.success,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _buildQuickStatCard(
                  'Rank',
                  '#42',
                  'Leaderboard',
                  Icons.leaderboard,
                  AppColors.warning,
                ),
              ),
            ],
          ),
          SizedBox(height: 24),

          // Achievements Section
          Text(
            'Achievements',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.2,
            ),
            itemCount: achievements.length,
            itemBuilder: (context, index) {
              final achievement = achievements[index];
              return _buildAchievementCard(achievement);
            },
          ),
          SizedBox(height: 24),

          // Points History
          Text(
            'Points History',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 12),
          ListView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            itemCount: pointsHistory.length,
            itemBuilder: (context, index) {
              return _buildHistoryItem(pointsHistory[index]);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.white.withOpacity(0.8),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildQuickStatCard(String title, String value, String subtitle, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Icon(
                icon,
                size: 20,
                color: color,
              ),
            ],
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
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAchievementCard(Map<String, dynamic> achievement) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: achievement['earned'] ? Colors.white : Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: achievement['earned'] ? AppColors.border : Colors.grey[300]!,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            achievement['icon'],
            style: TextStyle(
              fontSize: 32,
              color: achievement['earned'] ? null : Colors.grey,
            ),
          ),
          SizedBox(height: 8),
          Text(
            achievement['title'],
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: achievement['earned'] ? AppColors.textPrimary : Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 4),
          Text(
            achievement['description'],
            style: TextStyle(
              fontSize: 10,
              color: achievement['earned'] ? AppColors.textSecondary : Colors.grey,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          if (achievement['earned']) ...[
            SizedBox(height: 8),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '+${achievement['points']} pts',
                style: TextStyle(
                  fontSize: 10,
                  color: AppColors.textSecondary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildHistoryItem(Map<String, dynamic> item) {
    final isEarned = item['type'] == 'earned';
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isEarned ? AppColors.surfaceLight : Colors.red[50],
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              isEarned ? Icons.add : Icons.remove,
              color: isEarned ? AppColors.success : AppColors.error,
              size: 20,
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item['eventName'],
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  '${item['date'].day}/${item['date'].month}/${item['date'].year}',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${isEarned ? '+' : ''}${item['points']}',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: isEarned ? AppColors.success : AppColors.error,
            ),
          ),
        ],
      ),
    );
  }
}
