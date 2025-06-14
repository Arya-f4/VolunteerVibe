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
      _sessions = await _pbService.fetchParticipantsForEvent(widget.event.id);
      
      List<RecordModel> waiting = [];
      List<RecordModel> accepted = [];

      for (var session in _sessions) {
        if (session.expand['users_id'] != null && session.expand['users_id']!.isNotEmpty) {
          final participant = session.expand['users_id']!.first;
          if (session.getStringValue('status') == 'waiting') {
            waiting.add(participant);
          } else if (session.getStringValue('status') == 'accepted') {
            accepted.add(participant);
          }
        }
      }

      if (mounted) {
        setState(() {
          _waitingParticipants = waiting;
          _acceptedParticipants = accepted;
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
    final session = _sessions.firstWhere(
      (s) => s.expand['users_id']?.first.id == participant.id,
      orElse: () => throw Exception('Session tidak ditemukan untuk peserta'),
    );
    
    setState(() => _isLoading = true);

    try {
      final eventPoints = widget.event.getIntValue('point_event', 0);

      await _pbService.addParticipantToEvent(widget.event.id, participant.id);
      await _pbService.updateParticipantStatus(sessionId: session.id, newStatus: 'accepted');
      await _pbService.addPointsToUser(participant.id, eventPoints);
      await _pbService.checkAndGrantAchievements(participant.id);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${participant.getStringValue('name')} diterima & mendapatkan $eventPoints poin!'), backgroundColor: Colors.green),
      );
      
      await _loadParticipants(); 
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menerima peserta: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _verifyHours(RecordModel participant) async {
    final session = _sessions.firstWhere(
      (s) => s.expand['users_id']?.first.id == participant.id && s.getStringValue('status') == 'accepted',
      orElse: () => throw Exception('Session yang diterima tidak ditemukan'),
    );

    setState(() => _isLoading = true);
    try {
      await _pbService.verifyParticipantHours(session.id);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Jam untuk ${participant.getStringValue('name')} telah diverifikasi!'), backgroundColor: Colors.blue),
      );
      await _loadParticipants();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memverifikasi jam: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if(mounted) setState(() => _isLoading = false);
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
                  _buildListSection('Waiting for Approval', _waitingParticipants, true),
                  _buildListSection('Accepted Participants', _acceptedParticipants, false),
                  SliverToBoxAdapter(child: SizedBox(height: 24)),
                ],
              ),
            ),
    );
  }

  Widget _buildListSection(String title, List<RecordModel> participants, bool isWaitingList) {
    return SliverMainAxisGroup(
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24.0, 20.0, 24.0, 8.0),
            child: Text('$title (${participants.length})', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF2D3748))),
          ),
        ),
        participants.isEmpty
            ? SliverToBoxAdapter(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
                    child: Text(
                      isWaitingList ? 'Tidak ada peserta yang menunggu persetujuan.' : 'Belum ada peserta yang diterima.',
                      style: TextStyle(color: Color(0xFF718096), fontSize: 16),
                    ),
                  ),
                ),
              )
            : SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final participant = participants[index];
                    return _buildParticipantTile(participant, isWaiting: isWaitingList);
                  },
                  childCount: participants.length,
                ),
              ),
      ],
    );
  }

  Widget _buildParticipantTile(RecordModel participant, {required bool isWaiting}) {
    String? avatarUrl = _pbService.getFileUrl(participant, participant.getStringValue('avatar'));
    
    final session = _sessions.firstWhere(
      (s) => s.expand['users_id']?.first.id == participant.id,
      orElse: () => RecordModel()
    );
    final bool isVerified = session.getBoolValue('is_verified');

    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 12.0),
        child: Row(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: Colors.grey.shade200,
              backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl) : null,
              child: avatarUrl == null ? Icon(Icons.person, color: Color(0xFF6C63FF), size: 30) : null,
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(participant.getStringValue('name', 'Unknown User'), style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF2D3748))),
                  SizedBox(height: 4),
                  Text(participant.getStringValue('email', 'No Email'), style: TextStyle(fontSize: 13, color: Color(0xFF718096))),
                ],
              ),
            ),
            SizedBox(width: 8),
            if (isWaiting)
              ElevatedButton(
                onPressed: () => _acceptParticipant(participant),
                style: ElevatedButton.styleFrom(backgroundColor: Color(0xFF38A169), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                child: Text('Accept'),
              )
            else if (!isWaiting && !isVerified)
              ElevatedButton(
                onPressed: () => _verifyHours(participant),
                style: ElevatedButton.styleFrom(backgroundColor: Color(0xFF4299E1), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                child: Text('Verify'),
              )
            else
              Chip(
                avatar: Icon(Icons.check_circle, color: Colors.white, size: 18),
                label: Text('Verified'),
                backgroundColor: Color(0xFF38A169),
                labelStyle: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                padding: EdgeInsets.symmetric(horizontal: 8),
              ),
          ],
        ),
      ),
    );
  }
}