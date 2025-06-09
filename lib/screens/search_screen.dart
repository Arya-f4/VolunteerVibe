import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:convert';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'package:volunteervibe/pocketbase_client.dart';
import 'package:pocketbase/pocketbase.dart';

import 'event_detail_screen.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:flutter_map_marker_cluster/flutter_map_marker_cluster.dart';
import 'package:flutter_map_location_marker/flutter_map_location_marker.dart';

class SearchScreen extends StatefulWidget {
  @override
  _SearchScreenState createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;
  List<RecordModel> _events = [];
  List<RecordModel> _eventCategories = [];
  String? _selectedCategoryId;
  DateTime? _selectedDate;
  bool _isMapView = true;
  final MapController _mapController = MapController();
  bool _isLoading = true;

  // State untuk rute dan lokasi
  LatLng? _currentPosition;
  List<LatLng> _routePoints = [];
  bool _isRouteLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeScreen();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _debounce?.cancel();
    _mapController.dispose();
    super.dispose();
  }

  Future<void> _initializeScreen() async {
    await _getCurrentLocation();
    await _fetchCategories(); // Memanggil fungsi yang hilang
    await _fetchEvents();
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      setState(() {
        _currentPosition = LatLng(-7.2575, 112.7521); // Default Surabaya
      });
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
         setState(() {
          _currentPosition = LatLng(-7.2575, 112.7521);
        });
        return;
      }
    }
    
    if (permission == LocationPermission.deniedForever) {
      setState(() {
        _currentPosition = LatLng(-7.2575, 112.7521);
      });
      return;
    } 

    Position position = await Geolocator.getCurrentPosition();
    if(mounted) {
      setState(() {
        _currentPosition = LatLng(position.latitude, position.longitude);
      });
    }
  }

  Future<void> _getRoute(LatLng start, LatLng end) async {
    setState(() {
      _isRouteLoading = true;
    });

    final url = 'http://router.project-osrm.org/route/v1/driving/${start.longitude},${start.latitude};${end.longitude},${end.latitude}?overview=full&geometries=geojson';
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      final geometry = data['routes'][0]['geometry']['coordinates'];
      final List<LatLng> points = geometry.map<LatLng>((coord) => LatLng(coord[1], coord[0])).toList();
      
      setState(() {
        _routePoints = points;
      });
    } else {
      print('Failed to load route');
    }

    setState(() {
      _isRouteLoading = false;
    });
  }
  
  // --- FUNGSI YANG HILANG, SEKARANG DIKEMBALIKAN ---
  Future<void> _fetchCategories() async {
    try {
      final result = await pb.collection('event_categories').getFullList(sort: 'name');
      if (mounted) setState(() => _eventCategories = result);
    } catch (e) {
      print('Error fetching categories: $e');
    }
  }
  // ----------------------------------------------------

  Future<void> _fetchEvents() async {
    if (mounted) setState(() => _isLoading = true);
    final searchQuery = _searchController.text.trim();
    List<String> filters = ["date >= @now"];
    if (_selectedCategoryId != null) {
      filters.add("categories_id = '$_selectedCategoryId'");
    }
    if (searchQuery.isNotEmpty) {
      filters.add("(title ~ '$searchQuery' || description ~ '$searchQuery')");
    }
    if (_selectedDate != null) {
      final dateOnly = DateFormat('yyyy-MM-dd').format(_selectedDate!);
      filters.add("date >= '$dateOnly 00:00:00' && date <= '$dateOnly 23:59:59'");
    }
    final filterString = filters.join(' && ');
    try {
      final result = await pb.collection('event').getFullList(
        sort: '+date',
        filter: filterString,
        expand: 'organization_id,categories_id',
      );
      if (mounted) setState(() => _events = result);
    } catch (e) {
      print('Error fetching events: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
  
  List<Marker> _buildMarkers(List<RecordModel> events) {
    return events.map((event) {
      final dynamic locationRawData = event.data['location'];
      LatLng? point;
      Map<String, dynamic>? locationMap;
      if (locationRawData is Map<String, dynamic>) {
        locationMap = locationRawData;
      } else if (locationRawData is String && locationRawData.isNotEmpty) {
        try {
          locationMap = jsonDecode(locationRawData);
        } catch (e) {
          print('Error decoding location JSON string for event ${event.id}: $e');
        }
      }
      if (locationMap != null) {
        if (locationMap.containsKey('lat') && locationMap.containsKey('lon')) {
          try {
            final lat = (locationMap['lat'] as num).toDouble();
            final lon = (locationMap['lon'] as num).toDouble();
            point = LatLng(lat, lon);
          } catch (e) {
            print('Error converting location coordinates for event ${event.id}: $e');
          }
        }
      }
      if (point == null) return null;
      return Marker(
        width: 45,
        height: 45,
        point: point,
        child: GestureDetector(
          onTap: () => _showEventPreview(event, point!),
          child: Tooltip(
            message: event.getStringValue('title'),
            child: Icon(
              Icons.location_pin,
              color: Colors.red,
              size: 40,
            ),
          ),
        ),
      );
    }).whereType<Marker>().toList();
  }

  void _showEventPreview(RecordModel event, LatLng destination) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(event.getStringValue('title'), style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
              SizedBox(height: 8),
              Text(event.expand['organization_id']?.first.getStringValue('name') ?? 'Unknown Organization', style: Theme.of(context).textTheme.titleMedium),
              SizedBox(height: 16),
              Text(
                event.getStringValue('description'), 
                maxLines: 3, 
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              Spacer(),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: _isRouteLoading 
                          ? SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                          : Icon(_routePoints.isEmpty ? Icons.directions : Icons.clear),
                      label: Text(_routePoints.isEmpty ? "Show Route" : "Hide Route"),
                      onPressed: _isRouteLoading ? null : () {
                        if (_routePoints.isNotEmpty) {
                          setState(() {
                            _routePoints = [];
                          });
                        } else {
                          if (_currentPosition != null) {
                            _getRoute(_currentPosition!, destination);
                          }
                        }
                        Navigator.pop(context);
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Color(0xFF6C63FF),
                        side: BorderSide(color: Color(0xFF6C63FF)),
                        padding: EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      child: Text("View Details"),
                      onPressed: () {
                        Navigator.pop(context);
                        Navigator.push(context, MaterialPageRoute(builder: (context) => EventDetailScreen(event: event)));
                      },
                      style: ElevatedButton.styleFrom(
                         backgroundColor: Color(0xFF6C63FF),
                         foregroundColor: Colors.white,
                         padding: EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Search Opportunities', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2D3748))),
        backgroundColor: Colors.white,
        elevation: 1,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: Color(0xFF2D3748)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            _buildSearchHeader(),
            _buildQuickFilters(), // Widget yang hilang, sekarang dikembalikan
            Expanded(
              child: _buildSearchResults(),
            ),
          ],
        ),
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
              _debounce = Timer(const Duration(milliseconds: 500), () {
                _fetchEvents();
              });
            },
            decoration: InputDecoration(
              hintText: 'Search events, organizations...',
              prefixIcon: Icon(Icons.search, color: Color(0xFF6C63FF)),
              filled: true,
              fillColor: Color(0xFFF7FAFC),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Color(0xFFE2E8F0))),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide(color: Color(0xFFE2E8F0))),
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

  // --- WIDGET YANG HILANG, SEKARANG DIKEMBALIKAN ---
  Widget _buildQuickFilters() {
    return Container(
      height: 60,
      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.grey.shade200))
      ),
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
  // ----------------------------------------------------

  // --- WIDGET YANG HILANG, SEKARANG DIKEMBALIKAN ---
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
          setState(() {
            _selectedCategoryId = categoryId;
          });
          _fetchEvents();
        },
      ),
    );
  }
  // ----------------------------------------------------

  Widget _buildSearchResults() {
    return Container(
      color: Color(0xFFF8FAFC),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Row(
              children: [
                Text(
                  '${_events.length} opportunities found',
                  style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF2D3748)),
                ),
                Spacer(),
                ActionChip(
                  avatar: Icon(_isMapView ? Icons.list : Icons.map_outlined, color: _isMapView ? Colors.white : Color(0xFF6C63FF), size: 16),
                  label: Text(_isMapView ? 'List' : 'Map'),
                  labelStyle: TextStyle(color: _isMapView ? Colors.white : Color(0xFF6C63FF), fontWeight: FontWeight.w600),
                  backgroundColor: _isMapView ? Color(0xFF6C63FF) : Colors.white,
                  side: BorderSide(color: Color(0xFF6C63FF).withOpacity(0.5)),
                  onPressed: () => setState(() => _isMapView = !_isMapView),
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
              ? Center(child: CircularProgressIndicator())
              : _isMapView ? _buildMapView(_events) : _buildListView(_events),
          ),
        ],
      ),
    );
  }

  Widget _buildListView(List<RecordModel> events) {
    if (events.isEmpty) return _buildEmptyState();
    return ListView.builder(
      padding: EdgeInsets.symmetric(horizontal: 24),
      itemCount: events.length,
      itemBuilder: (context, index) => _buildEventCard(events[index]),
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

    return Card(
      margin: EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 3,
      shadowColor: Colors.grey.withOpacity(0.1),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => EventDetailScreen(event: event),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
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

  Widget _buildMapView(List<RecordModel> events) {
    if (_currentPosition == null) return Center(child: CircularProgressIndicator());
    
    final markers = _buildMarkers(events);

    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(initialCenter: _currentPosition!, initialZoom: 12.0),
      children: [
        TileLayer(urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png'),
        
        if (_routePoints.isNotEmpty)
          PolylineLayer(
            polylines: [
              Polyline(
                points: _routePoints,
                color: Colors.blue,
                strokeWidth: 5,
              ),
            ],
          ),

        CurrentLocationLayer(),
        MarkerClusterLayerWidget(
          options: MarkerClusterLayerOptions(
            maxClusterRadius: 45,
            size: const Size(40, 40),
            builder: (context, markers) {
              return Container(
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(20), color: const Color(0xFF6C63FF)),
                child: Center(child: Text(markers.length.toString(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
              );
            },
            markers: markers,
            onClusterTap: (cluster) => _mapController.move(cluster.bounds.center, _mapController.camera.zoom + 1),
          ),
        ),
      ],
    );
  }
  
  Widget _buildEmptyState() => Center(child: Text("No opportunities found. Try different filters."));
  Future<void> _selectDate() async {
    final picked = await showDatePicker(context: context, initialDate: _selectedDate ?? DateTime.now(), firstDate: DateTime(2020), lastDate: DateTime(2030));
    if (picked != null && picked != _selectedDate) {
      setState(() => _selectedDate = picked);
      _fetchEvents();
    }
  }
  String _formatDate(DateTime date) => DateFormat('MMM dd, yyyy').format(date);
  Widget _buildLocationSelector() => GestureDetector(child: Container(padding: EdgeInsets.all(12), decoration: BoxDecoration(color: Color(0xFFF7FAFC), borderRadius: BorderRadius.circular(12), border: Border.all(color: Color(0xFFE2E8F0))), child: Row(children: [Icon(Icons.my_location, color: Color(0xFF6C63FF), size: 20), SizedBox(width: 8), Expanded(child: Text("Current Location", overflow: TextOverflow.ellipsis)), Icon(Icons.keyboard_arrow_down, color: Color(0xFF718096))])));
  Widget _buildDateSelector() => GestureDetector(onTap: _selectDate, child: Container(padding: EdgeInsets.all(12), decoration: BoxDecoration(color: Color(0xFFF7FAFC), borderRadius: BorderRadius.circular(12), border: Border.all(color: Color(0xFFE2E8F0))), child: Row(children: [Icon(Icons.calendar_today, color: Color(0xFF6C63FF), size: 20), SizedBox(width: 8), Expanded(child: Text(_selectedDate == null ? 'Any Date' : _formatDate(_selectedDate!))), if (_selectedDate != null) GestureDetector(onTap: () { setState(() => _selectedDate = null); _fetchEvents(); }, child: Icon(Icons.clear, size: 16))])));
}