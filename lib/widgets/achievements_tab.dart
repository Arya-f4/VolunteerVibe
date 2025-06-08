import 'package:flutter/material.dart';
import '../utils/app_colors.dart';

class AchievementsTab extends StatelessWidget {
  final int userPoints = 1250;
  final String userLevel = "Community Helper";

  final List<Map<String, dynamic>> badges = [
    {'name': 'First Timer', 'icon': '🌟', 'earned': true},
    {'name': 'Team Player', 'icon': '🤝', 'earned': true},
    {'name': 'Eco Warrior', 'icon': '🌱', 'earned': true},
    {'name': 'Helper Hero', 'icon': '🦸', 'earned': true},
    {'name': 'Community Champion', 'icon': '🏆', 'earned': true},
    {'name': 'Mentor Master', 'icon': '👨‍🏫', 'earned': false},
  ];

  final List<Map<String, dynamic>> recentAchievements = [
    {
      'text': 'Completed Beach Cleanup Drive',
      'points': 50,
      'date': '2 days ago',
    },
    {
      'text': 'Earned Team Player badge',
      'points': 25,
      'date': '1 week ago',
    },
    {
      'text': 'Reached 1000 points milestone',
      'points': 100,
      'date': '2 weeks ago',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Points Header
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
                SizedBox(height: 8),
                Text(
                  '$userPoints Points',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Level: $userLevel',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
                SizedBox(height: 16),
                Container(
                  height: 8,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: 0.75,
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  '250 points to next level',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 24),

          // Badges Section
          Text(
            'Your Badges',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1,
            ),
            itemCount: badges.length,
            itemBuilder: (context, index) {
              final badge = badges[index];
              return Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: badge['earned'] ? Colors.white : Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      badge['icon'],
                      style: TextStyle(
                        fontSize: 32,
                        color: badge['earned'] ? null : Colors.grey,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      badge['name'],
                      style: TextStyle(
                        fontSize: 12,
                        color: badge['earned'] ? AppColors.textPrimary : Colors.grey,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              );
            },
          ),
          SizedBox(height: 24),

          // Recent Achievements
          Text(
            'Recent Achievements',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 16),
          ListView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            itemCount: recentAchievements.length,
            itemBuilder: (context, index) {
              final achievement = recentAchievements[index];
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
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            achievement['text'],
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            achievement['date'],
                            style: TextStyle(
                              fontSize: 12,
                              color: AppColors.textTertiary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Row(
                      children: [
                        Icon(Icons.emoji_events, size: 16, color: AppColors.textTertiary),
                        SizedBox(width: 4),
                        Text(
                          '+${achievement['points']}',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textTertiary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
