import 'package:flutter/material.dart';
import 'package:volunteervibe/screens/search_screen.dart';
import 'package:volunteervibe/screens/volunteer_hours_screen.dart';
import 'package:volunteervibe/screens/profile_screen.dart';

// Enum untuk melacak view yang sedang aktif, lebih rapi daripada integer.
enum GamificationView { badges, rewards }

class GamificationScreen extends StatefulWidget {
  @override
  _GamificationScreenState createState() => _GamificationScreenState();
}

class _GamificationScreenState extends State<GamificationScreen>
    with TickerProviderStateMixin {
  late AnimationController _progressController;
  late Animation<double> _progressAnimation;

  // --- State Aplikasi ---
  int _currentPoints = 1250;
  final int _nextLevelPoints = 1500;
  final int _currentLevel = 5;

  late List<Map<String, dynamic>> _rewards;
  bool _showAvailableRewardsOnly = true;
  
  // State baru untuk menggantikan TabController, default-nya menampilkan Badges
  GamificationView _selectedView = GamificationView.badges;
  
  // --- State untuk Bottom Bar ---
  int _bottomNavIndex = 2; // 2 adalah index untuk "Rewards"

  // --- Data Dummy ---
  final List<Map<String, dynamic>> _badges = [
    {
      'title': 'First Timer',
      'description': 'Complete your first volunteer event',
      'icon': Icons.star,
      'color': Color(0xFFFFD700),
      'earned': true,
      'earnedDate': 'Nov 15, 2024',
      'rarity': 'Common',
    },
    {
      'title': 'Community Helper',
      'description': 'Complete 5 volunteer events',
      'icon': Icons.people,
      'color': Color(0xFF6C63FF),
      'earned': true,
      'earnedDate': 'Nov 28, 2024',
      'rarity': 'Uncommon',
    },
    {
      'title': 'Environmental Warrior',
      'description': 'Complete 3 environmental events',
      'icon': Icons.eco,
      'color': Color(0xFF10B981),
      'earned': false,
      'progress': 2,
      'target': 3,
      'rarity': 'Rare',
    },
    {
      'title': 'Time Master',
      'description': 'Log 50+ volunteer hours',
      'icon': Icons.access_time,
      'color': Color(0xFFED8936),
      'earned': true,
      'earnedDate': 'Dec 5, 2024',
      'rarity': 'Epic',
    },
    {
      'title': 'Social Butterfly',
      'description': 'Share 10 volunteer activities',
      'icon': Icons.share,
      'color': Color(0xFFE53E3E),
      'earned': false,
      'progress': 7,
      'target': 10,
      'rarity': 'Rare',
    },
    {
      'title': 'Streak Master',
      'description': 'Volunteer for 7 consecutive weeks',
      'icon': Icons.local_fire_department,
      'color': Color(0xFFFF6B35),
      'earned': false,
      'progress': 4,
      'target': 7,
      'rarity': 'Legendary',
    },
  ];

  @override
  void initState() {
    super.initState();
    _rewards = [
      {
        'title': 'Coffee Shop Voucher',
        'description': '₹200 off at partner cafes',
        'points': 500,
        'icon': Icons.local_cafe,
        'color': Color(0xFF8B4513),
        'available': true,
      },
      {
        'title': 'Movie Ticket',
        'description': 'Free movie ticket at partner theaters',
        'points': 800,
        'icon': Icons.movie,
        'color': Color(0xFF6C63FF),
        'available': true,
      },
      {
        'title': 'Eco-Friendly Tote Bag',
        'description': 'Sustainable tote bag with VolunteerVibe logo',
        'points': 1000,
        'icon': Icons.shopping_bag,
        'color': Color(0xFF10B981),
        'available': true,
      },
      {
        'title': 'Volunteer T-Shirt',
        'description': 'Official VolunteerVibe volunteer t-shirt',
        'points': 1200,
        'icon': Icons.checkroom,
        'color': Color(0xFFED8936),
        'available': true,
      },
      {
        'title': 'Dinner Voucher',
        'description': '₹1000 voucher at partner restaurants',
        'points': 1500,
        'icon': Icons.restaurant,
        'color': Color(0xFFE53E3E),
        'available': true,
      },
    ];

    _progressController = AnimationController(
      duration: Duration(milliseconds: 1500),
      vsync: this,
    );
    _progressAnimation = Tween<double>(
      begin: 0.0,
      end: _currentPoints / _nextLevelPoints,
    ).animate(CurvedAnimation(
      parent: _progressController,
      curve: Curves.easeInOut,
    ));
    _progressController.forward();
  }

  @override
  void dispose() {
    _progressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        // Tombol kembali ini penting jika halaman ini dibuka dari halaman lain
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: Color(0xFF2D3748)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Rewards & Achievements',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Color(0xFF2D3748),
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false, // Kita handle tombol kembali secara manual
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            SizedBox(height: 16), // Memberi sedikit jarak dari app bar
            _buildLevelProgress(),
            SizedBox(height: 24),
            _buildSegmentedControl(),
            SizedBox(height: 24),
            // Menampilkan konten berdasarkan state _selectedView
            if (_selectedView == GamificationView.badges)
              _buildBadgesTab()
            else
              _buildRewardsTab(),
            SizedBox(height: 24), // Memberi ruang di bawah konten
          ],
        ),
      ),
      // --- BOTTOM NAVIGATION BAR DITAMBAHKAN DI SINI ---
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }
  
  // --- START: KODE BOTTOM BAR YANG BARU DITAMBAHKAN ---

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
          if (index == _bottomNavIndex) return; // Jangan lakukan apa-apa jika tab yang sama ditekan

          switch (index) {
            case 0:
              // Kembali ke halaman paling awal (HomeScreen)
              Navigator.popUntil(context, (route) => route.isFirst);
              break;
            case 1:
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => SearchScreen()));
              break;
            case 2:
              // Sudah di halaman ini
              break;
            case 3:
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => VolunteerHoursScreen()));
              break;
            case 4:
              // Ganti dengan halaman Profile Anda
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => ProfileScreen()));
              break;
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

  // --- END: KODE BOTTOM BAR YANG BARU DITAMBAHKAN ---

  Widget _buildSegmentedControl() {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(4),
      margin: EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: Color(0xFFEDF2F7), // Sedikit lebih abu-abu
        borderRadius: BorderRadius.circular(12),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return ToggleButtons(
            isSelected: [
              _selectedView == GamificationView.badges,
              _selectedView == GamificationView.rewards,
            ],
            onPressed: (index) {
              setState(() {
                _selectedView = index == 0 ? GamificationView.badges : GamificationView.rewards;
              });
            },
            color: Color(0xFF4A5568),
            selectedColor: Colors.white,
            fillColor: Color(0xFF6C63FF),
            splashColor: Color(0xFF6C63FF).withOpacity(0.12),
            hoverColor: Color(0xFF6C63FF).withOpacity(0.04),
            borderRadius: BorderRadius.circular(10.0),
            borderWidth: 0,
            renderBorder: false,
            constraints: BoxConstraints.expand(width: (constraints.maxWidth / 2) - 2, height: 40),
            children: <Widget>[
              Text('Badges', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
              Text('Rewards', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
            ],
          );
        },
      ),
    );
  }

  Widget _buildLevelProgress() {
    return Container(
      margin: EdgeInsets.fromLTRB(24, 0, 24, 0),
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
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Center(
                  child: Text(
                    '$_currentLevel',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Level $_currentLevel Volunteer', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.white)),
                    Text('$_currentPoints / $_nextLevelPoints points', style: TextStyle(fontSize: 14, color: Colors.white.withOpacity(0.9))),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 20),
          AnimatedBuilder(
            animation: _progressAnimation,
            builder: (context, child) {
              return Column(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: _progressAnimation.value,
                      backgroundColor: Colors.white.withOpacity(0.3),
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      minHeight: 8,
                    ),
                  ),
                  SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Level $_currentLevel', style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 12)),
                      Text('${_nextLevelPoints - _currentPoints} points to Level ${_currentLevel + 1}', style: TextStyle(color: Colors.white.withOpacity(0.9), fontSize: 12)),
                    ],
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildBadgesTab() {
    final earnedBadges = _badges.where((badge) => badge['earned'] == true).toList();
    final inProgressBadges = _badges.where((badge) => badge['earned'] == false).toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (earnedBadges.isNotEmpty) ...[
            Text('Earned Badges (${earnedBadges.length})', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2D3748))),
            SizedBox(height: 16),
            GridView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 0.8,
              ),
              itemCount: earnedBadges.length,
              itemBuilder: (context, index) => _buildBadgeCard(earnedBadges[index], true),
            ),
            SizedBox(height: 32),
          ],
          if (inProgressBadges.isNotEmpty) ...[
            Text('In Progress (${inProgressBadges.length})', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2D3748))),
            SizedBox(height: 16),
            GridView.builder(
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 0.8,
              ),
              itemCount: inProgressBadges.length,
              itemBuilder: (context, index) => _buildBadgeCard(inProgressBadges[index], false),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBadgeCard(Map<String, dynamic> badge, bool isEarned) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: isEarned ? badge['color'].withOpacity(0.3) : Color(0xFFE2E8F0), width: 2),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: Offset(0, 4))],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: isEarned ? badge['color'] : Color(0xFFE2E8F0),
              borderRadius: BorderRadius.circular(30),
              boxShadow: isEarned ? [BoxShadow(color: badge['color'].withOpacity(0.3), blurRadius: 10, offset: Offset(0, 4))] : null,
            ),
            child: Icon(badge['icon'], color: isEarned ? Colors.white : Color(0xFF718096), size: 30),
          ),
          Column(
            children: [
              Text(badge['title'], style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: isEarned ? Color(0xFF2D3748) : Color(0xFF718096)), textAlign: TextAlign.center),
              SizedBox(height: 4),
              Text(badge['description'], style: TextStyle(fontSize: 11, color: Color(0xFF718096)), textAlign: TextAlign.center, maxLines: 2, overflow: TextOverflow.ellipsis),
            ],
          ),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(color: _getRarityColor(badge['rarity']).withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
            child: Text(badge['rarity'], style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: _getRarityColor(badge['rarity']))),
          ),
          if (!isEarned && badge.containsKey('progress')) ...[
            Column(
              children: [
                SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(value: badge['progress'] / badge['target'], backgroundColor: Color(0xFFE2E8F0), valueColor: AlwaysStoppedAnimation<Color>(badge['color'])),
                ),
                SizedBox(height: 4),
                Text('${badge['progress']}/${badge['target']}', style: TextStyle(fontSize: 10, color: Color(0xFF718096))),
              ],
            )
          ],
          if (isEarned) ...[
            SizedBox(height: 4),
            Text('Earned ${badge['earnedDate']}', style: TextStyle(fontSize: 10, color: Color(0xFF10B981), fontWeight: FontWeight.w500)),
          ],
        ],
      ),
    );
  }

  Widget _buildRewardsTab() {
    final filteredRewards = _showAvailableRewardsOnly ? _rewards.where((r) => r['available'] == true).toList() : _rewards;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24.0),
      child: Column(
        children: [
          _buildFilterSwitch(),
          ListView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            itemCount: filteredRewards.length,
            itemBuilder: (context, index) {
              final reward = filteredRewards[index];
              return _buildRewardCard(reward);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFilterSwitch() {
    return Container(
      margin: const EdgeInsets.only(bottom: 24.0),
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: Color(0xFFF7FAFC),
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: Color(0xFFE2E8F0)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('Hanya tampilkan yang tersedia', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Color(0xFF4A5568))),
          Switch(
            value: _showAvailableRewardsOnly,
            onChanged: (value) {
              setState(() {
                _showAvailableRewardsOnly = value;
              });
            },
            activeColor: Color(0xFF6C63FF),
            materialTapTargetSize: MaterialTapTargetSize.padded,
          ),
        ],
      ),
    );
  }

  Widget _buildRewardCard(Map<String, dynamic> reward) {
    final bool canRedeem = _currentPoints >= reward['points'] && reward['available'];

    return Container(
      margin: EdgeInsets.only(bottom: 16),
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: canRedeem ? reward['color'].withOpacity(0.3) : Color(0xFFE2E8F0)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: Offset(0, 4))],
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: reward['color'].withOpacity(canRedeem || !reward['available'] ? 1.0 : 0.3),
              borderRadius: BorderRadius.circular(30),
            ),
            child: Icon(reward['icon'], color: Colors.white, size: 30),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(reward['title'], style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: canRedeem || !reward['available'] ? Color(0xFF2D3748) : Color(0xFF718096))),
                SizedBox(height: 4),
                Text(reward['description'], style: TextStyle(fontSize: 14, color: Color(0xFF718096))),
                SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.star, color: Color(0xFFFFD700), size: 16),
                    SizedBox(width: 4),
                    Text('${reward['points']} points', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF6C63FF))),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(width: 16),
          ElevatedButton(
            onPressed: canRedeem ? () => _showRedeemDialog(reward) : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: canRedeem ? Color(0xFF6C63FF) : Color(0xFFE2E8F0),
              foregroundColor: canRedeem ? Colors.white : Color(0xFF718096),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
            child: Text(reward['available'] ? (canRedeem ? 'Redeem' : 'Locked') : 'Redeemed', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Color _getRarityColor(String rarity) {
    switch (rarity) {
      case 'Common': return Color(0xFF718096);
      case 'Uncommon': return Color(0xFF10B981);
      case 'Rare': return Color(0xFF6C63FF);
      case 'Epic': return Color(0xFFED8936);
      case 'Legendary': return Color(0xFFE53E3E);
      default: return Color(0xFF718096);
    }
  }

  void _showRedeemDialog(Map<String, dynamic> reward) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Redeem Reward'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80, height: 80,
              decoration: BoxDecoration(color: reward['color'], borderRadius: BorderRadius.circular(40)),
              child: Icon(reward['icon'], color: Colors.white, size: 40),
            ),
            SizedBox(height: 16),
            Text(reward['title'], style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text('Redeem for ${reward['points']} points?', style: TextStyle(color: Color(0xFF718096))),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text('Cancel')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              setState(() {
                _currentPoints -= reward['points'] as int;
                final index = _rewards.indexWhere((r) => r['title'] == reward['title']);
                if (index != -1) {
                  _rewards[index]['available'] = false;
                }
              });
              _showRedemptionSuccess(reward);
            },
            child: Text('Redeem'),
          ),
        ],
      ),
    );
  }

  void _showRedemptionSuccess(Map<String, dynamic> reward) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80, height: 80,
              decoration: BoxDecoration(color: Color(0xFF10B981), borderRadius: BorderRadius.circular(40)),
              child: Icon(Icons.check, color: Colors.white, size: 40),
            ),
            SizedBox(height: 16),
            Text('Reward Redeemed!', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text('Check your email for redemption details.', textAlign: TextAlign.center, style: TextStyle(color: Color(0xFF718096))),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(onPressed: () => Navigator.pop(context), child: Text('Great!')),
          ),
        ],
      ),
    );
  }
}