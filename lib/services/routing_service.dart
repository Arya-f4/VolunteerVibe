import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

class RoutingService {
  Future<List<LatLng>> getRoute(LatLng start, LatLng end) async {
    final url = 'http://router.project-osrm.org/route/v1/driving/${start.longitude},${start.latitude};${end.longitude},${end.latitude}?overview=full&geometries=geojson';
    
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final geometry = data['routes'][0]['geometry']['coordinates'];
        final List<LatLng> points = geometry.map<LatLng>((coord) => LatLng(coord[1], coord[0])).toList();
        return points;
      }
    } catch (e) {
      print('Error fetching route: $e');
    }
    
    return []; // Kembalikan list kosong jika gagal
  }
}