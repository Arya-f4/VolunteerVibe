// File: lib/services/pocketbase_service.dart

import 'dart:io'; 
import 'package:pocketbase/pocketbase.dart';
import 'package:volunteervibe/pocketbase_client.dart';
import 'package:http/http.dart' as http; // Added import for MultipartFile

class PocketBaseService {
  
  void logout() {
    pb.authStore.clear();
    print('PocketBaseService: User logged out.');
  }
  
  String? getFileUrl(RecordModel record, String filename) {
    if (filename.isEmpty) {
      return null;
    }
    final url = pb.getFileUrl(record, filename).toString();
    // print('PocketBaseService: Generated file URL: $url for record ID: ${record.id}'); // Bisa sangat berisik
    return url;
  }

  Future<RecordModel?> getMyOrganization() async {
    final user = getCurrentUser();
    // Cek jika user yang login adalah dari koleksi 'organization'
    if (user != null && user.collectionName == 'organization') {
      print('PocketBaseService: Current user is an organization.');
      return user;
    }
    // Jika dari koleksi 'users', coba cari relasinya (logika lama, bisa disesuaikan)
    if (user != null && user.collectionName == 'users' && user.getStringValue('organization_id').isNotEmpty) {
        try {
        print('PocketBaseService: Fetching organization from user relation...');
        final userWithOrg = await pb.collection('users').getOne(user.id, expand: 'organization_id');
        final organization = userWithOrg.expand['organization_id']?.first;
        print('PocketBaseService: Organization from user relation: ${organization?.id}');
        return organization;
      } catch (e) {
        print('Error fetching my organization from user relation: $e');
        return null;
      }
    }
    print('PocketBaseService: No organization found for current user.');
    return null;
  }
  
  Future<List<RecordModel>> fetchEventsByOrganization({required String organizationId}) async {
    try {
      final result = await pb.collection('event').getFullList(
        filter: "organization_id = '$organizationId'",
        sort: '-date',
      );
      print('PocketBaseService: Fetched ${result.length} events for organization $organizationId.');
      return result;
    } catch (e) {
      print('Error fetching events by organization: $e');
      return [];
    }
  }

  Future<RecordModel?> createEvent({required Map<String, dynamic> body}) async {
    try {
      final record = await pb.collection('event').create(body: body);
      print('PocketBaseService: Event created with ID: ${record.id}');
      return record;
    } catch (e) {
      print('Error creating event: $e');
      return null;
    }
  }

  Future<List<RecordModel>> fetchEventCategories() async {
    try {
      final result = await pb.collection('event_categories').getFullList(sort: 'name');
      print('PocketBaseService: Fetched ${result.length} event categories.');
      return result;
    } catch (e) {
      print('Error fetching categories: $e');
      return [];
    }
  }

  Future<List<RecordModel>> fetchEvents({
    String? categoryId,
    String? searchQuery,
    DateTime? selectedDate,
  }) async {
    List<String> filters = ["date >= @now"];
    if (categoryId != null) {
      filters.add("categories_id = '$categoryId'");
    }
    if (searchQuery != null && searchQuery.isNotEmpty) {
      filters.add("(title ~ '$searchQuery' || description ~ '$searchQuery')");
    }
    if (selectedDate != null) {
      final dateOnly = "${selectedDate.year}-${selectedDate.month.toString().padLeft(2, '0')}-${selectedDate.day.toString().padLeft(2, '0')}";
      filters.add("date >= '$dateOnly 00:00:00' && date <= '$dateOnly 23:59:59'");
    }
    
    final filterString = filters.join(' && ');
    print('PocketBaseService: Fetching events with filter: $filterString');

    try {
      final result = await pb.collection('event').getFullList(
        sort: '+date',
        filter: filterString,
        expand: 'organization_id,categories_id',
      );
      print('PocketBaseService: Fetched ${result.length} events.');
      return result;
    } catch (e) {
      print('Error fetching events: $e');
      return [];
    }
  }

  Future<List<RecordModel>> fetchJoinedEvents({required String userId}) async {
    try {
      final result = await pb.collection('event').getFullList(
        filter: "participant_id ?~ '$userId'", 
        sort: '-date',
        expand: 'organization_id,categories_id',
      );
      print('PocketBaseService: Fetched ${result.length} joined events for user $userId.');
      return result;
    } catch (e) {
      print('Error fetching joined events: $e');
      return [];
    }
  }
  
  RecordModel? getCurrentUser() {
    final currentUser = pb.authStore.model;
    if (currentUser != null) {
      print('PocketBaseService: getCurrentUser - User ID: ${currentUser.id}, Name: ${currentUser.getStringValue('name')}, Avatar: ${currentUser.getStringValue('avatar')}');
    } else {
      print('PocketBaseService: getCurrentUser - No user authenticated.');
    }
    return currentUser;
  }

  Future<int> getEventsJoinedCount(String userId) async {
    try {
      final eventsResult = await pb.collection('event').getList(
        perPage: 1,
        filter: "participant_id ?~ '$userId'",
      );
      print('PocketBaseService: User $userId has joined ${eventsResult.totalItems} events.');
      return eventsResult.totalItems;
    } catch (e) {
      print('Error fetching joined events count: $e');
      return 0;
    }
  }

  // New method to update user profile
  Future<void> updateUserProfile({String? name, File? avatarFile}) async {
    final currentUser = pb.authStore.model;
    if (currentUser == null) {
      throw Exception("No authenticated user found.");
    }

    final body = <String, dynamic>{};
    if (name != null) {
      body['name'] = name;
      print('PocketBaseService: Attempting to update name to: $name');
    }

    List<http.MultipartFile> files = []; // Changed to http.MultipartFile
    if (avatarFile != null) {
      files.add(await http.MultipartFile.fromPath('avatar', avatarFile.path)); // Changed to http.MultipartFile.fromPath
      print('PocketBaseService: Attempting to upload new avatar from path: ${avatarFile.path}');
    }

    try {
      // Use the correct collection name for users, which is typically 'users'
      final updatedRecord = await pb.collection('users').update(currentUser.id, body: body, files: files);
      print('PocketBaseService: User profile updated successfully in PocketBase. New name: ${updatedRecord.getStringValue('name')}, New avatar filename: ${updatedRecord.getStringValue('avatar')}');
      // Refresh the auth store model after update to get the latest data
      await pb.collection('users').authRefresh();
      print('PocketBaseService: Auth store refreshed.');
    } catch (e) {
      print('PocketBaseService: FAILED to update user profile: $e');
      // Re-throw the error to be caught by the calling screen
      throw Exception("Failed to update profile: $e");
    }
  }
}
