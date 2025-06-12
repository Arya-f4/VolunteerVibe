import 'package:flutter/material.dart';
import 'dart:async';
import 'package:intl/intl.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:volunteervibe/services/location_service.dart';
import 'package:volunteervibe/services/pocketbase_service.dart';
import 'package:volunteervibe/services/routing_service.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart';
import 'package:flutter_map_location_marker/flutter_map_location_marker.dart';
import 'package:volunteervibe/screens/profile_screen.dart';

// Import untuk halaman lain di bottom bar
import 'event_detail_screen.dart';
import 'gamification_screen.dart';
import 'volunteer_hours_screen.dart';
// import 'profile_screen.dart'; // Pastikan Anda memiliki ProfileScreen

class SearchScreen extends StatefulWidget {
  @override
  _SearchScreenState createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  // Services
  final PocketBaseService _pbService = PocketBaseService();
  final LocationService _locationService = LocationService();
  final RoutingService _routingService = RoutingService();

  // Controllers and UI State
  final _searchController = TextEditingController();
  Timer? _debounce;
  final _mapController = MapController();
  bool _isMapView = true;
  bool _isLoading = true;
  bool _isRouteLoading = false;
  
  // Data State
  List<RecordModel> _events = [];
  List<RecordModel> _eventCategories = [];
  LatLng? _currentPosition;
  List<LatLng> _routePoints = [];

  // Filter State
  String? _selectedCategoryId;
  DateTime? _selectedDate;
  
  // State untuk Bottom Bar, 1 = index Search
  int _bottomNavIndex = 1;

  @override
  void initState() {
    super.initState();
    _initializeScreen();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    // _mapController tidak punya dispose() di versi terbaru, jika ada, gunakan
    super.dispose();
  }

  Future<void> _initializeScreen() async {
    setState(() => _isLoading = true);
    try {
      _currentPosition = await _locationService.getCurrentPosition();
      _eventCategories = await _pbService.fetchEventCategories();
      await _fetchEvents(); 
    } catch (e) {
      print("An error occurred during initialization: $e");
      // Menampilkan pesan error kepada pengguna jika perlu
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to load initial data. Please try again."))
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _centerOnCurrentLocation() async {
    final newPosition = await _locationService.getCurrentPosition();
    if (mounted) {
      setState(() => _currentPosition = newPosition);
      _mapController.move(newPosition, _mapController.camera.zoom);
    }
  }

  Future<void> _fetchEvents() async {
    if(!mounted) return;
    if(!_isLoading) setState(() => _isLoading = true);
    
    final eventsResult = await _pbService.fetchEvents(
      categoryId: _selectedCategoryId,
      searchQuery: _searchController.text.trim().isEmpty ? null : _searchController.text.trim(),
      selectedDate: _selectedDate,
    );
    if (mounted) {
      setState(() {
        _events = eventsResult;
        _isLoading = false; 
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Search Opportunities', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2D3748))),
        backgroundColor: Colors.white,
        elevation: 1,
        automaticallyImplyLeading: false,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: Color(0xFF2D3748)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            _buildSearchHeader(),
            _buildQuickFilters(),
            Expanded(child: _buildSearchResults()),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(),
    );
  }

  // --- START: KODE BOTTOM BAR YANG DIPERBARUI ---

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
    // Menggunakan warna utama dari halaman ini agar konsisten
    final activeColor = Color(0xFF6C63FF); 
    final inactiveColor = Color(0xFF718096);
    final bool isActive = _bottomNavIndex == index;

    return Flexible(
      child: GestureDetector(
        onTap: () {
          if (index == _bottomNavIndex) return; // Jangan lakukan apa-apa jika tab yang sama ditekan

          switch (index) {
            case 0:
              // Kembali ke HomeScreen
              Navigator.pop(context);
              break;
            case 1:
              // Sudah di halaman ini
              break;
            case 2:
              Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => GamificationScreen()));
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

  // --- END: KODE BOTTOM BAR YANG DIPERBARUI ---


  List<Marker> _buildMarkers(List<RecordModel> events) {
    return events.map((event) {
      final dynamic locationRawData = event.data['location'];
      LatLng? point;
      if (locationRawData is Map<String, dynamic> && locationRawData.containsKey('lat') && locationRawData.containsKey('lon')) {
        try {
          point = LatLng((locationRawData['lat'] as num).toDouble(), (locationRawData['lon'] as num).toDouble());
        } catch (e) { print('Error converting coordinates: $e'); }
      }
      if (point == null) return null;
      return Marker(
        width: 45, height: 45, point: point,
        child: GestureDetector(
          onTap: () => _showEventPreview(event, point!),
          child: Tooltip(
            message: event.getStringValue('title'),
            child: Icon(Icons.location_pin, color: Color(0xFFEF4444), size: 40),
          ),
        ),
      );
    }).whereType<Marker>().toList();
  }

  void _showEventPreview(RecordModel event, LatLng destination) {
    final organization = event.expand['organization_id']?.first;
    final category = event.expand['categories_id']?.first;
    final String title = event.getStringValue('title', 'No Title');
    final String orgName = organization?.getStringValue('name', 'Unknown Org') ?? 'Unknown Org';
    final String categoryName = category?.getStringValue('name', 'No Category') ?? 'No Category';
    final DateTime eventDate = DateTime.parse(event.getStringValue('date'));
    final int maxParticipants = event.getIntValue('max_participant', 0);
    final int points = event.getIntValue('point_event', 0);
    final String description = event.getStringValue('description', 'No description provided.');
    String? orgAvatarUrl = (organization != null) ? _pbService.getFileUrl(organization, organization.getStringValue('avatar')) : null;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (modalContext) => StatefulBuilder(
        builder: (BuildContext context, StateSetter modalState) {
          return Container(
            margin: EdgeInsets.all(8),
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: Colors.grey.shade200,
                        backgroundImage: orgAvatarUrl != null ? NetworkImage(orgAvatarUrl) : null,
                        child: orgAvatarUrl == null ? Icon(Icons.business_rounded, color: Colors.grey.shade400) : null,
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
                                Expanded(child: Text(title, style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2D3748)))),
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
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  Text(
                    description,
                    maxLines: 4,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Color(0xFF4A5568), fontSize: 14, height: 1.5),
                  ),
                  Divider(height: 32, color: Colors.grey.shade200),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildInfoChip(Icons.star_rounded, '$points Poin', Colors.orange),
                      _buildInfoChip(Icons.people_alt_rounded, '$maxParticipants Peserta', Colors.teal),
                    ],
                  ),
                  SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: _isRouteLoading
                              ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF6C63FF)))
                              : Icon(_routePoints.isEmpty ? Icons.directions : Icons.clear_rounded),
                          label: Text(_routePoints.isEmpty ? "Show Route" : "Hide Route"),
                          onPressed: _isRouteLoading ? null : () async {
                            final navigator = Navigator.of(modalContext);
                            if (_routePoints.isNotEmpty) {
                              setState(() => _routePoints = []);
                              modalState(() {});
                            } else {
                              if (_currentPosition != null) {
                                modalState(() => _isRouteLoading = true);
                                final route = await _routingService.getRoute(_currentPosition!, destination);
                                if (mounted) {
                                  setState(() => _routePoints = route);
                                  modalState(() => _isRouteLoading = false);
                                }
                                if (navigator.canPop()) navigator.pop();
                              }
                            }
                          },
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Color(0xFF6C63FF),
                            side: BorderSide(color: Color(0xFF6C63FF)),
                            padding: EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                          ),
                        ),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: ElevatedButton(
                          child: Text("View Details"),
                          onPressed: () {
                            Navigator.pop(modalContext);
                            Navigator.push(context, MaterialPageRoute(builder: (context) => EventDetailScreen(event: event)));
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Color(0xFF6C63FF),
                            foregroundColor: Colors.white,
                            padding: EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
                          ),
                        ),
                      ),
                    ],
                  )
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSearchHeader() {
    return Container(
      padding: EdgeInsets.fromLTRB(24, 16, 24, 16),
      color: Colors.white,
      child: Column(
        children: [
          TextField(
            controller: _searchController,
            onChanged: (value) {
              if (_debounce?.isActive ?? false) _debounce!.cancel();
              _debounce = Timer(const Duration(milliseconds: 500), () => _fetchEvents());
            },
            decoration: InputDecoration(
              hintText: 'Search events, organizations...',
              prefixIcon: Icon(Icons.search, color: Color(0xFF6C63FF)),
              filled: true,
              fillColor: Color(0xFFF7FAFC),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Color(0xFF6C63FF))),
            ),
          ),
          SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _buildLocationSelector()),
              SizedBox(width: 12),
              Expanded(child: _buildDateSelector()),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickFilters() {
    return Container(
      height: 60,
      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 10),
      decoration: BoxDecoration(color: Colors.white, border: Border(top: BorderSide(color: Colors.grey.shade200))),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _eventCategories.length + 1,
        itemBuilder: (context, index) {
          if (index == 0) {
            return _buildCategoryChip("All", null, _selectedCategoryId == null);
          }
          final category = _eventCategories[index - 1];
          return _buildCategoryChip(category.getStringValue('name'), category.id, _selectedCategoryId == category.id);
        },
      ),
    );
  }

  Widget _buildCategoryChip(String label, String? categoryId, bool isSelected) {
    return Padding(
      padding: EdgeInsets.only(right: 12),
      child: ActionChip(
        label: Text(label),
        labelStyle: TextStyle(color: isSelected ? Colors.white : Color(0xFF4A5568), fontWeight: FontWeight.w600),
        backgroundColor: isSelected ? Color(0xFF6C63FF) : Colors.white,
        side: BorderSide(color: isSelected ? Color(0xFF6C63FF) : Color(0xFFE2E8F0)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        onPressed: () {
          setState(() => _selectedCategoryId = categoryId);
          _fetchEvents();
        },
      ),
    );
  }

  Widget _buildSearchResults() {
    return Container(
      color: Color(0xFFF8FAFC),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Row(
              children: [
                Text('${_events.length} opportunities found', style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF2D3748))),
                Spacer(),
                ActionChip(
                  avatar: Icon(_isMapView ? Icons.list : Icons.map_outlined, color: _isMapView ? Color(0xFF6C63FF) : Colors.white, size: 16),
                  label: Text(_isMapView ? 'List' : 'Map'),
                  labelStyle: TextStyle(color: _isMapView ? Color(0xFF6C63FF) : Colors.white, fontWeight: FontWeight.w600),
                  backgroundColor: _isMapView ? Colors.white : Color(0xFF6C63FF),
                  side: BorderSide(color: Color(0xFF6C63FF).withOpacity(0.5)),
                  onPressed: () => setState(() => _isMapView = !_isMapView),
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator(color: Color(0xFF6C63FF)))
                : _isMapView ? _buildMapView() : _buildListView(),
          ),
        ],
      ),
    );
  }

  Widget _buildMapView() {
    if (_currentPosition == null) return Center(child: Text("Getting your location...", style: TextStyle(color: Colors.grey.shade600)));
    return Stack(
      children: [
        FlutterMap(
          mapController: _mapController,
          options: MapOptions(initialCenter: _currentPosition!, initialZoom: 12.0, maxZoom: 18),
          children: [
            TileLayer(urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png'),
            if (_routePoints.isNotEmpty)
              PolylineLayer(
                polylines: [Polyline(points: _routePoints, color: Colors.blue.shade400, strokeWidth: 5)],
              ),
            CurrentLocationLayer(),
            MarkerClusterLayerWidget(
              options: MarkerClusterLayerOptions(
                maxClusterRadius: 45,
                size: const Size(40, 40),
                builder: (context, markers) => Container(
                  decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), color: const Color(0xFF6C63FF)),
                  child: Center(child: Text(markers.length.toString(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                ),
                markers: _buildMarkers(_events),
                onClusterTap: (cluster) => _mapController.move(cluster.bounds.center, _mapController.camera.zoom + 1),
              ),
            ),
          ],
        ),
        Positioned(
          bottom: 20,
          right: 20,
          child: Column(
            children: [
              FloatingActionButton(
                heroTag: "zoomInBtn", mini: true, backgroundColor: Colors.white,
                onPressed: () => _mapController.move(_mapController.camera.center, _mapController.camera.zoom + 1),
                child: Icon(Icons.add, color: Colors.black87),
              ),
              SizedBox(height: 8),
              FloatingActionButton(
                heroTag: "zoomOutBtn", mini: true, backgroundColor: Colors.white,
                onPressed: () => _mapController.move(_mapController.camera.center, _mapController.camera.zoom - 1),
                child: Icon(Icons.remove, color: Colors.black87),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildListView() {
    if (_events.isEmpty) return _buildEmptyState();
    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      itemCount: _events.length,
      itemBuilder: (context, index) => _buildEventCard(_events[index]),
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
    String? orgAvatarUrl = (organization != null) ? _pbService.getFileUrl(organization, organization.getStringValue('avatar')) : null;

    return Card(
      margin: EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 3, shadowColor: Colors.grey.withOpacity(0.1),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => EventDetailScreen(event: event))),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: Colors.grey.shade200,
                backgroundImage: orgAvatarUrl != null ? NetworkImage(orgAvatarUrl) : null,
                child: orgAvatarUrl == null ? Icon(Icons.business_rounded, color: Colors.grey.shade400) : null,
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
                        Expanded(child: Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Color(0xFF2D3748)))),
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
      ),
    );
  }
  
  Widget _buildInfoChip(IconData icon, String label, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
      child: Row(
        children: [
          Icon(icon, color: color, size: 16),
          SizedBox(width: 6),
          Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
        ],
      ),
    );
  }
  
  Widget _buildEmptyState() => Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(Icons.search_off_rounded, size: 60, color: Colors.grey.shade400),
        SizedBox(height: 16),
        Text("No opportunities found", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Color(0xFF4A5568))),
        SizedBox(height: 8),
        Text(
          "Try adjusting your search or filters.",
          style: TextStyle(color: Colors.grey.shade600),
          textAlign: TextAlign.center,
        ),
      ],
    ),
  );
  
  Widget _buildDateSelector() {
    return Material(
      color: Colors.transparent, // Transparan agar efek InkWell terlihat
      child: InkWell(
        onTap: () async {
          final picked = await showDatePicker(
            context: context, initialDate: _selectedDate ?? DateTime.now(),
            firstDate: DateTime(2020), lastDate: DateTime(2030),
            builder: (context, child) {
              return Theme(
                data: ThemeData.light().copyWith(
                  colorScheme: ColorScheme.light(primary: Color(0xFF6C63FF)),
                  buttonTheme: ButtonThemeData(textTheme: ButtonTextTheme.primary),
                ),
                child: child!,
              );
            },
          );
          if (picked != null && picked != _selectedDate) {
            setState(() => _selectedDate = picked);
            _fetchEvents();
          }
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12), 
            border: Border.all(color: Color(0xFFE2E8F0)),
            color: Color(0xFFF7FAFC)
          ),
          child: Row(
            children: [
              Icon(Icons.calendar_today, color: Color(0xFF6C63FF), size: 20),
              SizedBox(width: 8),
              Expanded(child: Text(_selectedDate == null ? 'Any Date' : DateFormat('MMM dd, yyyy').format(_selectedDate!))),
              if (_selectedDate != null)
                GestureDetector(
                  onTap: () {
                    setState(() => _selectedDate = null);
                    _fetchEvents();
                  },
                  child: Icon(Icons.clear, color: Colors.grey[600], size: 18),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLocationSelector() {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _centerOnCurrentLocation,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Color(0xFFE2E8F0)),
            color: Color(0xFFF7FAFC)
          ),
          child: Row(
            children: [
              Icon(Icons.my_location, color: Color(0xFF6C63FF), size: 20),
              SizedBox(width: 8),
              Expanded(child: Text("Current Location", overflow: TextOverflow.ellipsis)),
            ],
          ),
        ),
      ),
    );
  }
}