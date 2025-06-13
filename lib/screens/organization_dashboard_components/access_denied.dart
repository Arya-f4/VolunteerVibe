import 'package:flutter/material.dart';

class AccessDenied extends StatelessWidget {
  final VoidCallback onGoBack;

  const AccessDenied({Key? key, required this.onGoBack}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Color(0xFFED8936).withOpacity(0.1),
                borderRadius: BorderRadius.circular(60),
              ),
              child: Icon(
                Icons.lock_person,
                color: Color(0xFFED8936),
                size: 60,
              ),
            ),
            SizedBox(height: 24),
            Text(
              'Access Denied',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF2D3748),
              ),
            ),
            SizedBox(height: 12),
            Text(
              'You must be logged in as an organization to view this dashboard.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Color(0xFF718096),
                height: 1.5,
              ),
            ),
            SizedBox(height: 24),
            ElevatedButton(
              onPressed: onGoBack,
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF6C63FF),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              ),
              child: Text('Go Back'),
            ),
          ],
        ),
      ),
    );
  }
}