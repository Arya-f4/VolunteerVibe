class User {
  final int id;
  final String name;
  final String email;
  final String? profileImage;
  final int points;
  final List<int> registeredEvents;
  final List<int> completedEvents;
  final List<String> badges;
  final String level;
  final int eventsJoined;
  final int hoursLogged;
  final int rank;

  User({
    required this.id,
    required this.name,
    required this.email,
    this.profileImage,
    required this.points,
    required this.registeredEvents,
    required this.completedEvents,
    required this.badges,
    required this.level,
    required this.eventsJoined,
    required this.hoursLogged,
    required this.rank,
  });

  User copyWith({
    int? id,
    String? name,
    String? email,
    String? profileImage,
    int? points,
    List<int>? registeredEvents,
    List<int>? completedEvents,
    List<String>? badges,
    String? level,
    int? eventsJoined,
    int? hoursLogged,
    int? rank,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      profileImage: profileImage ?? this.profileImage,
      points: points ?? this.points,
      registeredEvents: registeredEvents ?? this.registeredEvents,
      completedEvents: completedEvents ?? this.completedEvents,
      badges: badges ?? this.badges,
      level: level ?? this.level,
      eventsJoined: eventsJoined ?? this.eventsJoined,
      hoursLogged: hoursLogged ?? this.hoursLogged,
      rank: rank ?? this.rank,
    );
  }
}
