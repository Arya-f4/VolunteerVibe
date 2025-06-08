class Event {
  final int eventID;
  final String title;
  final String description;
  final DateTime date;
  final String location;
  final String category;
  final String organizationName;
  final int maxParticipants;
  final int currentParticipants;
  final int points;
  final List<String> requirements;
  final String imageUrl;

  Event({
    required this.eventID,
    required this.title,
    required this.description,
    required this.date,
    required this.location,
    required this.category,
    required this.organizationName,
    required this.maxParticipants,
    required this.currentParticipants,
    required this.points,
    required this.requirements,
    required this.imageUrl,
  });

  bool get isAvailable => currentParticipants < maxParticipants;
  
  String get formattedDate {
    return "${date.day}/${date.month}/${date.year}";
  }
  
  String get formattedTime {
    return "${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}";
  }
}

class User {
  final int userID;
  final String name;
  final String email;
  final int points;
  final List<int> registeredEvents;
  final List<int> completedEvents;

  User({
    required this.userID,
    required this.name,
    required this.email,
    required this.points,
    required this.registeredEvents,
    required this.completedEvents,
  });
}

class Organization {
  final int orgID;
  final String name;
  final String email;
  final List<int> createdEvents;
  final String description;
  final String contactInfo;

  Organization({
    required this.orgID,
    required this.name,
    required this.email,
    required this.createdEvents,
    required this.description,
    required this.contactInfo,
  });
}

class Participant {
  final int userID;
  final String name;
  final String email;
  final DateTime registrationDate;
  final bool attended;

  Participant({
    required this.userID,
    required this.name,
    required this.email,
    required this.registrationDate,
    required this.attended,
  });
}
