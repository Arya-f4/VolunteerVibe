import 'package:flutter/material.dart';
import 'dart:async';
import 'event_detail_screen.dart'; // Pastikan import ini ada
import 'search_screen.dart';
import 'gamification_screen.dart';
import 'social_sharing_screen.dart';
import 'volunteer_hours_screen.dart';

// Import yang diperlukan
import 'package:volunteervibe/pocketbase_client.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:intl/intl.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  // --- State untuk UI ---
  int _bottomNavIndex = 0;

  // --- State untuk Data Dinamis ---
  String _userName = 'Guest';
  String? _userAvatarUrl;
  int _userPoints = 0;
  int _eventsJoined = 0;
  bool _isLoading = true;

  List<RecordModel> _eventCategories = [];
  List<RecordModel> _events = [];
  String? _selectedCategoryId;

  // Controller dan Debouncer untuk search
  final _searchController = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);
    await _loadUserData();
    await _fetchCategories();
    await _fetchEvents();
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _loadUserData() async {
    final userRecord = pb.authStore.model;
    if (userRecord is RecordModel) {
      _userName = userRecord.getStringValue('name', 'Guest');
      _userPoints = userRecord.getIntValue('points', 0);
      final avatarFilename = userRecord.getStringValue('avatar');
      if (avatarFilename.isNotEmpty) {
        _userAvatarUrl = pb.getFileUrl(userRecord, avatarFilename).toString();
      }
      try {
        final eventsResult = await pb.collection('event').getList(
          perPage: 1,
          filter: "participant_id ?~ '${userRecord.id}'",
        );
        _eventsJoined = eventsResult.totalItems;
      } catch (e) {
        print('Error fetching joined events: $e');
        _eventsJoined = 0;
      }
    }
  }

  Future<void> _fetchCategories() async {
    try {
      final categoriesResult = await pb.collection('event_categories').getFullList(sort: 'name');
      if (mounted) setState(() => _eventCategories = categoriesResult);
    } catch (e) {
      print('Error fetching categories: $e');
    }
  }

  Future<void> _fetchEvents() async {
    if (mounted) setState(() => _isLoading = true);
    
    final searchQuery = _searchController.text.trim();
    
    List<String> filters = ["date >= @now"];
    if (_selectedCategoryId != null) {
      filters.add("categories_id = '$_selectedCategoryId'");
    }
    if (searchQuery.isNotEmpty) {
      filters.add("title ~ '$searchQuery'");
    }
    
    final filterString = filters.join(' && ');

    try {
      final eventsResult = await pb.collection('event').getFullList(
        sort: '+date',
        filter: filterString,
        expand: 'organization_id,categories_id',
      );
      if (mounted) setState(() => _events = eventsResult);
    } catch (e) {
      print('Error fetching events: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
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
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                SizedBox(height: 24),
                _buildStatsCards(),
                SizedBox(height: 24),
                _buildSearchBar(),
                SizedBox(height: 20),
                _buildQuickAccessButtons(),
                SizedBox(height: 20),
                _buildCategoryFilter(),
                SizedBox(height: 24),
                Text(
                  'Upcoming Events',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 16),
              ],
            ),
          ),
        ),
        _isLoading
            ? SliverToBoxAdapter(child: Center(child: Padding(padding: const EdgeInsets.all(32.0), child: CircularProgressIndicator())))
            : _events.isEmpty
                ? SliverToBoxAdapter(child: Center(child: Padding(padding: const EdgeInsets.all(32.0), child: Text("No events found."))))
                : SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        return Padding(
                          padding: EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
                          child: _buildEventCard(_events[index]),
                        );
                      },
                      childCount: _events.length,
                    ),
                  ),
      ],
    );
  }

  Widget _buildEventCard(RecordModel event) {
    final organization = event.expand['organization_id']?.first;
    final category = event.expand['categories_id']?.first;
    final String title = event.getStringValue('title', 'No Title');
    final String orgName = organization?.getStringValue('name', 'Unknown Org') ?? 'Unknown Org';
    final String categoryName = category?.getStringValue('name', 'No Category') ?? 'No Category';
    final DateTime eventDate = DateTime.parse(event.getStringValue('date'));
    final int maxParticipants = event.getIntValue('max_participant', 0);
    final int points = event.getIntValue('point_event', 0);
    
    String? orgAvatarUrl;
    if (organization != null) {
      final orgAvatarFilename = organization.getStringValue('avatar');
      if (orgAvatarFilename.isNotEmpty) {
        orgAvatarUrl = pb.getFileUrl(organization, orgAvatarFilename).toString();
      }
    }

    return GestureDetector(
      onTap: () {
        // Navigasi ke EventDetailScreen saat kartu ditekan
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => EventDetailScreen(event: event),
          ),
        );
      },
      child: Container(
        padding: EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.08),
              blurRadius: 20,
              offset: Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: Colors.grey.shade200,
              backgroundImage: orgAvatarUrl != null ? NetworkImage(orgAvatarUrl) : null,
              child: orgAvatarUrl == null 
                  ? Icon(Icons.business_rounded, color: Colors.grey.shade400)
                  : null,
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF2D3748)),
                        ),
                      ),
                      SizedBox(width: 8),
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(color: Color(0xFF6C63FF).withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                        child: Text(categoryName, style: TextStyle(color: Color(0xFF6C63FF), fontSize: 12, fontWeight: FontWeight.w500)),
                      ),
                    ],
                  ),
                  SizedBox(height: 4),
                  Text(orgName, style: TextStyle(color: Color(0xFF718096), fontSize: 14, fontWeight: FontWeight.w500)),
                  SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(Icons.calendar_today, size: 14, color: Colors.grey.shade500),
                      SizedBox(width: 6),
                      Text(DateFormat('MMM dd, yyyy').format(eventDate), style: TextStyle(color: Colors.grey.shade700, fontSize: 13)),
                    ],
                  ),
                  Divider(height: 24, color: Colors.grey.shade200),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildInfoChip(Icons.star_rounded, '$points Poin', Colors.orange),
                      _buildInfoChip(Icons.people_alt_rounded, '$maxParticipants Peserta', Colors.teal),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildInfoChip(IconData icon, String label, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 16),
          SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12),
          ),
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
    final numberFormatter = NumberFormat.decimalPattern('en_us');
    return Row(
      children: [
        Expanded(child: _buildStatCard('Total Points', _isLoading ? '...' : numberFormatter.format(_userPoints), Icons.star, Color(0xFFFFD700))),
        SizedBox(width: 16),
        Expanded(child: _buildStatCard('Events Joined', _isLoading ? '...' : _eventsJoined.toString(), Icons.event, Color(0xFF6C63FF))),
        SizedBox(width: 16),
        Expanded(child: _buildStatCard('Hours Logged', '48', Icons.access_time, Color(0xFF10B981))),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: Offset(0, 4))]),
      child: Column(
        children: [
          Container(width: 40, height: 40, decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(20)), child: Icon(icon, color: color, size: 20)),
          SizedBox(height: 8),
          _isLoading ? Padding(padding: const EdgeInsets.symmetric(vertical: 8.0), child: SizedBox(height: 14, width: 14, child: CircularProgressIndicator(strokeWidth: 2, color: color))) : Text(value, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF2D3748))),
          Text(title, style: TextStyle(fontSize: 12, color: Color(0xFF718096)), textAlign: TextAlign.center),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: Offset(0, 4))],
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (query) {
          if (_debounce?.isActive ?? false) _debounce!.cancel();
          _debounce = Timer(const Duration(milliseconds: 500), () {
            _fetchEvents();
          });
        },
        decoration: InputDecoration(
          hintText: 'Search volunteer opportunities...',
          hintStyle: TextStyle(color: Color(0xFFA0AEC0)),
          prefixIcon: Icon(Icons.search, color: Color(0xFFA0AEC0)),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
      ),
    );
  }

  Widget _buildQuickAccessButtons() {
    return Row(
      children: [
        Expanded(child: _buildQuickAccessButton('Search Events', Icons.search, Color(0xFF6C63FF), () => Navigator.push(context, MaterialPageRoute(builder: (context) => SearchScreen())))),
        SizedBox(width: 12),
        Expanded(child: _buildQuickAccessButton('My Hours', Icons.access_time, Color(0xFF10B981), () => Navigator.push(context, MaterialPageRoute(builder: (context) => VolunteerHoursScreen())))),
        SizedBox(width: 12),
        Expanded(child: _buildQuickAccessButton('Share Impact', Icons.share, Color(0xFFE53E3E), () => Navigator.push(context, MaterialPageRoute(builder: (context) => SocialSharingScreen())))),
      ],
    );
  }

  Widget _buildQuickAccessButton(String title, IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: color.withOpacity(0.3))),
        child: Column(
          children: [
            Icon(icon, color: color, size: 24),
            SizedBox(height: 8),
            Text(title, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: color), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
  
  Widget _buildCategoryFilter() {
    return SizedBox(
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _eventCategories.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            final isSelected = _selectedCategoryId == null;
            return _buildCategoryChip("All", null, isSelected);
          }
          final category = _eventCategories[index - 1];
          final isSelected = _selectedCategoryId == category.id;
          return _buildCategoryChip(category.getStringValue('name'), category.id, isSelected);
        },
      ),
    );
  }

  Widget _buildCategoryChip(String label, String? categoryId, bool isSelected) {
    return Padding(
      padding: EdgeInsets.only(right: 12),
      child: ActionChip(
        label: Text(label),
        labelStyle: TextStyle(color: isSelected ? Colors.white : Color(0xFF4A5568), fontWeight: FontWeight.w500),
        backgroundColor: isSelected ? Color(0xFF6C63FF) : Colors.white,
        side: BorderSide(color: isSelected ? Color(0xFF6C63FF) : Color(0xFFE2E8F0)),
        onPressed: () {
          setState(() {
            _selectedCategoryId = categoryId;
          });
          _fetchEvents();
        },
      ),
    );
  }

  Widget _buildProfileContent() {
    return Center(child: Text("Profile Page Content"));
  }

  Widget _buildBottomNavigationBar() {
    return Container(
      decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: Offset(0, -5))]),
      child: BottomNavigationBar(
        currentIndex: _bottomNavIndex,
        onTap: (index) {
          if (index == 0 || index == 4) {
             setState(() => _bottomNavIndex = index);
          } else {
             switch (index) {
              case 1: Navigator.push(context, MaterialPageRoute(builder: (context) => SearchScreen())); break;
              case 2: Navigator.push(context, MaterialPageRoute(builder: (context) => GamificationScreen())); break;
              case 3: Navigator.push(context, MaterialPageRoute(builder: (context) => VolunteerHoursScreen())); break;
            }
          }
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: Colors.transparent,
        selectedItemColor: Color(0xFF6C63FF),
        unselectedItemColor: Color(0xFF718096),
        elevation: 0,
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Search'),
          BottomNavigationBarItem(icon: Icon(Icons.emoji_events), label: 'Rewards'),
          BottomNavigationBarItem(icon: Icon(Icons.access_time), label: 'Hours'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}