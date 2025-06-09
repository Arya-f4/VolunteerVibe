import 'package:flutter/material.dart';
import 'package:volunteervibe/auth/login_page.dart';
import 'screens/splash_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/home_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/organization_dashboard.dart';

// Tambahkan import untuk screen baru
import 'screens/search_screen.dart';
import 'screens/gamification_screen.dart';
import 'screens/social_sharing_screen.dart';
import 'screens/volunteer_hours_screen.dart';
import 'screens/organization_register_screen.dart';

void main() {
  runApp(VolunteerVibeApp());
}

class VolunteerVibeApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'VolunteerVibe',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        primaryColor: Color(0xFF6C63FF),
        scaffoldBackgroundColor: Color(0xFFF8F9FA),
        fontFamily: 'SF Pro Display',
        textTheme: TextTheme(
          headlineLarge: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: Color(0xFF2D3748),
          ),
          headlineMedium: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.w600,
            color: Color(0xFF2D3748),
          ),
          bodyLarge: TextStyle(
            fontSize: 16,
            color: Color(0xFF4A5568),
          ),
          bodyMedium: TextStyle(
            fontSize: 14,
            color: Color(0xFF718096),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Color(0xFF6C63FF),
            foregroundColor: Colors.white,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            padding: EdgeInsets.symmetric(vertical: 16),
          ),
        ),
      ),
      home: SplashScreen(),
      routes: {
        '/welcome': (context) => LoginPage(),
        '/login': (context) => LoginScreen(),
        '/register': (context) => RegisterScreen(),
        '/home': (context) => HomeScreen(),
        '/profile': (context) => ProfileScreen(),
        '/organization': (context) => OrganizationDashboard(),
        '/search': (context) => SearchScreen(),
        '/gamification': (context) => GamificationScreen(),
        '/social': (context) => SocialSharingScreen(),
        '/hours': (context) => VolunteerHoursScreen(),
        '/org-register': (context) => OrganizationRegisterScreen(),
      },
    );
  }
}
