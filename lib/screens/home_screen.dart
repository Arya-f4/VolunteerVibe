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

class _HomeScreenState extends State<HomeScreen> {
  // Service
  final PocketBaseService _pbService = PocketBaseService();

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
    _loadInitialData();
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);
    
    await _loadUserData(); 
    await _fetchJoinedEvents();
    
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _loadUserData() async {
    final userRecord = _pbService.getCurrentUser();
    if (userRecord != null) {
      _userName = userRecord.getStringValue('name', 'Guest');
      _userPoints = userRecord.getIntValue('points', 0);
      final avatarFilename = userRecord.getStringValue('avatar');
      _userAvatarUrl = _pbService.getFileUrl(userRecord, avatarFilename);
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
        child: _bottomNavIndex == 0 ? _buildHomeContent() : _buildProfileContent(),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  Widget _buildHomeContent() {
    return RefreshIndicator(
      onRefresh: _loadInitialData,
      child: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.fromLTRB(24, 24, 24, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(),
                  SizedBox(height: 24),
                  _buildStatsCards(),
                  SizedBox(height: 24),
                  _buildQuickAccessButtons(),
                  SizedBox(height: 24),
                  Text('My Event History', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                  SizedBox(height: 16),
                ],
              ),
            ),
          ),
          _isLoading
              ? SliverToBoxAdapter(child: Center(child: Padding(padding: const EdgeInsets.all(32.0), child: CircularProgressIndicator())))
              : _events.isEmpty
                  ? SliverToBoxAdapter(
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.all(48.0),
                          child: Text("You haven't joined any events yet.", style: TextStyle(color: Colors.grey[600], fontSize: 16)),
                        ),
                      ),
                    )
                  : SliverList(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) => Padding(
                          padding: EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
                          child: _buildEventCard(_events[index]),
                        ),
                        childCount: _events.length,
                      ),
                    ),
          SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }
  
  Widget _buildHeader() {
    return Row(
      children: [
        CircleAvatar(
          radius: 28,
          backgroundColor: Colors.grey[200],
          backgroundImage: _userAvatarUrl != null ? NetworkImage(_userAvatarUrl!) : null,
          child: _userAvatarUrl == null ? Icon(Icons.person, size: 28, color: Colors.grey[400]) : null,
        ),
        SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Good morning,', style: TextStyle(color: Colors.grey[600], fontSize: 14)),
            SizedBox(height: 4),
            Text(_userName, style: TextStyle(color: Color(0xFF1E293B), fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        Spacer(),
        IconButton(
          icon: Icon(Icons.notifications_outlined, color: Color(0xFF4A5568), size: 28),
          onPressed: () {},
        ),
      ],
    );
  }

  Widget _buildStatsCards() {
    return Row(
      children: [
        Expanded(child: _buildStatCard('Total Points', _userPoints.toString(), Icons.star, Colors.orange)),
        SizedBox(width: 16),
        Expanded(child: _buildStatCard('Events Joined', _eventsJoined.toString(), Icons.event_available, Color(0xFF6C63FF))),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: Offset(0, 4))]),
      child: Column(
        children: [
          Container(width: 40, height: 40, decoration: BoxDecoration(color: color.withOpacity(0.1), shape: BoxShape.circle), child: Icon(icon, color: color, size: 20)),
          SizedBox(height: 8),
          _isLoading ? Padding(padding: const EdgeInsets.symmetric(vertical: 4.0), child: SizedBox(height: 14, width: 14, child: CircularProgressIndicator(strokeWidth: 2, color: color))) : Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF2D3748))),
          Text(title, style: TextStyle(fontSize: 12, color: Color(0xFF718096)), textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _buildQuickAccessButtons() {
    return Row(
      children: [
        Expanded(child: _buildQuickAccessButton('Search Events', Icons.search, Color(0xFF6C63FF), () => Navigator.push(context, MaterialPageRoute(builder: (context) => SearchScreen())))),
        SizedBox(width: 12),
        Expanded(child: _buildQuickAccessButton('My Hours', Icons.access_time_filled_outlined, Color(0xFF10B981), () => Navigator.push(context, MaterialPageRoute(builder: (context) => VolunteerHoursScreen())))),
        SizedBox(width: 12),
        Expanded(child: _buildQuickAccessButton('Share Impact', Icons.share, Colors.red, () => Navigator.push(context, MaterialPageRoute(builder: (context) => SocialSharingScreen())))),
      ],
    );
  }

  Widget _buildQuickAccessButton(String title, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 16, horizontal: 8),
        decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: color.withOpacity(0.3))),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 24),
            SizedBox(height: 8),
            Text(title, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _buildEventCard(RecordModel event) {
    final organization = event.expand['organization_id']?.first;
    final String title = event.getStringValue('title', 'No Title');
    final String orgName = organization?.getStringValue('name') ?? 'Unknown Org';
    final DateTime eventDate = DateTime.parse(event.getStringValue('date'));
    
    String? orgAvatarUrl;
    if (organization != null) {
      final orgAvatarFilename = organization.getStringValue('avatar');
      orgAvatarUrl = _pbService.getFileUrl(organization, orgAvatarFilename);
    }

    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => EventDetailScreen(event: event))),
      child: Container(
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.grey.shade200)),
        child: Row(
          children: [
            CircleAvatar(
              radius: 25,
              backgroundColor: Colors.grey.shade200,
              backgroundImage: orgAvatarUrl != null ? NetworkImage(orgAvatarUrl) : null,
              child: orgAvatarUrl == null ? Icon(Icons.business_rounded, color: Colors.grey.shade400) : null,
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF2D3748))),
                  SizedBox(height: 4),
                  Text(orgName, style: TextStyle(color: Colors.grey[600])),
                ],
              ),
            ),
            SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(DateFormat('MMM').format(eventDate).toUpperCase(), style: TextStyle(color: Color(0xFF6C63FF), fontWeight: FontWeight.bold, fontSize: 12)),
                Text(DateFormat('dd').format(eventDate), style: TextStyle(color: Color(0xFF1E293B), fontWeight: FontWeight.bold, fontSize: 20)),
              ],
            )
          ],
        ),
      ),
    );
  }

  Widget _buildProfileContent() {
    return Center(child: Text("Profile Page Content"));
  }

  Widget _buildBottomNavigationBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white, 
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: Offset(0, -5))]
      ),
      child: BottomNavigationBar(
        // Current index di halaman home akan selalu 0
        currentIndex: 0, 
        onTap: (index) {
          // Jika menekan tombol yang aktif (Home), jangan lakukan apa-apa
          if (index == 0) {
            return;
          }

          // Untuk tombol lain, lakukan navigasi push
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
            case 4: 
              Navigator.push(context, MaterialPageRoute(builder: (context) => ProfileScreen()));
              break;
            // -------------------------
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