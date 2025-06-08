import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:geolocator/geolocator.dart';
import 'package:flutter_map_location_marker/flutter_map_location_marker.dart';

import '../../utils/app_colors.dart';
import '../../models/event_location.dart';
import '../../services/map_service.dart';
import 'user_event_details.dart';

class MapSearchScreen extends StatefulWidget {
  const MapSearchScreen({super.key});

  @override
  _MapSearchScreenState createState() => _MapSearchScreenState();
}

class _MapSearchScreenState extends State<MapSearchScreen> {
  final MapController _mapController = MapController();
  List<Marker> _markers = [];
  String _selectedCategory = 'All';
  bool _isLoading = true;
  LatLng _center = LatLng(-7.2575, 112.7521); // Default ke Surabaya
  final List<String> _categories = ['All', 'Environment', 'Community', 'Education', 'Health', 'Animals'];

  @override
  void initState() {
    super.initState();
    _loadMarkers();
    _getCurrentLocation();
  }

  Future<void> _getCurrentLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() => _isLoading = false);
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          setState(() => _isLoading = false);
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        setState(() => _isLoading = false);
        return;
      }

      Position position = await Geolocator.getCurrentPosition();
      final userPosition = LatLng(position.latitude, position.longitude);

      setState(() {
        _center = userPosition;
        _isLoading = false;
      });

      _mapController.move(userPosition, 14.0);

    } catch (e) {
      debugPrint("Error getting location: $e");
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _loadMarkers() {
    List<EventLocation> events = MapService.filterEventsByCategory(_selectedCategory);
    List<Marker> markers = [];

    for (var event in events) {
      markers.add(
        Marker(
          point: event.position,
          width: 40,
          height: 40,
          child: GestureDetector(
            onTap: () => _onMarkerTapped(event.eventID),
            child: Tooltip(
              message: event.title,
              child: Icon(
                Icons.location_pin,
                color: _getCategoryColor(event.category),
                size: 40.0,
              ),
            ),
          ),
        ),
      );
    }

    if (mounted) {
      setState(() {
        _markers = markers;
      });
    }
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Environment':
        return AppColors.primary;
      case 'Community':
        return Colors.blueAccent;
      case 'Education':
        return Colors.orangeAccent;
      case 'Health':
        return Colors.redAccent;
      case 'Animals':
        return Colors.brown;
      default:
        return Colors.purpleAccent;
    }
  }

  void _onMarkerTapped(int eventId) {
    final event = MapService.getEventDetails(eventId);
    if (event != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => UserEventDetails(event: event),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          _isLoading
              ? Center(child: CircularProgressIndicator(color: AppColors.primary))
              : FlutterMap(
                  mapController: _mapController,
                  options: MapOptions(
                    initialCenter: _center,
                    initialZoom: 13.0,
                    interactionOptions: const InteractionOptions(
                      flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                    ),
                  ),
                  children: [
                    TileLayer(
                      urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.example.yourapp', // Ganti dengan nama paket aplikasi Anda
                    ),
                    MarkerLayer(markers: _markers),
                    CurrentLocationLayer(
                      style: LocationMarkerStyle(
                        marker: Container(
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.2),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              )
                            ],
                          ),
                          child: Center(
                            child: Container(
                              width: 16,
                              height: 16,
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
          Positioned(
            top: MediaQuery.of(context).padding.top + 16,
            left: 16,
            right: 16,
            child: _buildCategoryFilter(),
          ),
          Positioned(
            bottom: 16,
            right: 16,
            child: FloatingActionButton(
              heroTag: "locationButton",
              backgroundColor: Colors.white,
              onPressed: _getCurrentLocation,
              child: Icon(Icons.my_location, color: AppColors.primary),
            ),
          ),
          Positioned(
            bottom: 16,
            left: 16,
            child: FloatingActionButton.extended(
              heroTag: "listButton",
              backgroundColor: AppColors.primary,
              onPressed: _showEventsList,
              icon: const Icon(Icons.list, color: Colors.white),
              label: const Text('List View', style: TextStyle(color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryFilter() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      height: 50,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(Icons.filter_list, color: AppColors.textSecondary),
          const SizedBox(width: 8),
          Expanded(
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _selectedCategory,
                isExpanded: true,
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedCategory = newValue!;
                  });
                  _loadMarkers();
                },
                items: _categories.map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showEventsList() {
    List<EventLocation> events = MapService.filterEventsByCategory(_selectedCategory);
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.only(top: 8),
              height: 4,
              width: 40,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Events Near You',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            Expanded(
              child: events.isEmpty
                  ? Center(
                      child: Text(
                        'No events found in this category',
                        style: TextStyle(color: AppColors.textSecondary),
                      ),
                    )
                  : ListView.builder(
                      itemCount: events.length,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemBuilder: (context, index) {
                        final event = events[index];
                        return _buildEventListItem(event);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEventListItem(EventLocation event) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: CircleAvatar(
          backgroundColor: AppColors.primary.withOpacity(0.2),
          child: Icon(
            _getCategoryIcon(event.category),
            color: AppColors.primary,
          ),
        ),
        title: Text(
          event.title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              event.organizationName,
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.calendar_today, size: 12, color: AppColors.textTertiary),
                const SizedBox(width: 4),
                Text(
                  '${event.date.day}/${event.date.month}/${event.date.year}',
                  style: TextStyle(fontSize: 12, color: AppColors.textTertiary),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.star, size: 12, color: Colors.amber),
                const SizedBox(width: 4),
                Text(
                  '${event.points} pts',
                  style: TextStyle(fontSize: 12, color: AppColors.textTertiary),
                ),
              ],
            ),
          ],
        ),
        trailing: Icon(Icons.chevron_right, color: AppColors.textSecondary),
        onTap: () {
          Navigator.pop(context);
          _onMarkerTapped(event.eventID);
        },
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Environment':
        return Icons.eco;
      case 'Community':
        return Icons.people;
      case 'Education':
        return Icons.school;
      case 'Health':
        return Icons.health_and_safety;
      case 'Animals':
        return Icons.pets;
      default:
        return Icons.event;
    }
  }
}