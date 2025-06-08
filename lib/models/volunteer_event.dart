class VolunteerEvent {
  final String title;
  final String organization;
  final String date;
  final String time;
  final String location;
  final int participants;
  final int points;
  final String category;

  VolunteerEvent({
    required this.title,
    required this.organization,
    required this.date,
    required this.time,
    required this.location,
    required this.participants,
    required this.points,
    required this.category,
  });
}
