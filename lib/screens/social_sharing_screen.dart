import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:volunteervibe/services/pocketbase_service.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:volunteervibe/utils/app_constants.dart';

class SocialSharingScreen extends StatefulWidget {
  @override
  _SocialSharingScreenState createState() => _SocialSharingScreenState();
}

class _SocialSharingScreenState extends State<SocialSharingScreen> {
  final PocketBaseService _pbService = PocketBaseService();

  List<RecordModel> _recentActivities = [];
  bool _isLoading = true;
  int _userTotalShares = 0;

  final Map<String, String> _platformIconImageUrls = {
    'Facebook': 'https://img.freepik.com/premium-vector/circle-facebook-logotype-icon-social-media-app-network-application-popular-editorial-brand-vector-illustration_913857-373.jpg?semt=ais_hybrid&w=740',
    'Instagram': 'https://static.vecteezy.com/system/resources/previews/042/148/632/non_2x/instagram-logo-instagram-social-media-icon-free-png.png',
    'WhatsApp': 'https://i.pinimg.com/474x/e9/da/0c/e9da0c83b0a7ec866e17c100079c9d88.jpg',
    'Twitter': 'https://images.icon-icons.com/1121/PNG/512/1486147222-social-media-network22_79488.png',
    'LinkedIn': 'https://static.vecteezy.com/system/resources/previews/018/910/721/non_2x/linkedin-logo-linkedin-symbol-linkedin-icon-free-free-vector.jpg',
  };

  final List<Map<String, dynamic>> _socialPlatforms = [
    {
      'name': 'Facebook',
      'icon': Icons.facebook,
      'color': Color(0xFF1877F2),
      'connected': true,
      'share_url_template': 'https://www.facebook.com/sharer/sharer.php?u={link}&quote={text}',
    },
    {
      'name': 'Instagram',
      'icon': Icons.camera_alt,
      'color': Color(0xFFE4405F),
      'connected': true,
      'share_url_template': 'https://www.instagram.com',
    },
    {
      'name': 'WhatsApp',
      'icon': Icons.facebook,
      'color': Color(0xFF25D366),
      'connected': true,
      'share_url_template': 'whatsapp://send?text={text}',
    },
    {
      'name': 'Twitter',
      'icon': Icons.alternate_email,
      'color': Color(0xFF1DA1F2),
      'connected': true,
      'share_url_template': 'https://twitter.com/intent/tweet?text={text}&url={link}',
    },
    {
      'name': 'LinkedIn',
      'icon': Icons.work,
      'color': Color(0xFF0A66C2),
      'connected': true,
      'share_url_template': 'https://www.linkedin.com/shareArticle?mini=true&url={link}&title={title}&summary={description}',
    },
  ];

  @override
  void initState() {
    super.initState();
    _loadSharingData();
  }

  Future<void> _loadSharingData() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final currentUser = _pbService.getCurrentUser();
      if (currentUser != null) {
        final events = await _pbService.fetchJoinedEvents(userId: currentUser.id);
        final sharedCount = await _pbService.getUserSharedCount();
        setState(() {
          _recentActivities = events;
          _userTotalShares = sharedCount;
        });
      } else {
        setState(() {
          _recentActivities = [];
          _userTotalShares = 0;
        });
      }
    } catch (e) {
      print("Error loading sharing data: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to load sharing data: $e")),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

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
        child: RefreshIndicator(
          onRefresh: _loadSharingData,
          color: Color(0xFF6C63FF),
          child: SingleChildScrollView(
            physics: AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSharingStats(),
                _buildRecentActivities(),
                _buildSharingTips(),
              ],
            ),
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
              _buildStatItem(_userTotalShares.toString(), 'Posts Shared', Icons.share),
            ],
          ),
          SizedBox(height: 24),
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
          _isLoading
              ? Center(child: CircularProgressIndicator(color: Color(0xFF6C63FF)))
              : _recentActivities.isEmpty
                  ? _buildEmptyState()
                  : ListView.builder(
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

  Widget _buildActivityCard(RecordModel activityRecord) {
    final String title = activityRecord.getStringValue('title', 'No Title');
    final DateTime eventDate = DateFormat('yyyy-MM-dd').parse(activityRecord.getStringValue('date', DateTime.now().toIso8601String()));
    final int hours = activityRecord.getIntValue('duration_hours', 4);
    final int points = activityRecord.getIntValue('point_event', 0);
    final int maxParticipants = activityRecord.getIntValue('max_participant', 0);

    final organization = activityRecord.expand['organization_id']?.first;
    final category = activityRecord.expand['categories_id']?.first;

    final String orgName = organization?.getStringValue('name', 'Unknown Org') ?? 'Unknown Org';
    final String categoryName = category?.getStringValue('name', 'No Category') ?? 'No Category';

    String? orgAvatarUrl;
    if (organization != null && organization.getStringValue('avatar').isNotEmpty) {
      orgAvatarUrl = _pbService.getFileUrl(organization, organization.getStringValue('avatar'));
    }

    bool isShared = activityRecord.data.containsKey('isShared') ? activityRecord.getBoolValue('isShared') : false;

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
              gradient: orgAvatarUrl == null ? LinearGradient(
                colors: [Color(0xFF6C63FF), Color(0xFF9F7AEA)],
              ) : null,
              image: orgAvatarUrl != null
                  ? DecorationImage(
                      image: NetworkImage(orgAvatarUrl),
                      fit: BoxFit.cover,
                      colorFilter: ColorFilter.mode(Colors.black.withOpacity(0.3), BlendMode.darken),
                    )
                  : null,
            ),
            child: Stack(
              children: [
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isShared
                          ? Color(0xFF10B981)
                          : Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isShared ? Icons.check : Icons.share,
                          size: 12,
                          color: isShared ? Colors.white : Color(0xFF6C63FF),
                        ),
                        SizedBox(width: 4),
                        Text(
                          isShared ? 'Shared' : 'Share',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: isShared ? Colors.white : Color(0xFF6C63FF),
                          ),
                        ),
                      ],
                    ),
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
                  title,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2D3748),
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  orgName,
                  style: TextStyle(
                    color: Color(0xFF718096),
                    fontSize: 14,
                  ),
                ),
                SizedBox(height: 12),
                Row(
                  children: [
                    Icon(Icons.calendar_today, size: 14, color: Colors.grey.shade500),
                    SizedBox(width: 6),
                    Text(
                      DateFormat('MMM dd,EEEE').format(eventDate),
                      style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                    ),
                  ],
                ),
                SizedBox(height: 12),
                Row(
                  children: [
                    _buildActivityStat(Icons.star, '$points pts', Color(0xFFFFD700)),
                    SizedBox(width: 16),
                    _buildActivityStat(Icons.people, '$maxParticipants', Color(0xFF10B981)),
                  ],
                ),
                SizedBox(height: 16),
                if (!isShared)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _showShareDialog(activityRecord),
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
      margin: EdgeInsets.symmetric(horizontal: 24, vertical: 24),
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

  void _showShareDialog(RecordModel activityRecord) {
    final String title = activityRecord.getStringValue('title', 'No Title');
    final String orgName = activityRecord.expand['organization_id']?.first.getStringValue('name', 'Unknown Org') ?? 'Unknown Org';
    final int points = activityRecord.getIntValue('point_event', 0);
    final DateTime eventDate = DateFormat('yyyy-MM-dd').parse(activityRecord.getStringValue('date', DateTime.now().toIso8601String()));
    final String formattedDate = DateFormat('MMMM dd,EEEE').format(eventDate);
    final String description = activityRecord.getStringValue('description', 'It was a great experience contributing to our community!');

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.75, // Increased height
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 20,
              offset: Offset(0, -5),
            ),
          ],
        ),
        child: Column(
          children: [
            // Handle bar
            Container(
              margin: EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Header
            Container(
              padding: EdgeInsets.all(24),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Color(0xFF6C63FF).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.share,
                      color: Color(0xFF6C63FF),
                      size: 24,
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Share Your Impact',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2D3748),
                          ),
                        ),
                        Text(
                          'Inspire others to volunteer',
                          style: TextStyle(
                            fontSize: 14,
                            color: Color(0xFF718096),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.close, color: Color(0xFF718096)),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.grey.shade100,
                      shape: CircleBorder(),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    _buildSharePreview(activityRecord),
                    SizedBox(height: 32),
                    _buildSharePlatforms(activityRecord),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSharePreview(RecordModel activityRecord) {
    final String title = activityRecord.getStringValue('title', 'No Title');
    final String orgName = activityRecord.expand['organization_id']?.first.getStringValue('name', 'Unknown Org') ?? 'Unknown Org';
    final int points = activityRecord.getIntValue('point_event', 0);
    final DateTime eventDate = DateFormat('yyyy-MM-dd').parse(activityRecord.getStringValue('date', DateTime.now().toIso8601String()));
    final String formattedDate = DateFormat('MMMM dd,EEEE').format(eventDate);
    final String description = activityRecord.getStringValue('description', 'It was a great experience contributing to our community!');

    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Color(0xFFE2E8F0)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.preview, color: Color(0xFF6C63FF), size: 20),
              SizedBox(width: 8),
              Text(
                'Preview',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF2D3748),
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '🌟 Just completed "$title" with $orgName on $formattedDate!',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF2D3748),
                    height: 1.4,
                  ),
                ),
                SizedBox(height: 12),
                Text(
                  'I earned $points points for this event. ${description.isNotEmpty ? description : 'It was a great experience contributing to our community!'} 💪',
                  style: TextStyle(
                    fontSize: 14,
                    color: Color(0xFF4A5568),
                    height: 1.5,
                  ),
                ),
                SizedBox(height: 12),
                Text(
                  '#VolunteerVibe #MakeADifference #CommunityService',
                  style: TextStyle(
                    fontSize: 13,
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

  Widget _buildSharePlatforms(RecordModel activityRecord) {
    final connectedPlatforms = _socialPlatforms.where((p) => p['connected']).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Share to',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2D3748),
          ),
        ),
        SizedBox(height: 20),
        // Enhanced platform buttons with better visibility
        Column(
          children: connectedPlatforms.map((platform) {
            return Container(
              margin: EdgeInsets.only(bottom: 12),
              child: _buildEnhancedShareButton(platform, activityRecord),
            );
          }).toList(),
        ),
        SizedBox(height: 20),
        // Copy link button
        Container(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () => _copyToClipboard(activityRecord),
            icon: Icon(Icons.copy, size: 20),
            label: Text(
              'Copy Link',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            style: OutlinedButton.styleFrom(
              padding: EdgeInsets.symmetric(vertical: 16),
              side: BorderSide(color: Color(0xFF6C63FF), width: 2),
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

  Widget _buildEnhancedShareButton(Map<String, dynamic> platform, RecordModel activityRecord) {
    String? imageUrl = _platformIconImageUrls[platform['name']];
    Widget iconWidget;

    if (imageUrl != null) {
      iconWidget = ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.network(
          imageUrl,
          width: 32,
          height: 32,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return Icon(platform['icon'], size: 24, color: Colors.white);
          },
        ),
      );
    } else {
      iconWidget = Icon(platform['icon'], size: 24, color: Colors.white);
    }

    return Container(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () => _shareToplatform(platform, activityRecord),
        style: ElevatedButton.styleFrom(
          backgroundColor: platform['color'],
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
          shadowColor: platform['color'].withOpacity(0.3),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(child: iconWidget),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Share on ${platform['name']}',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    'Reach your ${platform['name']} audience',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.white.withOpacity(0.8),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Colors.white.withOpacity(0.8),
            ),
          ],
        ),
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
    String? imageUrl = _platformIconImageUrls[platform['name']];
    Widget iconWidget;

    if (imageUrl != null) {
      iconWidget = Image.network(
        imageUrl,
        width: 20,
        height: 20,
        color: null,
      );
    } else {
      iconWidget = Icon(platform['icon'], size: 20, color: Colors.white);
    }

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
            child: iconWidget,
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
                  platform['connected'] ? 'Connected' : 'Not Connected',
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

  void _shareToplatform(Map<String, dynamic> platform, RecordModel activityRecord) async {
    Navigator.pop(context);

    final String title = activityRecord.getStringValue('title', 'No Title');
    final String orgName = activityRecord.expand['organization_id']?.first.getStringValue('name', 'Unknown Org') ?? 'Unknown Org';
    final int points = activityRecord.getIntValue('point_event', 0);
    final DateTime eventDate = DateFormat('yyyy-MM-dd').parse(activityRecord.getStringValue('date', DateTime.now().toIso8601String()));
    final String formattedDate = DateFormat('MMMM dd,EEEE').format(eventDate);
    final String description = activityRecord.getStringValue('description', 'It was a great experience contributing to our community!');

    final String genericShareText = '🌟 Just completed "$title" with $orgName on $formattedDate! I earned $points points for this event. ${description.isNotEmpty ? description : 'It was a great experience contributing to our community!'} 💪 #VolunteerVibe #MakeADifference #CommunityService';

    final String webLink = '${AppConstants.appWebDomain}/events/${activityRecord.id}';

    try {
      Uri? shareUri;

      if (platform['name'] == 'Facebook') {
        String facebookShareUrl = platform['share_url_template']
            .replaceAll('{link}', Uri.encodeComponent(webLink))
            .replaceAll('{text}', Uri.encodeComponent(genericShareText));
        shareUri = Uri.parse(facebookShareUrl);
      } else if (platform['name'] == 'Instagram') {
        await Share.share(genericShareText);
        _updateActivitySharedStatus(activityRecord, platform['name']);
        return;
      } else if (platform['name'] == 'WhatsApp') {
        final String encodedText = Uri.encodeComponent("$genericShareText\n\n$webLink");
        shareUri = Uri.parse("whatsapp://send?text=$encodedText");
      } else if (platform.containsKey('share_url_template')) {
        String urlTemplate = platform['share_url_template'];
        String shareUrl = urlTemplate
            .replaceAll('{link}', Uri.encodeComponent(webLink))
            .replaceAll('{text}', Uri.encodeComponent(genericShareText))
            .replaceAll('{title}', Uri.encodeComponent(title))
            .replaceAll('{description}', Uri.encodeComponent(description));
        shareUri = Uri.parse(shareUrl);
      } else {
        await Share.share(genericShareText);
        _updateActivitySharedStatus(activityRecord, platform['name']);
        return;
      }

      if (shareUri != null && await canLaunchUrl(shareUri)) {
        await launchUrl(shareUri, mode: LaunchMode.externalApplication);
        _updateActivitySharedStatus(activityRecord, platform['name']);
      } else {
        await Share.share(genericShareText);
        _updateActivitySharedStatus(activityRecord, platform['name']);
      }

      await _pbService.incrementUserSharedCount();
      if (mounted) {
        _loadSharingData();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to share to ${platform['name']}: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _updateActivitySharedStatus(RecordModel activityRecord, String platformName) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Shared to $platformName successfully!'),
        backgroundColor: Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
      ),
    );
    int index = _recentActivities.indexOf(activityRecord);
    if (index != -1) {
      RecordModel updatedRecord = RecordModel(
        collectionId: activityRecord.collectionId,
        collectionName: activityRecord.collectionName,
        id: activityRecord.id,
        created: activityRecord.created,
        updated: activityRecord.updated,
        data: Map<String, dynamic>.from(activityRecord.data)..['isShared'] = true,
        expand: activityRecord.expand,
      );
      setState(() {
        _recentActivities[index] = updatedRecord;
      });
    }
  }

  void _copyToClipboard(RecordModel activityRecord) {
    final String title = activityRecord.getStringValue('title', 'No Title');
    final String orgName = activityRecord.expand['organization_id']?.first.getStringValue('name', 'Unknown Org') ?? 'Unknown Org';
    final int points = activityRecord.getIntValue('point_event', 0);
    final DateTime eventDate = DateFormat('yyyy-MM-dd').parse(activityRecord.getStringValue('date', DateTime.now().toIso8601String()));
    final String formattedDate = DateFormat('MMMM dd,EEEE').format(eventDate);
    final String description = activityRecord.getStringValue('description', 'It was a great experience contributing to our community!');

    final String webLink = '${AppConstants.appWebDomain}/events/${activityRecord.id}';

    final textToCopy = '🌟 Just completed "$title" with $orgName on $formattedDate! I earned $points points for this event. ${description.isNotEmpty ? description : 'It was a great experience contributing to our community!'} 💪 #VolunteerVibe #MakeADifference #CommunityService\n\nLearn more: $webLink';

    Clipboard.setData(ClipboardData(text: textToCopy));
    Navigator.pop(context);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Link copied to clipboard!'),
        backgroundColor: Color(0xFF6C63FF),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  IconData _getCategoryIcon(String categoryName) {
    switch (categoryName) {
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

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_note_rounded, size: 60, color: Colors.grey.shade400),
            SizedBox(height: 16),
            Text(
              "No Activities Yet",
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFF4A5568),
              ),
            ),
            SizedBox(height: 8),
            Text(
              "You haven't participated in any events recently. Go out and make a difference!",
              style: TextStyle(color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}