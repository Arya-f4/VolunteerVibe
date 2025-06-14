import 'package:flutter/material.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:volunteervibe/services/pocketbase_service.dart';
import 'package:volunteervibe/screens/search_screen.dart';
import 'package:volunteervibe/screens/volunteer_hours_screen.dart';
import 'package:volunteervibe/screens/profile_screen.dart';

class GamificationScreen extends StatefulWidget {
  @override
  _GamificationScreenState createState() => _GamificationScreenState();
}

class _GamificationScreenState extends State<GamificationScreen> with TickerProviderStateMixin {
  final PocketBaseService _pbService = PocketBaseService();
  late AnimationController _progressController;
  
  // State Aplikasi
  bool _isLoading = true;
  RecordModel? _currentUser;
  int _eventsJoined = 0;
  List<RecordModel> _allAchievements = [];
  List<String> _earnedAchievementIds = [];
  
  int _bottomNavIndex = 2; // Index untuk tab 'Rewards/Achievements'

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(
      duration: Duration(milliseconds: 1500),
      vsync: this,
    );
    _loadGamificationData();
  }

  @override
  void dispose() {
    _progressController.dispose();
    super.dispose();
  }

  Future<void> _loadGamificationData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final userId = _pbService.getCurrentUser()?.id;
      if (userId == null) {
        if(mounted) setState(() => _isLoading = false);
        return;
      }

      final results = await Future.wait([
        _pbService.fetchCurrentUserWithAchievements(),
        _pbService.fetchAllAchievements(),
        _pbService.getEventsJoinedCount(userId),
      ]);

      if (mounted) {
        setState(() {
          _currentUser = results[0] as RecordModel?;
          _allAchievements = results[1] as List<RecordModel>;
          _eventsJoined = results[2] as int;

          if (_currentUser != null) {
            _earnedAchievementIds = _currentUser!.getListValue<String>('achievment_id');
          }
          _isLoading = false;
        });

        _animateProgress();
      }
    } catch (e) {
      print("Error loading gamification data: $e");
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _animateProgress() {
    if (_currentUser == null) return;
    final points = _currentUser!.getIntValue('points', 0);
    final levelData = _calculateLevel(points);
    final levelBasePoints = levelData['levelBasePoints']!;
    final nextLevelPoints = levelData['nextLevelPoints']!;
    
    final progress = (nextLevelPoints > levelBasePoints)
        ? (points - levelBasePoints) / (nextLevelPoints - levelBasePoints)
        : 0.0;

    final progressAnimation = Tween<double>(begin: 0.0, end: progress.clamp(0.0, 1.0))
        .animate(CurvedAnimation(parent: _progressController, curve: Curves.easeInOut));
    
    _progressController.reset();
    _progressController.forward();
    
    _progressController.addListener(() => setState(() {}));
  }

  Map<String, int> _calculateLevel(int points) {
    if (points < 200) return {"level": 1, "levelBasePoints": 0, "nextLevelPoints": 200};
    
    int level = (points / 100).floor();
    if (points >= 200 && points < 300) level = 2;
    if (points >= 300 && points < 400) level = 3;

    int nextLevelPoints = (level * 100) + 100;
    int levelBasePoints = (level - 1) * 100;

    return {"level": level, "levelBasePoints": levelBasePoints, "nextLevelPoints": nextLevelPoints};
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text('Achievements', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2D3748))),
        backgroundColor: Colors.white,
        elevation: 1,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: Color(0xFF2D3748)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: RefreshIndicator(
        onRefresh: _loadGamificationData,
        color: Color(0xFF6C63FF),
        child: _isLoading
            ? Center(child: CircularProgressIndicator(color: Color(0xFF6C63FF)))
            : CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Column(
                      children: [
                        SizedBox(height: 24),
                        _buildLevelProgress(),
                        SizedBox(height: 24),
                        _buildBadgesSection(),
                        SizedBox(height: 24),
                      ],
                    ),
                  )
                ],
              ),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildLevelProgress() {
    final points = _currentUser?.getIntValue('points', 0) ?? 0;
    final levelData = _calculateLevel(points);
    final currentLevel = levelData['level']!;
    final levelBasePoints = levelData['levelBasePoints']!;
    final nextLevelPoints = levelData['nextLevelPoints']!;
    
    final progress = (nextLevelPoints > levelBasePoints)
      ? (points - levelBasePoints) / (nextLevelPoints - levelBasePoints)
      : 0.0;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 24),
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [Color(0xFF6C63FF), Color(0xFF9F7AEA)]),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Color(0xFF6C63FF).withOpacity(0.3), blurRadius: 20, offset: Offset(0, 10))],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 60, height: 60,
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(30)),
                child: Center(child: Text('$currentLevel', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white))),
              ),
              SizedBox(width: 16),
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Level $currentLevel Volunteer', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                  Text('$points / $nextLevelPoints points', style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.9))),
                ],
              )),
            ],
          ),
          SizedBox(height: 20),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: _progressController.value * progress.clamp(0.0, 1.0),
              backgroundColor: Colors.white.withOpacity(0.3),
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              minHeight: 8,
            ),
          ),
          SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Level $currentLevel', style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 12)),
              Text('${nextLevelPoints - points} points to Level ${currentLevel + 1}', style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBadgesSection() {
    final earnedBadges = _allAchievements.where((a) => _earnedAchievementIds.contains(a.id)).toList();
    final inProgressBadges = _allAchievements.where((a) => !_earnedAchievementIds.contains(a.id)).toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (earnedBadges.isNotEmpty) ...[
            Text('Earned Badges (${earnedBadges.length})', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2D3748))),
            SizedBox(height: 16),
            GridView.builder(
              shrinkWrap: true, physics: NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, crossAxisSpacing: 16, mainAxisSpacing: 16, childAspectRatio: 0.9),
              itemCount: earnedBadges.length,
              itemBuilder: (context, index) => _buildBadgeCard(earnedBadges[index]),
            ),
            SizedBox(height: 32),
          ],
          if (inProgressBadges.isNotEmpty) ...[
            Text('In Progress (${inProgressBadges.length})', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2D3748))),
            SizedBox(height: 16),
            GridView.builder(
              shrinkWrap: true, physics: NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 3, crossAxisSpacing: 16, mainAxisSpacing: 16, childAspectRatio: 0.9),
              itemCount: inProgressBadges.length,
              itemBuilder: (context, index) => _buildBadgeCard(inProgressBadges[index]),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBadgeCard(RecordModel achievement) {
    final bool isEarned = _earnedAchievementIds.contains(achievement.id);
    final String title = achievement.getStringValue('badge_name');
    final String iconUrl = _pbService.getFileUrl(achievement, achievement.getStringValue('icon')) ?? '';
    final int requiredCount = achievement.getIntValue('count_event');

    return Opacity(
      opacity: isEarned ? 1.0 : 0.7,
      child: Container(
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isEarned ? Color(0xFF6C63FF).withOpacity(0.2) : Colors.grey.shade200),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: Offset(0, 4))],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.network(iconUrl, height: 50, width: 50, errorBuilder: (c, e, s) => Icon(Icons.shield, size: 40, color: Colors.grey)),
            SizedBox(height: 8),
            Text(title, style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF2D3748)), textAlign: TextAlign.center, maxLines: 2),
            if (!isEarned) ...[
              SizedBox(height: 4),
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: (requiredCount > 0) ? _eventsJoined / requiredCount : 0, 
                  backgroundColor: Color(0xFFE2E8F0), 
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6C63FF))
                ),
              ),
              SizedBox(height: 2),
              Text('$_eventsJoined/$requiredCount Events', style: TextStyle(fontSize: 10, color: Color(0xFF718096))),
            ]
          ],
        ),
      ),
    );
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
            case 2: break; // Already here
            case 3: Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => VolunteerHoursScreen())); break;
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