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
    return url;
  }

  Future<RecordModel?> getMyOrganization() async {
    final user = getCurrentUser();
    if (user != null && user.collectionName == 'organization') {
      print('PocketBaseService: Current user is an organization.');
      return user;
    }
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
      print('PocketBaseService: getCurrentUser - User ID: ${currentUser.id}, Name: ${currentUser.getStringValue('name')}, Email: ${currentUser.getStringValue('email')}, Avatar: ${currentUser.getStringValue('avatar')}');
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

  Future<void> updateUserProfile({String? name, String? email, File? avatarFile}) async {
    final currentUser = pb.authStore.model;
    if (currentUser == null) {
      throw Exception("No authenticated user found.");
    }

    final body = <String, dynamic>{};
    if (name != null) {
      body['name'] = name;
      print('PocketBaseService: Attempting to update name to: $name');
    }
    if (email != null) {
      body['email'] = email;
      print('PocketBaseService: Attempting to update email to: $email');
    }

    List<http.MultipartFile> files = [];
    if (avatarFile != null) {
      files.add(await http.MultipartFile.fromPath('avatar', avatarFile.path));
      print('PocketBaseService: Attempting to upload new avatar from path: ${avatarFile.path}');
    }

    try {
      final updatedRecord = await pb.collection('users').update(currentUser.id, body: body, files: files);
      print('PocketBaseService: User profile updated successfully in PocketBase. New name: ${updatedRecord.getStringValue('name')}, New email: ${updatedRecord.getStringValue('email')}, New avatar filename: ${updatedRecord.getStringValue('avatar')}');
      await pb.collection('users').authRefresh();
    } catch (e) {
      print('PocketBaseService: FAILED to update user profile: $e');
      throw Exception("Failed to update profile: $e");
    }
  }

  Future<int> getUserSharedCount() async {
    final currentUser = pb.authStore.model;
    if (currentUser == null) {
      print('PocketBaseService: No authenticated user to get shared count.');
      return 0;
    }
    try {
      final userRecord = await pb.collection('users').getOne(currentUser.id);
      return userRecord.getIntValue('count_shared', 0);
    } catch (e) {
      print('PocketBaseService: Error getting user shared count: $e');
      return 0;
    }
  }

  Future<void> incrementUserSharedCount() async {
    final currentUser = pb.authStore.model;
    if (currentUser == null) {
      print('PocketBaseService: No authenticated user to increment shared count.');
      return;
    }
    try {
      final currentCount = currentUser.getIntValue('count_shared', 0);
      final newCount = currentCount + 1;
      await pb.collection('users').update(currentUser.id, body: {'count_shared': newCount});
      await pb.collection('users').authRefresh();
      print('PocketBaseService: User shared count incremented to: $newCount');
    } catch (e) {
      print('PocketBaseService: Failed to increment user shared count: $e');
    }
  }

  // Updated: Method to update an event
  Future<RecordModel?> updateEvent(String eventId, Map<String, dynamic> body) async {
    try {
      final record = await pb.collection('event').update(eventId, body: body);
      print('PocketBaseService: Event updated with ID: ${record.id}');
      return record;
    } catch (e) {
      print('Error updating event: $e');
      return null;
    }
  }

  // Updated: Method to delete an event
  Future<void> deleteEvent(String eventId) async {
    try {
      await pb.collection('event').delete(eventId);
      print('PocketBaseService: Event deleted with ID: $eventId');
    } catch (e) {
      print('Error deleting event: $e');
      throw Exception('Failed to delete event: $e');
    }
  }

  Future<RecordModel?> fetchUserById(String userId) async {
  try {
    return await pb.collection('users').getOne(userId);
  } catch (e) {
    print('Error fetching user $userId: $e');
    return null;
  }
  }

 // NEW: Update event's participant lists
  Future<void> updateEventParticipants({
    required String eventId,
    List<String>? participantsWaiting,
    List<String>? participantsAccepted,
  }) async {
    try {
      final body = <String, dynamic>{};
      if (participantsWaiting != null) {
        body['participants_waiting'] = participantsWaiting;
      }
      if (participantsAccepted != null) {
        body['participants_accepted'] = participantsAccepted;
      }
      await pb.collection('event').update(eventId, body: body);
      print('PocketBaseService: Updated participants for event $eventId');
    } catch (e) {
      print('Error updating event participants: $e');
      throw Exception('Failed to update event participants: $e');
    }
  }

  // NEW: Fetch a single event by ID with expansions
  Future<RecordModel?> fetchEventById(String eventId) async {
    try {
      return await pb.collection('event').getOne(
        eventId,
        expand: 'participants_waiting,participants_accepted,organization_id,categories_id', // Ensure expansions
      );
    } catch (e) {
      print('Error fetching event $eventId: $e');
      return null;
    }
  }

  Future<List<RecordModel>> fetchUsersByIds(List<String> userIds) async {
    if (userIds.isEmpty) return [];
    try {
      // Create a filter string for multiple IDs
      final filterString = userIds.map((id) => 'id = "$id"').join(' || ');
      final records = await pb.collection('users').getFullList(
        filter: filterString,
      );
      print('PocketBaseService: Fetched ${records.length} users for IDs: $userIds');
      return records;
    } catch (e) {
      print('Error fetching users by IDs: $e');
      return [];
    }
  }

   Future<List<RecordModel>> fetchNotifications() async {
    final user = getCurrentUser();
    if (user == null) {
      print('PocketBaseService: Cannot fetch notifications, user is null.');
      return [];
    }

    try {
      // Filter: user_id cocok & status adalah 'accepted'
      // Expand: untuk mendapatkan detail dari event_id
      final result = await pb.collection('event_session').getFullList(
        filter: "users_id = '${user.id}' && status = 'accepted'",
        sort: '-created', // Tampilkan yang terbaru di atas
        expand: 'event_id',
      );
      print('PocketBaseService: Fetched ${result.length} notifications for user ${user.id}.');
      return result;
    } catch (e) {
      print('Error fetching notifications: $e');
      return [];
    }
  }

  // [BARU] Menandai notifikasi sebagai sudah dibaca
  Future<void> markNotificationAsRead(String notificationId) async {
    try {
      await pb.collection('event_session').update(notificationId, body: {'read': true});
      print('PocketBaseService: Marked notification $notificationId as read.');
    } catch (e) {
      print('Error marking notification as read: $e');
      throw Exception('Failed to update notification');
    }
  }

  // [BARU] Menghapus notifikasi
  Future<void> deleteNotification(String notificationId) async {
    try {
      await pb.collection('event_session').delete(notificationId);
      print('PocketBaseService: Deleted notification $notificationId.');
    } catch (e) {
      print('Error deleting notification: $e');
      throw Exception('Failed to delete notification');
    }
  }

   Future<int> getUnreadNotificationCount() async {
    final user = getCurrentUser();
    if (user == null) {
      return 0; // Tidak ada pengguna, tidak ada notifikasi
    }

    try {
      // Filter untuk notifikasi yang belum dibaca (read = false) & status accepted
      final filterString = "users_id = '${user.id}' && status = 'accepted' && read = false";
      
      // Kita hanya butuh jumlahnya, jadi kita ambil 1 halaman dengan 1 item per halaman.
      // PocketBase akan tetap mengembalikan totalItems yang cocok dengan filter.
      final result = await pb.collection('event_session').getList(
        perPage: 1, 
        filter: filterString,
      );

      print('PocketBaseService: Found ${result.totalItems} unread notifications for user ${user.id}.');
      return result.totalItems;
    } catch (e) {
      print('Error fetching unread notification count: $e');
      return 0;
    }
  }

  Future<List<RecordModel>> fetchParticipantsForEvent(String eventId) async {
    try {
      final records = await pb.collection('event_session').getFullList(
        filter: 'event_id = "$eventId"',
        expand: 'users_id', // Penting: untuk mendapatkan detail user
      );
      print('PocketBaseService: Fetched ${records.length} participants for event $eventId');
      return records;
    } catch (e) {
      print('Error fetching participants for event: $e');
      return [];
    }
  }

  // [BARU] Mengubah status peserta di event_session
  Future<void> updateParticipantStatus({
    required String sessionId,
    required String newStatus,
  }) async {
    try {
      await pb.collection('event_session').update(sessionId, body: {
        'status': newStatus,
      });
      print('PocketBaseService: Updated status for session $sessionId to $newStatus');
    } catch (e) {
      print('Error updating participant status: $e');
      throw Exception('Failed to update participant status');
    }
  }

  Future<void> addParticipantToEvent(String eventId, String userIdToAdd) async {
    try {
      // Pertama, ambil data event yang ada untuk mendapatkan daftar participant_id saat ini
      final event = await pb.collection('event').getOne(eventId);
      final currentParticipantIds = List<String>.from(event.getListValue<String>('participant_id'));

      // Tambahkan ID baru jika belum ada untuk menghindari duplikat
      if (!currentParticipantIds.contains(userIdToAdd)) {
        currentParticipantIds.add(userIdToAdd);
      }

      // Update event dengan daftar participant_id yang baru
      await pb.collection('event').update(eventId, body: {
        'participant_id': currentParticipantIds,
      });

      print('PocketBaseService: Added user $userIdToAdd to event $eventId');
    } catch (e) {
      print('Error adding participant to event: $e');
      throw Exception('Failed to add participant to event');
    }
  }

   Future<void> createEventSession({
    required String eventId,
    required String userId,
  }) async {
    try {
      await pb.collection('event_session').create(body: {
        'event_id': eventId,
        'users_id': userId,
        'status': 'waiting',
        'read': false, // Default value saat dibuat
      });
      print('PocketBaseService: Created event session for user $userId, event $eventId.');
    } catch (e) {
      print('Error creating event session: $e');
      throw Exception('Failed to create event session');
    }
  }

  // [BARU] Memeriksa apakah user sudah terdaftar atau sudah mengirim permintaan
  Future<Map<String, String?>> checkUserRegistrationStatus(String eventId, String userId) async {
    try {
      // Cek di event_session terlebih dahulu
      final sessionRecords = await pb.collection('event_session').getFullList(
        filter: 'event_id = "$eventId" && users_id = "$userId"',
      );

      if (sessionRecords.isNotEmpty) {
        // Jika ada record, kembalikan statusnya ('waiting' atau 'accepted')
        return {'status': sessionRecords.first.getStringValue('status')};
      }
      
      // Jika tidak ada di session, kembalikan null
      return {'status': null};

    } catch (e) {
      print('Error checking registration status: $e');
      return {'status': null}; // Anggap belum terdaftar jika ada error
    }
  }


}