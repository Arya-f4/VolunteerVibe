// File: lib/services/pocketbase_service.dart

import 'dart:io'; 
import 'package:pocketbase/pocketbase.dart';
import 'package:volunteervibe/pocketbase_client.dart';
import 'package:http/http.dart' show MultipartFile;

class PocketBaseService {
  
  void logout() {
    pb.authStore.clear();
  }
  
  String? getFileUrl(RecordModel record, String filename) {
    if (filename.isEmpty) {
      return null;
    }
    return pb.getFileUrl(record, filename).toString();
  }

  Future<RecordModel?> getMyOrganization() async {
    final user = getCurrentUser();
    // Cek jika user yang login adalah dari koleksi 'organization'
    if (user != null && user.collectionName == 'organization') {
      return user;
    }
    // Jika dari koleksi 'users', coba cari relasinya (logika lama, bisa disesuaikan)
    if (user != null && user.collectionName == 'users' && user.getStringValue('organization_id').isNotEmpty) {
        try {
        final userWithOrg = await pb.collection('users').getOne(user.id, expand: 'organization_id');
        return userWithOrg.expand['organization_id']?.first;
      } catch (e) {
        print('Error fetching my organization from user relation: $e');
        return null;
      }
    }
    return null;
  }
  
  Future<List<RecordModel>> fetchEventsByOrganization({required String organizationId}) async {
    try {
      final result = await pb.collection('event').getFullList(
        filter: "organization_id = '$organizationId'",
        sort: '-date',
      );
      return result;
    } catch (e) {
      print('Error fetching events by organization: $e');
      return [];
    }
  }

  Future<RecordModel?> createEvent({required Map<String, dynamic> body}) async {
    try {
      final record = await pb.collection('event').create(body: body);
      return record;
    } catch (e) {
      print('Error creating event: $e');
      return null;
    }
  }

  Future<List<RecordModel>> fetchEventCategories() async {
    try {
      final result = await pb.collection('event_categories').getFullList(sort: 'name');
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

    try {
      final result = await pb.collection('event').getFullList(
        sort: '+date',
        filter: filterString,
        expand: 'organization_id,categories_id',
      );
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
      return result;
    } catch (e) {
      print('Error fetching joined events: $e');
      return [];
    }
  }
  
  RecordModel? getCurrentUser() {
    return pb.authStore.model;
  }

  Future<int> getEventsJoinedCount(String userId) async {
    try {
      final eventsResult = await pb.collection('event').getList(
        perPage: 1,
        filter: "participant_id ?~ '$userId'",
      );
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
    }

    List<MultipartFile> files = [];
    if (avatarFile != null) {
      files.add(await MultipartFile.fromPath('avatar', avatarFile.path));
    }

    try {
      // Use the correct collection name for users, which is typically 'users'
      await pb.collection('users').update(currentUser.id, body: body, files: files);
      // Refresh the auth store model after update to get the latest data
      await pb.collection('users').authRefresh();
    } catch (e) {
      // Re-throw the error to be caught by the calling screen
      throw Exception("Failed to update profile: $e");
    }
  }
}