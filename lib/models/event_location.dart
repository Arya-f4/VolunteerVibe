import 'package:latlong2/latlong.dart';
import 'event.dart';

class EventLocation {
  final int eventID;
  final String title;
  final String description;
  final LatLng position;
  final String category;
  final String organizationName;
  final int points;
  final DateTime date;

  EventLocation({
    required this.eventID,
    required this.title,
    required this.description,
    required this.position,
    required this.category,
    required this.organizationName,
    required this.points,
    required this.date,
  });

  factory EventLocation.fromEvent(Event event, LatLng position) {
    return EventLocation(
      eventID: event.eventID,
      title: event.title,
      description: event.description,
      position: position,
      category: event.category,
      organizationName: event.organizationName,
      points: event.points,
      date: event.date,
    );
  }
}