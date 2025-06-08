import 'package:flutter/material.dart';
import 'auth/login_page.dart';
import 'screens/user/user_dashboard.dart';
import 'screens/organization/organization_dashboard.dart';

void main() {
  runApp(const VolunteerVibeApp());
}

class VolunteerVibeApp extends StatelessWidget {
  const VolunteerVibeApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'VolunteerVibe',
      home: OrganizationDashboard(),
      debugShowCheckedModeBanner: false,
    );
  }
}
