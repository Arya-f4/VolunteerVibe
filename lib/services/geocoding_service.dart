import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:volunteervibe/models/place.dart'; // Sesuaikan path jika perlu

class GeocodingService {
  Future<List<Place>> searchPlaces(String query) async {
    if (query.length < 3) {
      return []; // Jangan cari jika query terlalu pendek
    }

    final url = Uri.parse('https://nominatim.openstreetmap.org/search?q=$query&format=json&addressdetails=1&limit=5');
    
    try {
      final response = await http.get(url, headers: {
        'User-Agent': 'com.volunteervibe.app', // API Nominatim kadang memerlukan User-Agent
      });

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => Place.fromJson(json)).toList();
      }
    } catch (e) {
      print('Error searching places: $e');
    }

    return [];
  }
}