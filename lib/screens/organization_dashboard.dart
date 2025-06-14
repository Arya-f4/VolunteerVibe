import 'package:flutter/material.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:volunteervibe/services/pocketbase_service.dart';
import 'package:volunteervibe/screens/organization_dashboard_components/organization_header.dart';
import 'package:volunteervibe/screens/organization_dashboard_components/stats_section.dart';
import 'package:volunteervibe/screens/organization_dashboard_components/events_section.dart';
import 'package:volunteervibe/screens/organization_dashboard_components/access_denied.dart';
import 'package:volunteervibe/screens/organization_dashboard_components/create_event_bottom_sheet.dart';
import 'package:volunteervibe/screens/profile_screen.dart';
import 'package:volunteervibe/screens/search_screen.dart';
import 'package:volunteervibe/screens/gamification_screen.dart';
import 'package:volunteervibe/screens/volunteer_hours_screen.dart';

class OrganizationDashboard extends StatefulWidget {
  @override
  _OrganizationDashboardState createState() => _OrganizationDashboardState();
}

class _OrganizationDashboardState extends State<OrganizationDashboard> with TickerProviderStateMixin {
  final PocketBaseService _pbService = PocketBaseService();
  late AnimationController _fadeController;
  late AnimationController _slideController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  bool _isLoading = true;
  RecordModel? _organization;
  List<RecordModel> _organizationEvents = [];
  Map<String, int> _waitingCounts = {};

  int _activeEventsCount = 0;
  int _totalVolunteers = 0;
  int _completedEventsCount = 0;
  
  int _bottomNavIndex = 0; 

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadDashboardData();
  }

  void _initializeAnimations() {
    _fadeController = AnimationController(duration: Duration(milliseconds: 800), vsync: this);
    _slideController = AnimationController(duration: Duration(milliseconds: 600), vsync: this);
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(CurvedAnimation(parent: _fadeController, curve: Curves.easeInOut));
    _slideAnimation = Tween<Offset>(begin: Offset(0, 0.3), end: Offset.zero).animate(CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic));
  }
  
  @override
  void dispose() {
    _fadeController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  Future<void> _loadDashboardData() async {
    setState(() => _isLoading = true);
    try {
      final orgRecord = _pbService.getCurrentUser();
      if (orgRecord != null && (orgRecord.collectionName == 'organization' || orgRecord.data['is_organization'] == true)) {
        _organization = orgRecord;
        _organizationEvents = await _pbService.fetchEventsByOrganization(organizationId: _organization!.id);
        
        final eventIds = _organizationEvents.map((e) => e.id).toList();
        _waitingCounts = await _pbService.getWaitingCountsForEvents(eventIds);
        
        _calculateStats();
      } else {
        _organization = null;
      }
    } catch (e) {
      print("Error loading dashboard data: $e");
      _organization = null;
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
        if (_organization != null) {
          _fadeController.forward();
          _slideController.forward();
        }
      }
    }
  }

  void _calculateStats() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    int active = 0;
    int completed = 0;
    Set<String> uniqueVolunteers = {};

    for (var event in _organizationEvents) {
      final eventDate = DateTime.parse(event.getStringValue('date'));
      final eventDay = DateTime(eventDate.year, eventDate.month, eventDate.day);
      
      if (eventDay.isBefore(today)) {
        completed++;
      } else {
        active++;
      }
      
      final participants = event.getListValue<String>('participant_id');
      for (var pId in participants) {
        uniqueVolunteers.add(pId);
      }
    }

    setState(() {
      _activeEventsCount = active;
      _completedEventsCount = completed;
      _totalVolunteers = uniqueVolunteers.length;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF8FAFC),
      body: RefreshIndicator(
        onRefresh: _loadDashboardData,
        color: Color(0xFF6C63FF),
        child: _buildBody()
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
      floatingActionButton: _organization != null ? _buildFloatingActionButton() : null,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  Widget _buildFloatingActionButton() {
    return FloatingActionButton.extended(
      onPressed: () => _showCreateEventBottomSheet(),
      backgroundColor: Color(0xFF6C63FF),
      foregroundColor: Colors.white,
      elevation: 8,
      icon: Icon(Icons.add, size: 24),
      label: Text('Create Event', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    );
  }

  Widget _buildBody() {
    return CustomScrollView(
      physics: BouncingScrollPhysics(),
      slivers: [
        _buildSliverAppBar(),
        if (_isLoading)
          SliverFillRemaining(child: Center(child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6C63FF)))))
        else if (_organization == null)
          SliverFillRemaining(child: AccessDenied(onGoBack: () => Navigator.pop(context)))
        else
          SliverList(
            delegate: SliverChildListDelegate([
              FadeTransition(
                opacity: _fadeAnimation,
                child: SlideTransition(
                  position: _slideAnimation,
                  child: Padding(
                    padding: EdgeInsets.all(24.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        StatsSection(
                          activeEventsCount: _activeEventsCount,
                          totalVolunteers: _totalVolunteers,
                          completedEventsCount: _completedEventsCount,
                        ),
                        SizedBox(height: 32),
                        EventsSection(
                          events: _organizationEvents,
                          waitingCounts: _waitingCounts,
                          onViewAll: () {},
                          onCreateEvent: () => _showCreateEventBottomSheet(),
                          onRefresh: _loadDashboardData,
                        ),
                        SizedBox(height: 100),
                      ],
                    ),
                  ),
                ),
              ),
            ]),
          ),
      ],
    );
  }

  Widget _buildSliverAppBar() {
    return SliverAppBar(
      expandedHeight: 120,
      floating: false,
      pinned: true,
      backgroundColor: Color(0xFF6C63FF),
      foregroundColor: Colors.white,
      elevation: 0,
      automaticallyImplyLeading: false,
      flexibleSpace: FlexibleSpaceBar(
        background: _organization != null
            ? OrganizationHeader(
                organization: _organization!,
                pbService: _pbService,
              )
            : Container(color: Color(0xFF6C63FF)),
      ),
    );
  }

  void _showCreateEventBottomSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CreateEventBottomSheet(
        organization: _organization!,
        onEventCreated: () {
          _loadDashboardData();
        },
      ),
    );
  }

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
            case 0:
              break;
            case 4:
              Navigator.push(context, MaterialPageRoute(builder: (context) => ProfileScreen()));
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
}