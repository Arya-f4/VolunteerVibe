import 'package:flutter/material.dart';
import 'enhanced_stat_card.dart';

class StatsSection extends StatelessWidget {
  final int activeEventsCount;
  final int totalVolunteers;
  final int completedEventsCount;
  final double averageRating;

  const StatsSection({
    Key? key,
    required this.activeEventsCount,
    required this.totalVolunteers,
    required this.completedEventsCount,
    required this.averageRating,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Overview',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2D3748),
          ),
        ),
        SizedBox(height: 16),
        GridView.count(
          crossAxisCount: 2,
          shrinkWrap: true,
          physics: NeverScrollableScrollPhysics(),
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.2,
          children: [
            EnhancedStatCard(
              title: 'Active Events',
              value: activeEventsCount.toString(),
              icon: Icons.event_available,
              color: Color(0xFF10B981),
              subtitle: 'Currently running',
            ),
            EnhancedStatCard(
              title: 'Total Volunteers',
              value: totalVolunteers.toString(),
              icon: Icons.people,
              color: Color(0xFF6C63FF),
              subtitle: 'All time participants',
            ),
            EnhancedStatCard(
              title: 'Completed Events',
              value: completedEventsCount.toString(),
              icon: Icons.check_circle,
              color: Color(0xFFED8936),
              subtitle: 'Successfully finished',
            ),
            EnhancedStatCard(
              title: 'Average Rating',
              value: averageRating > 0 ? averageRating.toStringAsFixed(1) : 'N/A',
              icon: Icons.star,
              color: Color(0xFFFFD700),
              subtitle: 'Event satisfaction',
            ),
          ],
        ),
      ],
    );
  }
}