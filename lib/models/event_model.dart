class Event {
  final int id;
  final String title;
  final String description;
  final DateTime date;
  final String location;
  final String category;
  final String organizationName;
  final int organizationId;
  final int maxParticipants;
  final int currentParticipants;
  final int points;
  final List<String> requirements;
  final String? imageUrl;
  final double? latitude;
  final double? longitude;
  final bool isVirtual;
  final String status; // "upcoming", "ongoing", "completed", "cancelled"
  final int duration; // in minutes

  Event({
    required this.id,
    required this.title,
    required this.description,
    required this.date,
    required this.location,
    required this.category,
    required this.organizationName,
    required this.organizationId,
    required this.maxParticipants,
    required this.currentParticipants,
    required this.points,
    required this.requirements,
    this.imageUrl,
    this.latitude,
    this.longitude,
    this.isVirtual = false,
    required this.status,
    required this.duration,
  });

  bool get isAvailable => currentParticipants < maxParticipants;
  
  String get formattedDate {
    return "${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}";
  }
  
  String get formattedTime {
    return "${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}";
  }

  String get formattedDuration {
    if (duration < 60) {
      return "$duration minutes";
    } else {
      int hours = duration ~/ 60;
      int minutes = duration % 60;
      return hours > 0 
          ? minutes > 0 
              ? "$hours hr $minutes min" 
              : "$hours hr"
          : "$minutes min";
    }
  }

  Event copyWith({
    int? id,
    String? title,
    String? description,
    DateTime? date,
    String? location,
    String? category,
    String? organizationName,
    int? organizationId,
    int? maxParticipants,
    int? currentParticipants,
    int? points,
    List<String>? requirements,
    String? imageUrl,
    double? latitude,
    double? longitude,
    bool? isVirtual,
    String? status,
    int? duration,
  }) {
    return Event(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      date: date ?? this.date,
      location: location ?? this.location,
      category: category ?? this.category,
      organizationName: organizationName ?? this.organizationName,
      organizationId: organizationId ?? this.organizationId,
      maxParticipants: maxParticipants ?? this.maxParticipants,
      currentParticipants: currentParticipants ?? this.currentParticipants,
      points: points ?? this.points,
      requirements: requirements ?? this.requirements,
      imageUrl: imageUrl ?? this.imageUrl,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      isVirtual: isVirtual ?? this.isVirtual,
      status: status ?? this.status,
      duration: duration ?? this.duration,
    );
  }
}

class Participant {
  final int id;
  final String name;
  final String email;
  final String? profileImage;
  final DateTime registrationDate;
  final bool attended;
  final int? rating;
  final String? feedback;

  Participant({
    required this.id,
    required this.name,
    required this.email,
    this.profileImage,
    required this.registrationDate,
    required this.attended,
    this.rating,
    this.feedback,
  });

  Participant copyWith({
    int? id,
    String? name,
    String? email,
    String? profileImage,
    DateTime? registrationDate,
    bool? attended,
    int? rating,
    String? feedback,
  }) {
    return Participant(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      profileImage: profileImage ?? this.profileImage,
      registrationDate: registrationDate ?? this.registrationDate,
      attended: attended ?? this.attended,
      rating: rating ?? this.rating,
      feedback: feedback ?? this.feedback,
    );
  }
}
