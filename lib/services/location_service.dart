import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

class LocationService {
  // Lokasi default jika GPS tidak aktif atau ditolak
  final LatLng _defaultLocation = LatLng(-7.2575, 112.7521); // Surabaya

  Future<LatLng> getCurrentPosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Jika layanan lokasi mati, kembalikan lokasi default
      return _defaultLocation;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return _defaultLocation;
      }
    }
    
    if (permission == LocationPermission.deniedForever) {
      return _defaultLocation;
    } 

    Position position = await Geolocator.getCurrentPosition();
    return LatLng(position.latitude, position.longitude);
  }
}