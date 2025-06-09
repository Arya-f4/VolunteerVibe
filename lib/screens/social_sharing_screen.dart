import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class SocialSharingScreen extends StatefulWidget {
  @override
  _SocialSharingScreenState createState() => _SocialSharingScreenState();
}

class _SocialSharingScreenState extends State<SocialSharingScreen> {
  final List<Map<String, dynamic>> _recentActivities = [
    {
      'title': 'Beach Cleanup Drive',
      'organization': 'Ocean Warriors',
      'date': 'Dec 10, 2024',
      'points': 50,
      'hours': 4,
      'participants': 45,
      'image': 'https://images.unsplash.com/photo-1583212292454-1fe6229603b7?w=400',
      'category': 'Environment',
      'shared': false,
    },
    {
      'title': 'Food Bank Volunteer',
      'organization': 'Community Kitchen',
      'date': 'Dec 5, 2024',
      'points': 40,
      'hours': 3,
      'participants': 30,
      'image': 'https://images.unsplash.com/photo-1593113598332-cd288d649433?w=400',
      'category': 'Community',
      'shared': true,
    },
    {
      'title': 'Reading Program for Kids',
      'organization': 'Bright Futures',
      'date': 'Nov 28, 2024',
      'points': 35,
      'hours': 3,
      'participants': 20,
      'image': 'https://images.unsplash.com/photo-1481627834876-b7833e8f5570?w=400',
      'category': 'Education',
      'shared': true,
    },
  ];

  final List<Map<String, dynamic>> _socialPlatforms = [
    {
      'name': 'Facebook',
      'icon': Icons.facebook,
      'color': Color(0xFF1877F2),
      'connected': true,
    },
    {
      'name': 'Instagram',
      'icon': Icons.camera_alt,
      'color': Color(0xFFE4405F),
      'connected': true,
    },
    {
      'name': 'Twitter',
      'icon': Icons.alternate_email,
      'color': Color(0xFF1DA1F2),
      'connected': false,
    },
    {
      'name': 'LinkedIn',
      'icon': Icons.work,
      'color': Color(0xFF0A66C2),
      'connected': false,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Social Sharing',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF2D3748),
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: Color(0xFF2D3748)),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.settings, color: Color(0xFF6C63FF)),
            onPressed: _showSocialSettings,
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSharingStats(),
              _buildConnectedAccounts(),
              _buildRecentActivities(),
              _buildSharingTips(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSharingStats() {
    return Container(
      margin: EdgeInsets.all(24),
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF6C63FF), Color(0xFF9F7AEA)],
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
              Icon(Icons.share, color: Colors.white, size: 32),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Sharing Impact',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      'Inspire others to volunteer',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.white.withOpacity(0.9),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _buildStatItem('7', 'Posts Shared', Icons.share),
              ),
              Expanded(
                child: _buildStatItem('142', 'People Reached', Icons.people),
              ),
              Expanded(
                child: _buildStatItem('23', 'Inspired to Join', Icons.favorite),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String value, String label, IconData icon) {
    return Column(
      children: [
        Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(25),
          ),
          child: Icon(icon, color: Colors.white, size: 24),
        ),
        SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
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
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildConnectedAccounts() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 24),
      padding: EdgeInsets.all(20),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Connected Accounts',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2D3748),
                ),
              ),
              Spacer(),
              TextButton(
                onPressed: _showSocialSettings,
                child: Text(
                  'Manage',
                  style: TextStyle(color: Color(0xFF6C63FF)),
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          GridView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 3,
            ),
            itemCount: _socialPlatforms.length,
            itemBuilder: (context, index) {
              final platform = _socialPlatforms[index];
              return _buildPlatformCard(platform);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPlatformCard(Map<String, dynamic> platform) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: platform['connected'] 
            ? platform['color'].withOpacity(0.1) 
            : Color(0xFFF7FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: platform['connected'] 
              ? platform['color'].withOpacity(0.3) 
              : Color(0xFFE2E8F0),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: platform['connected'] 
                  ? platform['color'] 
                  : Color(0xFFE2E8F0),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              platform['icon'],
              color: Colors.white,
              size: 16,
            ),
          ),
          SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  platform['name'],
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: platform['connected'] 
                        ? Color(0xFF2D3748) 
                        : Color(0xFF718096),
                  ),
                ),
                Text(
                  platform['connected'] ? 'Connected' : 'Not connected',
                  style: TextStyle(
                    fontSize: 10,
                    color: platform['connected'] 
                        ? Color(0xFF10B981) 
                        : Color(0xFF718096),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentActivities() {
    return Container(
      margin: EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Recent Activities',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2D3748),
            ),
          ),
          SizedBox(height: 16),
          ListView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            itemCount: _recentActivities.length,
            itemBuilder: (context, index) {
              return _buildActivityCard(_recentActivities[index]);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildActivityCard(Map<String, dynamic> activity) {
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 120,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
              gradient: LinearGradient(
                colors: [Color(0xFF6C63FF), Color(0xFF9F7AEA)],
              ),
            ),
            child: Stack(
              children: [
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: activity['shared'] 
                          ? Color(0xFF10B981) 
                          : Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          activity['shared'] ? Icons.check : Icons.share,
                          size: 12,
                          color: activity['shared'] ? Colors.white : Color(0xFF6C63FF),
                        ),
                        SizedBox(width: 4),
                        Text(
                          activity['shared'] ? 'Shared' : 'Share',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: activity['shared'] ? Colors.white : Color(0xFF6C63FF),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Center(
                  child: Icon(
                    _getCategoryIcon(activity['category']),
                    size: 48,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  activity['title'],
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2D3748),
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  activity['organization'],
                  style: TextStyle(
                    color: Color(0xFF718096),
                    fontSize: 14,
                  ),
                ),
                SizedBox(height: 12),
                Row(
                  children: [
                    _buildActivityStat(Icons.star, '${activity['points']} pts', Color(0xFFFFD700)),
                    SizedBox(width: 16),
                    _buildActivityStat(Icons.access_time, '${activity['hours']}h', Color(0xFF6C63FF)),
                    SizedBox(width: 16),
                    _buildActivityStat(Icons.people, '${activity['participants']}', Color(0xFF10B981)),
                  ],
                ),
                SizedBox(height: 16),
                if (!activity['shared'])
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _showShareDialog(activity),
                      icon: Icon(Icons.share, size: 18),
                      label: Text('Share Your Impact'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFF6C63FF),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  )
                else
                  Container(
                    width: double.infinity,
                    padding: EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      color: Color(0xFF10B981).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check_circle, color: Color(0xFF10B981), size: 18),
                        SizedBox(width: 8),
                        Text(
                          'Shared successfully',
                          style: TextStyle(
                            color: Color(0xFF10B981),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityStat(IconData icon, String value, Color color) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        SizedBox(width: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Color(0xFF4A5568),
          ),
        ),
      ],
    );
  }

  Widget _buildSharingTips() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 24),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Color(0xFFF7FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.lightbulb, color: Color(0xFF6C63FF)),
              SizedBox(width: 8),
              Text(
                'Sharing Tips',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2D3748),
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          _buildTip('Share your volunteer experiences to inspire others'),
          _buildTip('Use hashtags like #VolunteerVibe #MakeADifference'),
          _buildTip('Tag friends who might be interested in volunteering'),
          _buildTip('Share photos from your volunteer activities'),
        ],
      ),
    );
  }

  Widget _buildTip(String tip) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 6,
            height: 6,
            margin: EdgeInsets.only(top: 6),
            decoration: BoxDecoration(
              color: Color(0xFF6C63FF),
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              tip,
              style: TextStyle(
                color: Color(0xFF4A5568),
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showShareDialog(Map<String, dynamic> activity) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.6,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.all(20),
              child: Row(
                children: [
                  Text(
                    'Share Your Impact',
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
                  children: [
                    _buildSharePreview(activity),
                    SizedBox(height: 24),
                    _buildSharePlatforms(activity),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSharePreview(Map<String, dynamic> activity) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Color(0xFFF7FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Preview',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF718096),
            ),
          ),
          SizedBox(height: 12),
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 5,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '🌟 Just completed "${activity['title']}" with ${activity['organization']}!',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF2D3748),
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Earned ${activity['points']} points and contributed ${activity['hours']} hours to make a difference in our community! 💪',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF4A5568),
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  '#VolunteerVibe #MakeADifference #CommunityService',
                  style: TextStyle(
                    fontSize: 12,
                    color: Color(0xFF6C63FF),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSharePlatforms(Map<String, dynamic> activity) {
    final connectedPlatforms = _socialPlatforms.where((p) => p['connected']).toList();
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Share to',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2D3748),
          ),
        ),
        SizedBox(height: 16),
        GridView.builder(
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 2.5,
          ),
          itemCount: connectedPlatforms.length,
          itemBuilder: (context, index) {
            final platform = connectedPlatforms[index];
            return _buildShareButton(platform, activity);
          },
        ),
        SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => _copyToClipboard(activity),
            icon: Icon(Icons.copy),
            label: Text('Copy Link'),
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: Color(0xFF6C63FF)),
              foregroundColor: Color(0xFF6C63FF),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildShareButton(Map<String, dynamic> platform, Map<String, dynamic> activity) {
    return ElevatedButton(
      onPressed: () => _shareToplatform(platform, activity),
      style: ElevatedButton.styleFrom(
        backgroundColor: platform['color'],
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(platform['icon'], size: 18),
          SizedBox(width: 8),
          Text(
            platform['name'],
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  void _showSocialSettings() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.all(20),
              child: Row(
                children: [
                  Text(
                    'Social Settings',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2D3748),
                    ),
                  ),
                  Spacer(),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text('Done'),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: EdgeInsets.symmetric(horizontal: 20),
                itemCount: _socialPlatforms.length,
                itemBuilder: (context, index) {
                  final platform = _socialPlatforms[index];
                  return _buildPlatformSetting(platform, index);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlatformSetting(Map<String, dynamic> platform, int index) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Color(0xFFE2E8F0)),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: platform['color'],
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              platform['icon'],
              color: Colors.white,
              size: 20,
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  platform['name'],
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2D3748),
                  ),
                ),
                Text(
                  platform['connected'] ? 'Connected' : 'Not connected',
                  style: TextStyle(
                    fontSize: 14,
                    color: platform['connected'] ? Color(0xFF10B981) : Color(0xFF718096),
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: platform['connected'],
            onChanged: (value) {
              setState(() {
                _socialPlatforms[index]['connected'] = value;
              });
            },
            activeColor: Color(0xFF6C63FF),
          ),
        ],
      ),
    );
  }

  void _shareToplatform(Map<String, dynamic> platform, Map<String, dynamic> activity) {
    Navigator.pop(context);
    
    // Simulate sharing
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Shared to ${platform['name']} successfully!'),
        backgroundColor: Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
      ),
    );

    // Update activity as shared
    setState(() {
      activity['shared'] = true;
    });
  }

  void _copyToClipboard(Map<String, dynamic> activity) {
    final text = '🌟 Just completed "${activity['title']}" with ${activity['organization']}! Earned ${activity['points']} points and contributed ${activity['hours']} hours to make a difference! #VolunteerVibe #MakeADifference';
    
    Clipboard.setData(ClipboardData(text: text));
    Navigator.pop(context);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Copied to clipboard!'),
        backgroundColor: Color(0xFF6C63FF),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Environment':
        return Icons.eco;
      case 'Education':
        return Icons.school;
      case 'Health':
        return Icons.health_and_safety;
      case 'Community':
        return Icons.people;
      case 'Animals':
        return Icons.pets;
      default:
        return Icons.volunteer_activism;
    }
  }
}
