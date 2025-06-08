import 'package:flutter/material.dart';
import '../utils/app_colors.dart';
import '../models/volunteer_event.dart';

class DiscoverTab extends StatefulWidget {
  @override
  _DiscoverTabState createState() => _DiscoverTabState();
}

class _DiscoverTabState extends State<DiscoverTab> {
  final TextEditingController _searchController = TextEditingController();

  final List<VolunteerEvent> events = [
    VolunteerEvent(
      title: "Beach Cleanup Drive",
      organization: "Ocean Guardians",
      date: "Dec 15, 2024",
      time: "9:00 AM",
      location: "Santa Monica Beach",
      participants: 24,
      points: 50,
      category: "Environment",
    ),
    VolunteerEvent(
      title: "Food Bank Volunteer",
      organization: "Community Kitchen",
      date: "Dec 18, 2024",
      time: "2:00 PM",
      location: "Downtown Center",
      participants: 15,
      points: 40,
      category: "Community",
    ),
    VolunteerEvent(
      title: "Youth Mentoring Program",
      organization: "Future Leaders",
      date: "Dec 20, 2024",
      time: "4:00 PM",
      location: "Local High School",
      participants: 8,
      points: 60,
      category: "Education",
    ),
  ];

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
              decoration: InputDecoration(
                hintText: 'Search volunteer opportunities...',
                prefixIcon: Icon(Icons.search, color: AppColors.textTertiary),
                suffixIcon: IconButton(
                  icon: Icon(Icons.filter_list, color: AppColors.primary),
                  onPressed: () {},
                ),
                border: InputBorder.none,
                contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ),
          SizedBox(height: 20),

          // Quick Stats
          Row(
            children: [
              Expanded(child: _buildStatCard("12", "Events Joined")),
              SizedBox(width: 12),
              Expanded(child: _buildStatCard("48", "Hours Logged")),
              SizedBox(width: 12),
              Expanded(child: _buildStatCard("5", "Badges Earned")),
            ],
          ),
          SizedBox(height: 24),

          // Featured Events
          Text(
            'Featured Opportunities',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppColors.textPrimary,
            ),
          ),
          SizedBox(height: 16),

          // Events List
          ListView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            itemCount: events.length,
            itemBuilder: (context, index) {
              return _buildEventCard(events[index]);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(String value, String label) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppColors.textTertiary,
            ),
          ),
          SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textTertiary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildEventCard(VolunteerEvent event) {
    return Container(
      margin: EdgeInsets.only(bottom: 16),
      padding: EdgeInsets.all(16),
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
                      event.organization,
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textTertiary,
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

          // Event Details
          Row(
            children: [
              Icon(Icons.calendar_today, size: 16, color: AppColors.textTertiary),
              SizedBox(width: 8),
              Text(
                '${event.date} at ${event.time}',
                style: TextStyle(fontSize: 14, color: AppColors.textTertiary),
              ),
            ],
          ),
          SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.location_on, size: 16, color: AppColors.textTertiary),
              SizedBox(width: 8),
              Text(
                event.location,
                style: TextStyle(fontSize: 14, color: AppColors.textTertiary),
              ),
            ],
          ),
          SizedBox(height: 16),

          // Bottom Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Row(
                    children: [
                      Icon(Icons.people, size: 16, color: AppColors.textTertiary),
                      SizedBox(width: 4),
                      Text(
                        '${event.participants} joined',
                        style: TextStyle(fontSize: 12, color: AppColors.textTertiary),
                      ),
                    ],
                  ),
                  SizedBox(width: 16),
                  Row(
                    children: [
                      Icon(Icons.star, size: 16, color: Colors.amber),
                      SizedBox(width: 4),
                      Text(
                        '${event.points} pts',
                        style: TextStyle(fontSize: 12, color: AppColors.textTertiary),
                      ),
                    ],
                  ),
                ],
              ),
              ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  minimumSize: Size(0, 0),
                ),
                child: Text(
                  'Join Event',
                  style: TextStyle(fontSize: 12),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
