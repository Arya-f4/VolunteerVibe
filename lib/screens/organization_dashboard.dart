import 'package:flutter/material.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:volunteervibe/services/pocketbase_service.dart';
import '../screens/organization_dashboard_components/organization_header.dart';
import '../screens/organization_dashboard_components//stats_section.dart';
import '../screens/organization_dashboard_components//quick_actions.dart';
import '../screens/organization_dashboard_components//events_section.dart';
import '../screens/organization_dashboard_components//access_denied.dart';
import '../screens/organization_dashboard_components//create_event_bottom_sheet.dart';
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
  int _activeEventsCount = 0;
  int _totalVolunteers = 0;
  int _completedEventsCount = 0;
  double _averageRating = 0.0;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
    _loadDashboardData();
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
    _slideAnimation = Tween<Offset>(begin: Offset(0, 0.3), end: Offset.zero).animate(
      CurvedAnimation(parent: _slideController, curve: Curves.easeOutCubic),
    );
    _fadeController.forward();
    _slideController.forward();
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
      if (orgRecord != null && orgRecord.collectionName == 'organization') {
        _organization = orgRecord;
        _organizationEvents = await _pbService.fetchEventsByOrganization(organizationId: _organization!.id);
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
      }
    }
  }

  void _calculateStats() {
    final now = DateTime.now();
    int active = 0;
    int completed = 0;
    int volunteers = 0;
    double totalRating = 0.0;
    int ratedEvents = 0;

    for (var event in _organizationEvents) {
      final eventDate = DateTime.parse(event.getStringValue('date'));
      if (eventDate.isAfter(now)) {
        active++;
      } else {
        completed++;
      }
      volunteers += (event.getListValue<String>('participant_id')).length;
      final rating = event.getDoubleValue('rating', 0.0);
      if (rating > 0) {
        totalRating += rating;
        ratedEvents++;
      }
    }

    setState(() {
      _activeEventsCount = active;
      _completedEventsCount = completed;
      _totalVolunteers = volunteers;
      _averageRating = ratedEvents > 0 ? totalRating / ratedEvents : 0.0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF8FAFC),
      body: _buildBody(),
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
      label: Text(
        'Create Event',
        style: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 16,
        ),
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    );
  }

  Widget _buildBody() {
    return CustomScrollView(
      slivers: [
        _buildSliverAppBar(),
        if (_isLoading)
          SliverFillRemaining(
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF6C63FF)),
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Loading dashboard...',
                    style: TextStyle(
                      color: Color(0xFF718096),
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          )
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
                          averageRating: _averageRating,
                        ),
                        SizedBox(height: 32),
                        QuickActions(),
                        SizedBox(height: 32),
                        EventsSection(
                          events: _organizationEvents,
                          onViewAll: () {},
                          onCreateEvent: () => _showCreateEventBottomSheet(),
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
      flexibleSpace: FlexibleSpaceBar(
        background: _organization != null
            ? OrganizationHeader(
                organization: _organization!,
                pbService: _pbService,
              )
            : null,
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
            blurRadius: 10,
            offset: Offset(0, -5),
          ),
        ],
      ),
      child: BottomNavigationBar(
        currentIndex: 0,
        onTap: (index) {
          switch (index) {
            case 0:
              Navigator.popUntil(context, (route) => route.isFirst);
              break;
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