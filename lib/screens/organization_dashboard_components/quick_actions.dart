import 'package:flutter/material.dart';
import 'action_card.dart';

class QuickActions extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2D3748),
          ),
        ),
        SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: ActionCard(
                title: 'View Analytics',
                icon: Icons.analytics,
                color: Color(0xFF6C63FF),
                onTap: () {},
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: ActionCard(
                title: 'Manage Events',
                icon: Icons.event_note,
                color: Color(0xFF10B981),
                onTap: () {},
              ),
            ),
            SizedBox(width: 12),
            Expanded(
              child: ActionCard(
                title: 'Messages',
                icon: Icons.message,
                color: Color(0xFFED8936),
                onTap: () {},
              ),
            ),
          ],
        ),
      ],
    );
  }
}