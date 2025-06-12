import 'package:flutter/material.dart';
import 'dart:async';
import 'package:intl/intl.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:volunteervibe/services/pocketbase_service.dart';
import 'profile_screen.dart';
import 'event_detail_screen.dart';
import 'search_screen.dart';
import 'gamification_screen.dart';
import 'social_sharing_screen.dart';
import 'volunteer_hours_screen.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  // Service
  final PocketBaseService _pbService = PocketBaseService();

  // Animation Controllers
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // UI State
  int _bottomNavIndex = 0;
  bool _isLoading = true;

  // Data State
  String _userName = 'Guest';
  String? _userAvatarUrl;
  int _userPoints = 0;
  int _eventsJoined = 0;
  List<RecordModel> _events = [];

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadInitialData();
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(
      duration: Duration(milliseconds: 800),
      vsync: this,
    );
    _slideController = AnimationController(
      duration: Duration(milliseconds: 600),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut),
    );

    _slideAnimation = Tween<Offset>(
      begin: Offset(0, 0.3),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic));
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);

    await _loadUserData();
    await _fetchJoinedEvents();

    if (mounted) {
      setState(() => _isLoading = false);
      _fadeController.forward();
      _slideController.forward();
    }
  }

  Future<void> _loadUserData() async {
    final userRecord = _pbService.getCurrentUser();
    if (userRecord != null) {
      _userName = userRecord.data['name'] ?? 'Guest';
      _userPoints = userRecord.data['points'] ?? 0;
      final avatarFilename = userRecord.data['avatar'];
      if (avatarFilename != null && avatarFilename.isNotEmpty) {
        _userAvatarUrl = _pbService.getFileUrl(userRecord, avatarFilename);
      }
      _eventsJoined = await _pbService.getEventsJoinedCount(userRecord.id);
    }
  }

  Future<void> _fetchJoinedEvents() async {
    final user = _pbService.getCurrentUser();
    if (user == null) {
      if (mounted) setState(() => _events = []);
      return;
    }

    if (!_isLoading) setState(() => _isLoading = true);

    final joinedEventsResult = await _pbService.fetchJoinedEvents(userId: user.id);
    if (mounted) {
      setState(() {
        _events = joinedEventsResult;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF8FAFC),
      body: SafeArea(
        // Berganti konten berdasarkan _bottomNavIndex
        child: _bottomNavIndex == 4 ? _buildProfileContent() : _buildHomeContent(),
      ),
      bottomNavigationBar: _buildFixedBottomNavigationBar(),
    );
  }

  Widget _buildHomeContent() {
    return RefreshIndicator(
      onRefresh: _loadInitialData,
      color: Color(0xFF6366F1),
      backgroundColor: Colors.white,
      child: CustomScrollView(
        physics: BouncingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: SlideTransition(
                position: _slideAnimation,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFF6366F1),
                        Color(0xFF8B5CF6),
                      ],
                    ),
                  ),
                  child: Padding(
                    padding: EdgeInsets.fromLTRB(24, 32, 24, 32),
                    child: Column(
                      children: [
                        _buildModernHeader(),
                        SizedBox(height: 32),
                        _buildModernStatsCards(),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Transform.translate(
              offset: Offset(0, -20),
              child: Container(
                decoration: BoxDecoration(
                  color: Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(24),
                    topRight: Radius.circular(24),
                  ),
                ),
                child: Padding(
                  padding: EdgeInsets.fromLTRB(24, 32, 24, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildQuickAccessButtons(),
                      SizedBox(height: 32),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Recent Activities',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                          TextButton(
                            onPressed: () {},
                            child: Text(
                              'View All',
                              style: TextStyle(
                                color: Color(0xFF6366F1),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ),
          ),
          _isLoading
              ? SliverToBoxAdapter(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(48.0),
                      child: Column(
                        children: [
                          CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6366F1)),
                            strokeWidth: 3,
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Loading your activities...',
                            style: TextStyle(
                              color: Color(0xFF64748B),
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              : _events.isEmpty
                  ? SliverToBoxAdapter(
                      child: _buildEmptyState(),
                    )
                  : SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) => Padding(
                          padding: EdgeInsets.symmetric(horizontal: 24.0, vertical: 6.0),
                          child: _buildModernEventCard(_events[index], index),
                        ),
                        childCount: _events.length,
                      ),
                    ),
          SliverToBoxAdapter(child: SizedBox(height: 100)),
        ],
      ),
    );
  }

  Widget _buildModernHeader() {
    return Row(
      children: [
        Container(
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withOpacity(0.3), width: 3),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: CircleAvatar(
            radius: 32,
            backgroundColor: Colors.white,
            backgroundImage: _userAvatarUrl != null ? NetworkImage(_userAvatarUrl!) : null,
            child: _userAvatarUrl == null
                ? Icon(Icons.person, size: 32, color: Color(0xFF6366F1))
                : null,
          ),
        ),
        SizedBox(width: 20),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Welcome back,',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 4),
              Text(
                _userName,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(16),
          ),
          child: IconButton(
            icon: Icon(Icons.notifications_outlined, color: Colors.white, size: 24),
            onPressed: () {},
          ),
        ),
      ],
    );
  }

  Widget _buildModernStatsCards() {
    return Row(
      children: [
        Expanded(
          child: _buildModernStatCard(
            'Total Points',
            _userPoints.toString(),
            Icons.star_rounded,
            Color(0xFFFBBF24),
            Color(0xFFFEF3C7),
          ),
        ),
        SizedBox(width: 16),
        Expanded(
          child: _buildModernStatCard(
            'Events Joined',
            _eventsJoined.toString(),
            Icons.event_available_rounded,
            Color(0xFF10B981),
            Color(0xFFD1FAE5),
          ),
        ),
      ],
    );
  }

  Widget _buildModernStatCard(String title, String value, IconData icon, Color iconColor, Color bgColor) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          SizedBox(height: 12),
          _isLoading
              ? Container(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(iconColor),
                  ),
                )
              : Text(
                  value,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
          SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 13,
              color: Color(0xFF64748B),
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAccessButtons() {
    final buttons = [
      {'title': 'Search Events', 'icon': Icons.search_rounded, 'color': Color(0xFF6366F1), 'action': () => Navigator.push(context, MaterialPageRoute(builder: (context) => SearchScreen()))},
      {'title': 'My Hours', 'icon': Icons.schedule_rounded, 'color': Color(0xFF10B981), 'action': () => Navigator.push(context, MaterialPageRoute(builder: (context) => VolunteerHoursScreen()))},
      {'title': 'Share Impact', 'icon': Icons.share_rounded, 'color': Color(0xFFEF4444), 'action': () => Navigator.push(context, MaterialPageRoute(builder: (context) => SocialSharingScreen()))},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Color(0xFF1E293B),
          ),
        ),
        SizedBox(height: 16),
        Row(
          children: buttons.map((button) =>
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(right: buttons.indexOf(button) < buttons.length - 1 ? 12 : 0),
                child: _buildModernQuickAccessButton(
                  button['title'] as String,
                  button['icon'] as IconData,
                  button['color'] as Color,
                  button['action'] as VoidCallback,
                ),
              ),
            ),
          ).toList(),
        ),
      ],
    );
  }

  Widget _buildModernQuickAccessButton(String title, IconData icon, Color color, VoidCallback onTap) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withOpacity(0.2)),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.1),
                blurRadius: 10,
                offset: Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              SizedBox(height: 12),
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF374151),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildModernEventCard(RecordModel event, int index) {
    final organization = event.expand['organization_id']?.first;
    final String title = event.data['title'] ?? 'No Title';
    final String orgName = organization?.data['name'] ?? 'Unknown Org';
    final DateTime eventDate = DateTime.parse(event.data['date']);

    String? orgAvatarUrl;
    if (organization != null) {
      final orgAvatarFilename = organization.data['avatar'];
       if (orgAvatarFilename != null && orgAvatarFilename.isNotEmpty) {
          orgAvatarUrl = _pbService.getFileUrl(organization, orgAvatarFilename);
       }
    }

    return TweenAnimationBuilder<double>(
      duration: Duration(milliseconds: 300 + (index * 100)),
      tween: Tween(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: child,
          ),
        );
      },
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => EventDetailScreen(event: event)),
          ),
          borderRadius: BorderRadius.circular(20),
          child: Container(
            margin: EdgeInsets.only(bottom: 12),
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 15,
                  offset: Offset(0, 5),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Color(0xFF6366F1).withOpacity(0.2),
                        blurRadius: 8,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: CircleAvatar(
                    radius: 28,
                    backgroundColor: Color(0xFFF1F5F9),
                    backgroundImage: orgAvatarUrl != null ? NetworkImage(orgAvatarUrl) : null,
                    child: orgAvatarUrl == null
                        ? Icon(Icons.business_rounded, color: Color(0xFF6366F1), size: 24)
                        : null,
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: Color(0xFF1E293B),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(Icons.business_rounded, size: 14, color: Color(0xFF64748B)),
                          SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              orgName,
                              style: TextStyle(
                                color: Color(0xFF64748B),
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                SizedBox(width: 16),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Color(0xFF6366F1).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      Text(
                        DateFormat('MMM').format(eventDate).toUpperCase(),
                        style: TextStyle(
                          color: Color(0xFF6366F1),
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                      Text(
                        DateFormat('dd').format(eventDate),
                        style: TextStyle(
                          color: Color(0xFF1E293B),
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: EdgeInsets.all(48),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Color(0xFF6366F1).withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              Icons.event_available_rounded,
              size: 40,
              color: Color(0xFF6366F1),
            ),
          ),
          SizedBox(height: 24),
          Text(
            'No Events Yet',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1E293B),
            ),
          ),
          SizedBox(height: 8),
          Text(
            "You haven't joined any events yet.\nStart exploring and make an impact!",
            style: TextStyle(
              color: Color(0xFF64748B),
              fontSize: 16,
              height: 1.5,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => SearchScreen()),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF6366F1),
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 0,
            ),
            child: Text(
              'Explore Events',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileContent() {
    // Navigasi ke ProfileScreen yang sebenarnya
    return ProfileScreen();
  }

  //-- KODE YANG DIPERBAIKI ADA DI BAWAH INI --//

  Widget _buildFixedBottomNavigationBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05), // Sedikit mengurangi bayangan
            blurRadius: 20,
            offset: Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          // Menyesuaikan padding agar lebih seimbang dan tidak memakan banyak ruang vertikal
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround, // Memberi ruang yang lebih baik
            children: [
              // Perhatikan bagaimana status 'isActive' sekarang dinamis
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
    // Menentukan apakah item ini sedang aktif berdasarkan state _bottomNavIndex
    final bool isActive = _bottomNavIndex == index;
  
    return Flexible(
      child: GestureDetector(
        onTap: () {
          // Logika navigasi utama
          // Jika Anda ingin mengganti konten body di HomeScreen, gunakan setState.
          // Jika Anda ingin membuka halaman baru di atasnya, gunakan Navigator.push.
  
          if (index == 0 || index == 4) { // Jika tab Home atau Profile ditekan
            setState(() {
              _bottomNavIndex = index;
            });
            return; // Hentikan eksekusi agar tidak menjalankan Navigator.push
          }
          
          // Logika navigasi yang sudah ada untuk halaman lain
          if (_bottomNavIndex == index) return; // Jangan lakukan apa pun jika tab yang sama ditekan
  
          switch (index) {
            case 1:
              Navigator.push(context, MaterialPageRoute(builder: (context) => SearchScreen()));
              break;
            case 2:
              Navigator.push(context, MaterialPageRoute(builder: (context) => GamificationScreen()));
              break;
            case 3:
              Navigator.push(context, MaterialPageRoute(builder: (context) => VolunteerHoursScreen()));
              break;
          }
        },
        child: Container(
          // Memberi sedikit padding agar lebih mudah ditekan
          padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
          decoration: BoxDecoration(
            color: isActive ? Color(0xFF6366F1).withOpacity(0.1) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min, // Penting agar column tidak memakan banyak ruang
            children: [
              Icon(
                icon,
                color: isActive ? Color(0xFF6366F1) : Color(0xFF9CA3AF),
                size: 24, // Sedikit memperbesar ikon agar seimbang
              ),
              SizedBox(height: 4), // Memberi sedikit jarak
              Text(
                label,
                style: TextStyle(
                  color: isActive ? Color(0xFF6366F1) : Color(0xFF9CA3AF),
                  fontSize: 11, // Sedikit memperbesar font agar mudah dibaca
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