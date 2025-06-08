import 'package:latlong2/latlong.dart';
import '../models/event_location.dart';
import '../models/event.dart';

class MapService {
  // Data contoh acara
  static List<EventLocation> getEventLocations() {
    return [
      EventLocation(
        eventID: 1,
        title: "Beach Cleanup Drive",
        description: "Join us for a community beach cleanup to protect marine life.",
        position: LatLng(-7.2491, 112.7508), // Surabaya
        category: "Environment",
        organizationName: "Ocean Guardians",
        points: 50,
        date: DateTime(2025, 10, 25, 9, 0),
      ),
      EventLocation(
        eventID: 2,
        title: "Food Bank Volunteer",
        description: "Help sort and distribute food to families in need.",
        position: LatLng(-7.2575, 112.7521), // Surabaya
        category: "Community",
        organizationName: "Community Kitchen",
        points: 40,
        date: DateTime(2025, 11, 5, 14, 0),
      ),
      EventLocation(
        eventID: 3,
        title: "Youth Mentoring Program",
        description: "Mentor young students and help them with their academic development.",
        position: LatLng(-7.2652, 112.7424), // Surabaya
        category: "Education",
        organizationName: "Future Leaders",
        points: 60,
        date: DateTime(2025, 11, 12, 16, 0),
      ),
    ];
  }

  static EventLocation? getEventLocationById(int id) {
    try {
      return getEventLocations().firstWhere((event) => event.eventID == id);
    } catch (e) {
      return null;
    }
  }

  static List<EventLocation> filterEventsByCategory(String category) {
    if (category == 'All') {
      return getEventLocations();
    }
    return getEventLocations().where((event) => event.category == category).toList();
  }

  static Event? getEventDetails(int eventId) {
    EventLocation? location = getEventLocationById(eventId);
    if (location == null) return null;

    return Event(
      eventID: location.eventID,
      title: location.title,
      description: location.description,
      date: location.date,
      location: "Location based on map",
      category: location.category,
      organizationName: location.organizationName,
      maxParticipants: 50,
      currentParticipants: 24,
      points: location.points,
      requirements: ["Bring water bottle", "Wear comfortable clothes"],
      imageUrl: "",
    );
  }
}