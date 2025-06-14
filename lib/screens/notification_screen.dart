// lib/notification_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:volunteervibe/services/pocketbase_service.dart';

class NotificationScreen extends StatefulWidget {
  @override
  _NotificationScreenState createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  final PocketBaseService _pbService = PocketBaseService();
  
  bool _isLoading = true;
  List<RecordModel> _notifications = [];

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  // Fungsi untuk memuat notifikasi dari PocketBase
  Future<void> _loadNotifications() async {
    if (!mounted) return;
    setState(() => _isLoading = true);

    try {
      final notifications = await _pbService.fetchNotifications();
      if (mounted) {
        setState(() {
          _notifications = notifications;
        });
      }
    } catch (e) {
      print("Failed to load notifications: $e");
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  // Fungsi saat notifikasi diklik (tandai sudah dibaca)
  Future<void> _onNotificationTap(RecordModel notification) async {
    // Jika sudah dibaca, tidak perlu melakukan apa-apa
    if (notification.getBoolValue('read')) return;

    try {
      await _pbService.markNotificationAsRead(notification.id);
      if (mounted) {
        setState(() {
          // Perbarui state secara lokal untuk respons instan
          notification.data['read'] = true;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menandai notifikasi: ${e.toString()}')),
      );
    }
  }

  // Fungsi untuk menghapus notifikasi
  Future<void> _onDeleteTap(String notificationId, int index) async {
    // Tampilkan dialog konfirmasi
    final bool? confirmDelete = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Hapus Notifikasi?'),
        content: Text('Apakah Anda yakin ingin menghapus notifikasi ini secara permanen?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('Hapus', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmDelete == true) {
      try {
        await _pbService.deleteNotification(notificationId);
        if (mounted) {
          setState(() {
            // Hapus dari daftar secara lokal untuk respons instan
            _notifications.removeAt(index);
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Notifikasi berhasil dihapus.')),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menghapus notifikasi: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF8FAFC),
      appBar: _buildAppBar(),
      body: RefreshIndicator(
        onRefresh: _loadNotifications,
        color: Color(0xFF6366F1),
        child: _buildBody(),
      ),
    );
  }

  AppBar _buildAppBar() {
    return AppBar(
      title: Text(
        'Notifications',
        style: TextStyle(color: Color(0xFF1E293B), fontWeight: FontWeight.bold, fontSize: 22),
      ),
      backgroundColor: Colors.white,
      elevation: 1.0,
      shadowColor: Colors.black.withOpacity(0.05),
      centerTitle: true,
      leading: IconButton(
        icon: Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF374151)),
        onPressed: () => Navigator.of(context).pop(),
      ),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return Center(child: CircularProgressIndicator(color: Color(0xFF6366F1)));
    }

    if (_notifications.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.builder(
      padding: EdgeInsets.symmetric(vertical: 16, horizontal: 16),
      itemCount: _notifications.length,
      itemBuilder: (context, index) {
        final notification = _notifications[index];
        return _buildNotificationCard(notification, index);
      },
    );
  }

  Widget _buildNotificationCard(RecordModel notification, int index) {
    final eventName = notification.expand['event_id']?.first.data['title'] ?? 'acara yang tidak diketahui';
    final isRead = notification.getBoolValue('read');
    final createdDate = DateTime.parse(notification.created);
    final timeAgo = _formatTimeAgo(createdDate);

    return Card(
      margin: EdgeInsets.only(bottom: 16),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: isRead ? Colors.grey.shade200 : Color(0xFF6366F1).withOpacity(0.5), width: 1),
      ),
      color: isRead ? Colors.white : Color(0xFFF1F5F9),
      child: InkWell(
        onTap: () => _onNotificationTap(notification),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Color(0xFF10B981).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 24),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Pendaftaran Diterima',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF1E293B)),
                    ),
                    SizedBox(height: 4),
                    Text.rich(
                      TextSpan(
                        style: TextStyle(color: Color(0xFF64748B), fontSize: 14, height: 1.4),
                        children: [
                          TextSpan(text: 'Selamat! Anda telah diterima di acara: '),
                          TextSpan(
                            text: eventName,
                            style: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF374151)),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      timeAgo,
                      style: TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
                    ),
                  ],
                ),
              ),
              if (!isRead)
                Container(
                  margin: EdgeInsets.only(left: 8),
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(color: Color(0xFF6366F1), shape: BoxShape.circle),
                ),
              IconButton(
                icon: Icon(Icons.delete_outline_rounded, color: Colors.red.shade400, size: 22),
                onPressed: () => _onDeleteTap(notification.id, index),
                visualDensity: VisualDensity.compact,
                padding: EdgeInsets.zero,
              ),
            ],
          ),
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
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Color(0xFF6366F1).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Icon(Icons.notifications_off_rounded, size: 40, color: Color(0xFF6366F1)),
                  ),
                  SizedBox(height: 24),
                  Text('Tidak Ada Notifikasi', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF1E293B))),
                  SizedBox(height: 8),
                  Text(
                    "Saat ini tidak ada notifikasi baru untuk Anda. Tarik ke bawah untuk memuat ulang.",
                    style: TextStyle(color: Color(0xFF64748B), fontSize: 16, height: 1.5),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    });
  }

  // Helper untuk format waktu
  String _formatTimeAgo(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inSeconds < 60) {
      return '${difference.inSeconds} detik lalu';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} menit lalu';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} jam lalu';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} hari lalu';
    } else {
      return DateFormat('d MMM yyyy').format(date);
    }
  }
}