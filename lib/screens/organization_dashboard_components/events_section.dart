import 'package:flutter/material.dart';
import 'package:pocketbase/pocketbase.dart';
import 'empty_events_state.dart';
import 'enhanced_event_card.dart';

class EventsSection extends StatelessWidget {
  final List<RecordModel> events;
  final VoidCallback onViewAll;
  final VoidCallback onCreateEvent;

  const EventsSection({
    Key? key,
    required this.events,
    required this.onViewAll,
    required this.onCreateEvent, required Map<String, int> waitingCounts, required Future<void> Function() onRefresh,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'My Events',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2D3748),
              ),
            ),
            Spacer(),
            TextButton.icon(
              onPressed: onViewAll,
              icon: Icon(Icons.arrow_forward, size: 16),
              label: Text('View All'),
              style: TextButton.styleFrom(
                foregroundColor: Color(0xFF6C63FF),
              ),
            ),
          ],
        ),
        SizedBox(height: 16),
        events.isEmpty
            ? EmptyEventsState(onCreateEvent: onCreateEvent)
            : ListView.separated(
                physics: NeverScrollableScrollPhysics(),
                shrinkWrap: true,
                itemCount: events.length > 5 ? 5 : events.length,
                itemBuilder: (context, index) {
                  return EnhancedEventCard(event: events[index]);
                },
                separatorBuilder: (context, index) => SizedBox(height: 16),
              ),
      ],
    );
  }
}