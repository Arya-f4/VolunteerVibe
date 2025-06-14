import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:volunteervibe/pocketbase_client.dart'; // Pastikan path ini benar
import 'package:volunteervibe/services/pocketbase_service.dart';

// Class generik untuk menyatukan berbagai jenis notifikasi
class NotificationData {
  final String id;
  final String type; // 'session' atau 'reminder'
  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconColor;
  final DateTime createdAt;
  bool isRead;

  NotificationData({
    required this.id,
    required this.type,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
    required this.createdAt,
    required this.isRead,
  });
}

class NotificationScreen extends StatefulWidget {
  @override
  _NotificationScreenState createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  final PocketBaseService _pbService = PocketBaseService();
  bool _isLoading = true;
  List<NotificationData> _notifications = [];

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  /// Memuat semua notifikasi dan menjalankan logika pembuatan reminder
  Future<void> _loadNotifications() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      await _createRemindersBasedOnUserLogic();

      final userId = _pbService.getCurrentUser()?.id;
      if (userId == null) {
        if (mounted) setState(() => _notifications = []);
        return;
      }

      final results = await Future.wait([
        _pbService.fetchNotifications(),
        _pbService.fetchEventReminders(userId),
      ]);

      final sessions = results[0];
      final reminders = results[1];
      List<NotificationData> combinedList = [];

      for (var record in sessions) {
        final eventName = record.expand['event_id']?.first.data['title'] ?? 'acara';
        combinedList.add(NotificationData(
          id: record.id, type: 'session', title: 'Pendaftaran Diterima',
          subtitle: 'Selamat! Anda telah diterima di acara: $eventName.',
          icon: Icons.check_circle_rounded, iconColor: Colors.green,
          createdAt: DateTime.parse(record.created), isRead: record.getBoolValue('read'),
        ));
      }

      for (var record in reminders) {
        final eventName = record.expand['event_id']?.first.data['title'] ?? 'acara';
        combinedList.add(NotificationData(
          id: record.id, type: 'reminder', title: 'Pengingat Acara',
          subtitle: 'Jangan lupa, acara "$eventName" akan dimulai besok!',
          icon: Icons.schedule_rounded, iconColor: Colors.orange,
          createdAt: DateTime.parse(record.created), isRead: record.getBoolValue('read'),
        ));
      }

      combinedList.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      if (mounted) setState(() => _notifications = combinedList);

    } catch (e) {
      print("Failed to load notifications: $e");
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  /// Implementasi langsung dari logika "selisih 1 hari"
  Future<void> _createRemindersBasedOnUserLogic() async {
    print("Mengecek acara H-1 untuk membuat pengingat...");
    try {
      final allFutureEvents = await pb.collection('event').getFullList(filter: 'date >= @now');

      for (final event in allFutureEvents) {
        final eventDate = DateTime.parse(event.getStringValue('date'));

        if (_isEventTomorrow(eventDate)) {
          
          // --- [PERBAIKAN] ---
          // Menggunakan getList (bukan getFullList) dan memeriksa 'items'
          final existingReminders = await pb.collection('event_reminder').getList(
            filter: 'event_id = "${event.id}"', perPage: 1
          );

          // Kondisi diubah menjadi .items.isEmpty karena getList mengembalikan object ResultList
          if (existingReminders.items.isEmpty) {
          // --- [AKHIR PERBAIKAN] ---
            
            final participantIds = event.getListValue<String>('participant_id');
            if (participantIds.isNotEmpty) {
              await pb.collection('event_reminder').create(body: {
                "event_id": event.id,
                "users_id": participantIds,
                "read": false,
              });
              print('Pengingat dibuat untuk acara: ${event.getStringValue('title')}');
            }
          }
        }
      }
    } catch (e) {
      print("Gagal saat mencoba membuat reminder: $e");
    }
  }

  /// Helper function untuk logika "apakah selisihnya 1 hari?".
  bool _isEventTomorrow(DateTime eventDate) {
    final now = DateTime.now();
    final todayAtMidnight = DateTime(now.year, now.month, now.day);
    final eventDateAtMidnight = DateTime(eventDate.year, eventDate.month, eventDate.day);
    final difference = eventDateAtMidnight.difference(todayAtMidnight);
    return difference.inDays == 1;
  }
  
  // ... sisa kode lainnya tidak berubah ...
  Future<void> _onNotificationTap(NotificationData notification) async {
    if (notification.isRead) return;
    try {
      if (notification.type == 'session') {
        await _pbService.markNotificationAsRead(notification.id);
      } else if (notification.type == 'reminder') {
        await _pbService.markReminderAsRead(notification.id);
      }
      if (mounted) setState(() => notification.isRead = true);
    } catch (e) {
       ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal: ${e.toString()}')));
    }
  }

  Future<void> _onDeleteTap(NotificationData notification, int index) async {
     final bool? confirmDelete = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Hapus Notifikasi?'),
        content: Text('Anda yakin ingin menghapus notifikasi ini?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: Text('Batal')),
          TextButton(onPressed: () => Navigator.of(context).pop(true), child: Text('Hapus', style: TextStyle(color: Colors.red))),
        ],
      ),
    );
    if (confirmDelete == true) {
      try {
        if (notification.type == 'session') {
          await _pbService.deleteNotification(notification.id);
        } else if (notification.type == 'reminder') {
          await _pbService.deleteReminder(notification.id);
        }
        if (mounted) setState(() => _notifications.removeAt(index));
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal menghapus: ${e.toString()}')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF8FAFC),
      appBar: AppBar(
        title: Text('Notifications', style: TextStyle(color: Color(0xFF1E293B), fontWeight: FontWeight.bold, fontSize: 22)),
        backgroundColor: Colors.white, elevation: 1.0, centerTitle: true,
        leading: IconButton(icon: Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF374151)), onPressed: () => Navigator.of(context).pop()),
      ),
      body: RefreshIndicator(onRefresh: _loadNotifications, color: Color(0xFF6366F1), child: _buildBody()),
    );
  }

  Widget _buildBody() {
    if (_isLoading) return Center(child: CircularProgressIndicator(color: Color(0xFF6366F1)));
    if (_notifications.isEmpty) return _buildEmptyState();
    return ListView.builder(
      padding: EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      itemCount: _notifications.length,
      itemBuilder: (context, index) => _buildNotificationCard(_notifications[index], index),
    );
  }

  Widget _buildNotificationCard(NotificationData item, int index) {
    final timeAgo = _formatTimeAgo(item.createdAt);
    return Card(
      margin: EdgeInsets.only(bottom: 16), elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: item.isRead ? Colors.grey.shade200 : item.iconColor.withOpacity(0.7), width: 1)),
      color: item.isRead ? Colors.white : Color(0xFFF1F5F9),
      child: InkWell(
        onTap: () => _onNotificationTap(item), borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(width: 48, height: 48, decoration: BoxDecoration(color: item.iconColor.withOpacity(0.1), borderRadius: BorderRadius.circular(12)), child: Icon(item.icon, color: item.iconColor, size: 24)),
            SizedBox(width: 16),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(item.title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1E293B))),
              SizedBox(height: 4),
              Text(item.subtitle, style: TextStyle(color: Color(0xFF64748B), fontSize: 14, height: 1.4)),
              SizedBox(height: 8),
              Text(timeAgo, style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8))),
            ])),
            Column(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              if (!item.isRead) Container(margin: EdgeInsets.only(left: 8, bottom: 8), width: 8, height: 8, decoration: BoxDecoration(color: Color(0xFF6366F1), shape: BoxShape.circle)),
              IconButton(icon: Icon(Icons.delete_outline_rounded, color: Colors.red.shade400, size: 22), onPressed: () => _onDeleteTap(item, index), visualDensity: VisualDensity.compact, padding: EdgeInsets.zero),
            ]),
          ]),
        ),
      ),
    );
  }
  
  Widget _buildEmptyState() {
     return LayoutBuilder(builder: (context, constraints) {
      return SingleChildScrollView(
        physics: AlwaysScrollableScrollPhysics(),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                Container(width: 80, height: 80, decoration: BoxDecoration(color: Color(0xFF6366F1).withOpacity(0.1), borderRadius: BorderRadius.circular(20)), child: Icon(Icons.notifications_off_rounded, size: 40, color: Color(0xFF6366F1))),
                SizedBox(height: 24),
                Text('Tidak Ada Notifikasi', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                SizedBox(height: 8),
                Text("Saat ini tidak ada notifikasi baru untuk Anda.", style: TextStyle(color: Color(0xFF64748B), fontSize: 16, height: 1.5), textAlign: TextAlign.center),
              ]),
            ),
          ),
        ),
      );
    });
  }

  String _formatTimeAgo(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);
    if (difference.inSeconds < 60) return '${difference.inSeconds} detik lalu';
    if (difference.inMinutes < 60) return '${difference.inMinutes} menit lalu';
    if (difference.inHours < 24) return '${difference.inHours} jam lalu';
    if (difference.inDays < 7) return '${difference.inDays} hari lalu';
    return DateFormat('d MMM yy').format(date);
  }
}