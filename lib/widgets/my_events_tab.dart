import 'package:flutter/material.dart';
import '../utils/app_colors.dart';

class MyEventsTab extends StatelessWidget {
  final List<Map<String, dynamic>> myEvents = [
    {
      'title': 'Community Garden Project',
      'date': 'Tomorrow, 10:00 AM',
      'status': 'Confirmed',
      'points': 45,
    },
    {
      'title': 'Senior Center Visit',
      'date': 'Dec 16, 3:00 PM',
      'status': 'Pending',
      'points': 35,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'My Registered Events',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              OutlinedButton.icon(
                onPressed: () {},
                icon: Icon(Icons.add, size: 16),
                label: Text('Find More'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.textTertiary,
                  side: BorderSide(color: AppColors.border),
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
              ),
            ],
          ),
          SizedBox(height: 20),

          // Events List
          ListView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            itemCount: myEvents.length,
            itemBuilder: (context, index) {
              final event = myEvents[index];
              return Container(
                margin: EdgeInsets.only(bottom: 16),
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            event['title'],
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(Icons.access_time, size: 16, color: AppColors.textTertiary),
                              SizedBox(width: 8),
                              Text(
                                event['date'],
                                style: TextStyle(
                                  fontSize: 14,
                                  color: AppColors.textTertiary,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 8),
                          Container(
                            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: event['status'] == 'Confirmed' 
                                  ? Colors.green.withOpacity(0.1)
                                  : Colors.orange.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              event['status'],
                              style: TextStyle(
                                fontSize: 12,
                                color: event['status'] == 'Confirmed' 
                                    ? Colors.green[700]
                                    : Colors.orange[700],
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      children: [
                        Text(
                          '${event['points']} points',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.textTertiary,
                          ),
                        ),
                        SizedBox(height: 8),
                        IconButton(
                          onPressed: () {},
                          icon: Icon(Icons.share),
                          style: IconButton.styleFrom(
                            backgroundColor: AppColors.surfaceLight,
                            foregroundColor: AppColors.textTertiary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
