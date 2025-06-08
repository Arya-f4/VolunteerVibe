import 'package:flutter/material.dart';
import '../../utils/app_colors.dart';
import '../../models/event.dart';
import 'user_event_details.dart';

class UserSearchEvents extends StatefulWidget {
  @override
  _UserSearchEventsState createState() => _UserSearchEventsState();
}

class _UserSearchEventsState extends State<UserSearchEvents> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'All';
  String _selectedLocation = 'All';

  final List<String> categories = ['All', 'Environment', 'Community', 'Education', 'Health', 'Animals'];
  final List<String> locations = ['All', 'Downtown', 'Santa Monica', 'Beverly Hills', 'Hollywood'];

  final List<Event> allEvents = [
    Event(
      eventID: 1,
      title: "Beach Cleanup Drive",
      description: "Join us for a community beach cleanup to protect marine life and keep our beaches beautiful.",
      date: DateTime(2024, 12, 15, 9, 0),
      location: "Santa Monica Beach",
      category: "Environment",
      organizationName: "Ocean Guardians",
      maxParticipants: 50,
      currentParticipants: 24,
      points: 50,
      requirements: ["Bring water bottle", "Wear comfortable clothes"],
      imageUrl: "",
    ),
    Event(
      eventID: 2,
      title: "Food Bank Volunteer",
      description: "Help sort and distribute food to families in need in our community.",
      date: DateTime(2024, 12, 18, 14, 0),
      location: "Downtown Community Center",
      category: "Community",
      organizationName: "Community Kitchen",
      maxParticipants: 30,
      currentParticipants: 15,
      points: 40,
      requirements: ["Food safety training", "Minimum 3 hours commitment"],
      imageUrl: "",
    ),
    Event(
      eventID: 3,
      title: "Youth Mentoring Program",
      description: "Mentor young students and help them with their academic and personal development.",
      date: DateTime(2024, 12, 20, 16, 0),
      location: "Beverly Hills High School",
      category: "Education",
      organizationName: "Future Leaders",
      maxParticipants: 20,
      currentParticipants: 8,
      points: 60,
      requirements: ["Background check required", "Teaching experience preferred"],
      imageUrl: "",
    ),
    Event(
      eventID: 4,
      title: "Animal Shelter Support",
      description: "Help care for rescued animals and assist with daily shelter operations.",
      date: DateTime(2024, 12, 22, 10, 0),
      location: "Hollywood Animal Shelter",
      category: "Animals",
      organizationName: "Pet Rescue Alliance",
      maxParticipants: 15,
      currentParticipants: 7,
      points: 45,
      requirements: ["Love for animals", "Physical activity involved"],
      imageUrl: "",
    ),
  ];

  List<Event> get filteredEvents {
    return allEvents.where((event) {
      bool matchesSearch = _searchController.text.isEmpty ||
          event.title.toLowerCase().contains(_searchController.text.toLowerCase()) ||
          event.description.toLowerCase().contains(_searchController.text.toLowerCase());
      
      bool matchesCategory = _selectedCategory == 'All' || event.category == _selectedCategory;
      bool matchesLocation = _selectedLocation == 'All' || event.location.contains(_selectedLocation);
      
      return matchesSearch && matchesCategory && matchesLocation;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search Bar
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.border),
            ),
            child: TextField(
              controller: _searchController,
              onChanged: (value) {
                setState(() {});
              },
              decoration: InputDecoration(
                hintText: 'Search events...',
                prefixIcon: Icon(Icons.search, color: AppColors.textSecondary),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ),
          SizedBox(height: 16),

          // Filters
          Text(
            'Filters',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 12),
          
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Category',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: 8),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedCategory,
                          isExpanded: true,
                          onChanged: (String? newValue) {
                            setState(() {
                              _selectedCategory = newValue!;
                            });
                          },
                          items: categories.map<DropdownMenuItem<String>>((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(value),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Location',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: 8),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedLocation,
                          isExpanded: true,
                          onChanged: (String? newValue) {
                            setState(() {
                              _selectedLocation = newValue!;
                            });
                          },
                          items: locations.map<DropdownMenuItem<String>>((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(value),
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 24),

          // Results Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Search Results',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              Text(
                '${filteredEvents.length} events found',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),

          // Events List
          filteredEvents.isEmpty
              ? _buildEmptyState()
              : ListView.builder(
                  shrinkWrap: true,
                  physics: NeverScrollableScrollPhysics(),
                  itemCount: filteredEvents.length,
                  itemBuilder: (context, index) {
                    return _buildEventCard(filteredEvents[index]);
                  },
                ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      padding: EdgeInsets.all(32),
      child: Column(
        children: [
          Icon(
            Icons.search_off,
            size: 64,
            color: AppColors.textSecondary,
          ),
          SizedBox(height: 16),
          Text(
            'No events found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Try adjusting your search criteria',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEventCard(Event event) {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Event Image Placeholder
          Container(
            height: 120,
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Center(
              child: Icon(
                _getCategoryIcon(event.category),
                size: 48,
                color: AppColors.primary,
              ),
            ),
          ),
          
          Padding(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            event.title,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            event.organizationName,
                            style: TextStyle(
                              fontSize: 14,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceLight,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        event.category,
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 12),
                
                Text(
                  event.description,
                  style: TextStyle(
                    fontSize: 14,
                    color: AppColors.textSecondary,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 12),
                
                Row(
                  children: [
                    Icon(Icons.calendar_today, size: 16, color: AppColors.textSecondary),
                    SizedBox(width: 8),
                    Text(
                      '${event.formattedDate} at ${event.formattedTime}',
                      style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
                    ),
                  ],
                ),
                SizedBox(height: 8),
                Row(
                  children: [
                    Icon(Icons.location_on, size: 16, color: AppColors.textSecondary),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        event.location,
                        style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.people, size: 16, color: AppColors.textSecondary),
                        SizedBox(width: 4),
                        Text(
                          '${event.currentParticipants}/${event.maxParticipants}',
                          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                        SizedBox(width: 16),
                        Icon(Icons.star, size: 16, color: Colors.amber),
                        SizedBox(width: 4),
                        Text(
                          '${event.points} pts',
                          style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => UserEventDetails(event: event),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        minimumSize: Size(0, 0),
                      ),
                      child: Text(
                        'View Details',
                        style: TextStyle(fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _getCategoryIcon(String category) {
    switch (category) {
      case 'Environment':
        return Icons.eco;
      case 'Community':
        return Icons.people;
      case 'Education':
        return Icons.school;
      case 'Health':
        return Icons.health_and_safety;
      case 'Animals':
        return Icons.pets;
      default:
        return Icons.event;
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
