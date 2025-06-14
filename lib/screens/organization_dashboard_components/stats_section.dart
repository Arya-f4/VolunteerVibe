import 'package:flutter/material.dart';

class StatsSection extends StatelessWidget {
  final int activeEventsCount;
  final int totalVolunteers;
  final int completedEventsCount;

  const StatsSection({
    Key? key,
    required this.activeEventsCount,
    required this.totalVolunteers,
    required this.completedEventsCount,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Overview',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2D3748),
          ),
        ),
        SizedBox(height: 16),
        // [MODIFIKASI] Menggunakan Row dan Expanded untuk tata letak horizontal
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                count: activeEventsCount.toString(),
                label: 'Active Events',
                icon: Icons.event_note,
                color: Color(0xFF6C63FF),
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: _buildStatCard(
                count: totalVolunteers.toString(),
                label: 'Total Volunteers',
                icon: Icons.people,
                color: Color(0xFF3182CE),
              ),
            ),
            SizedBox(width: 16),
            Expanded(
              child: _buildStatCard(
                count: completedEventsCount.toString(),
                label: 'Complete Events',
                icon: Icons.check_circle,
                color: Color(0xFF38A169),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required String count,
    required String label,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          SizedBox(height: 16),
          Text(
            count,
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2D3748),
            ),
          ),
          SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF718096),
            ),
          ),
        ],
      ),
    );
  }
}