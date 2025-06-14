import 'package:flutter/material.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:volunteervibe/services/pocketbase_service.dart';

class EventParticipantsScreen extends StatefulWidget {
  final RecordModel event;

  const EventParticipantsScreen({Key? key, required this.event}) : super(key: key);

  @override
  _EventParticipantsScreenState createState() => _EventParticipantsScreenState();
}

class _EventParticipantsScreenState extends State<EventParticipantsScreen> {
  final PocketBaseService _pbService = PocketBaseService();
  bool _isLoading = true;
  List<RecordModel> _sessions = [];
  List<RecordModel> _waitingParticipants = [];
  List<RecordModel> _acceptedParticipants = [];

  @override
  void initState() {
    super.initState();
    _loadParticipants();
  }

  Future<void> _loadParticipants() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      // Ambil semua session yang terkait dengan event ini
      _sessions = await _pbService.fetchParticipantsForEvent(widget.event.id);
      
      List<RecordModel> waiting = [];
      // Pisahkan user yang berstatus 'waiting' dari data session
      for (var session in _sessions) {
        if (session.getStringValue('status') == 'waiting' &&
            session.expand['users_id'] != null &&
            session.expand['users_id']!.isNotEmpty) {
          waiting.add(session.expand['users_id']!.first);
        }
      }

      // Ambil data event terbaru untuk mendapatkan daftar peserta yang sudah diterima
      final latestEvent = await _pbService.fetchEventById(widget.event.id);
      if (latestEvent == null) throw Exception('Gagal memuat detail event terbaru.');
      
      // Ambil user dari daftar 'participant_id' di event
      final acceptedIds = latestEvent.getListValue<String>('participant_id');
      final acceptedList = acceptedIds.isNotEmpty
          ? await _pbService.fetchUsersByIds(acceptedIds)
          : <RecordModel>[];

      if (mounted) {
        setState(() {
          _waitingParticipants = waiting;
          _acceptedParticipants = acceptedList;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memuat peserta: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _acceptParticipant(RecordModel participant) async {
    // Cari session ID yang sesuai dari daftar session yang sudah kita simpan
    final session = _sessions.firstWhere(
      (s) => s.expand['users_id']?.first.id == participant.id,
      orElse: () => throw Exception('Session tidak ditemukan untuk peserta'),
    );
    
    setState(() => _isLoading = true);

    try {
      // Ambil jumlah poin dari event ini
      final eventPoints = widget.event.getIntValue('point_event', 0);

      // Aksi 1: Tambahkan ID user ke dalam daftar participant_id di event
      await _pbService.addParticipantToEvent(widget.event.id, participant.id);

      // Aksi 2: Ubah status di record event_session menjadi 'accepted'
      await _pbService.updateParticipantStatus(
        sessionId: session.id,
        newStatus: 'accepted',
      );
      
      // Aksi 3: Tambahkan poin ke user
      await _pbService.addPointsToUser(participant.id, eventPoints);
      
      // Aksi 4: Panggil fungsi pengecekan achievement untuk user yang baru diterima
      await _pbService.checkAndGrantAchievements(participant.id);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${participant.getStringValue('name')} diterima & mendapatkan $eventPoints poin!'), backgroundColor: Colors.green),
      );
      
      // Muat ulang seluruh daftar untuk menampilkan perubahan
      await _loadParticipants(); 
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menerima peserta: $e'), backgroundColor: Colors.red),
      );
    } finally {
      // Pastikan loading indicator hilang meskipun ada error
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Participants - ${widget.event.getStringValue('title')}'),
        backgroundColor: Color(0xFF6C63FF),
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: Color(0xFF6C63FF)))
          : RefreshIndicator(
              onRefresh: _loadParticipants,
              color: Color(0xFF6C63FF),
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24.0, 16.0, 24.0, 8.0),
                      child: Text(
                        'Waiting for Approval (${_waitingParticipants.length})',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2D3748),
                        ),
                      ),
                    ),
                  ),
                  _waitingParticipants.isEmpty
                      ? SliverToBoxAdapter(
                          child: Center(
                            child: Padding(
                              padding: const EdgeInsets.all(24.0),
                              child: Text('Tidak ada peserta yang menunggu.', style: TextStyle(color: Color(0xFF718096))),
                            ),
                          ),
                        )
                      : SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final participant = _waitingParticipants[index];
                              return _buildParticipantTile(participant, isWaiting: true);
                            },
                            childCount: _waitingParticipants.length,
                          ),
                        ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(24.0, 24.0, 24.0, 8.0),
                      child: Text(
                        'Accepted Participants (${_acceptedParticipants.length})',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF2D3748),
                        ),
                      ),
                    ),
                  ),
                  _acceptedParticipants.isEmpty
                      ? SliverToBoxAdapter(
                          child: Center(
                            child: Padding(
                              padding: const EdgeInsets.all(24.0),
                              child: Text('Belum ada peserta yang diterima.', style: TextStyle(color: Color(0xFF718096))),
                            ),
                          ),
                        )
                      : SliverList(
                          delegate: SliverChildBuilderDelegate(
                            (context, index) {
                              final participant = _acceptedParticipants[index];
                              return _buildParticipantTile(participant, isWaiting: false);
                            },
                            childCount: _acceptedParticipants.length,
                          ),
                        ),
                  SliverToBoxAdapter(child: SizedBox(height: 24)),
                ],
              ),
            ),
    );
  }

  Widget _buildParticipantTile(RecordModel participant, {required bool isWaiting}) {
    String? avatarUrl = _pbService.getFileUrl(participant, participant.getStringValue('avatar'));

    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: Colors.grey.shade200,
              backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
              child: avatarUrl == null
                  ? Icon(Icons.person, color: Color(0xFF6C63FF), size: 30)
                  : null,
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    participant.getStringValue('name', 'Unknown User'),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Color(0xFF2D3748),
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    participant.getStringValue('email', 'No Email'),
                    style: TextStyle(
                      fontSize: 13,
                      color: Color(0xFF718096),
                    ),
                  ),
                ],
              ),
            ),
            if (isWaiting) ...[
              SizedBox(width: 8),
              ElevatedButton(
                onPressed: () => _acceptParticipant(participant),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF38A169),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
                child: Text('Accept'),
              ),
            ]
          ],
        ),
      ),
    );
  }
}