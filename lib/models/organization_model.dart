class Organization {
  final int id;
  final String name;
  final String email;
  final String? profileImage;
  final String description;
  final String contactInfo;
  final List<int> createdEvents;
  final int totalParticipants;
  final int totalEvents;
  final String website;
  final String address;
  final List<String> categories;

  Organization({
    required this.id,
    required this.name,
    required this.email,
    this.profileImage,
    required this.description,
    required this.contactInfo,
    required this.createdEvents,
    required this.totalParticipants,
    required this.totalEvents,
    required this.website,
    required this.address,
    required this.categories,
  });

  Organization copyWith({
    int? id,
    String? name,
    String? email,
    String? profileImage,
    String? description,
    String? contactInfo,
    List<int>? createdEvents,
    int? totalParticipants,
    int? totalEvents,
    String? website,
    String? address,
    List<String>? categories,
  }) {
    return Organization(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      profileImage: profileImage ?? this.profileImage,
      description: description ?? this.description,
      contactInfo: contactInfo ?? this.contactInfo,
      createdEvents: createdEvents ?? this.createdEvents,
      totalParticipants: totalParticipants ?? this.totalParticipants,
      totalEvents: totalEvents ?? this.totalEvents,
      website: website ?? this.website,
      address: address ?? this.address,
      categories: categories ?? this.categories,
    );
  }
}
