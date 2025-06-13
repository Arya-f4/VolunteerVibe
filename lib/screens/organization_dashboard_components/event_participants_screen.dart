import 'package:flutter/material.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:volunteervibe/services/pocketbase_service.dart';

class EventParticipantsScreen extends StatefulWidget {
  final RecordModel event; // Pass the full event record

  const EventParticipantsScreen({Key? key, required this.event}) : super(key: key);

  @override
  _EventParticipantsScreenState createState() => _EventParticipantsScreenState();
}

class _EventParticipantsScreenState extends State<EventParticipantsScreen> {
  final PocketBaseService _pbService = PocketBaseService();
  bool _isLoading = true;
  RecordModel? _currentEvent; // To store the latest event data
  List<RecordModel> _waitingParticipants = [];
  List<RecordModel> _acceptedParticipants = [];

  @override
  void initState() {
    super.initState();
    _currentEvent = widget.event; // Initialize with the passed event
    _loadParticipants();
  }

  Future<void> _loadParticipants() async {
    setState(() => _isLoading = true);
    try {
      // Fetch the latest event data to ensure we have updated participant lists
      final updatedEvent = await _pbService.fetchEventById(widget.event.id);
      if (updatedEvent == null) {
        throw Exception('Event not found or failed to load latest data.');
      }
      _currentEvent = updatedEvent; // Update the current event state

      final waitingIds = _currentEvent!.getListValue<String>('participants_waiting');
      final acceptedIds = _currentEvent!.getListValue<String>('participants_accepted');

      List<Future<RecordModel>> waitingFutures = [];
      for (var id in waitingIds) {
        // Fetch users from the 'users' collection
        waitingFutures.add(_pbService.fetchUsersByIds([id]).then((list) => list.first));
      }

      List<Future<RecordModel>> acceptedFutures = [];
      for (var id in acceptedIds) {
        // Fetch users from the 'users' collection
        acceptedFutures.add(_pbService.fetchUsersByIds([id]).then((list) => list.first));
      }
      
      final loadedWaiting = await Future.wait(waitingFutures.toList());
      final loadedAccepted = await Future.wait(acceptedFutures.toList());

      setState(() {
        _waitingParticipants = loadedWaiting.whereType<RecordModel>().toList();
        _acceptedParticipants = loadedAccepted.whereType<RecordModel>().toList();
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load participants: $e'), backgroundColor: Colors.red),
      );
      print('Error loading participants: $e'); // Add a print for detailed error
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _acceptParticipant(String userId) async {
    if (_currentEvent == null) return;

    // Remove from waiting list
    final updatedWaiting = List<String>.from(_currentEvent!.getListValue<String>('participants_waiting'));
    updatedWaiting.remove(userId);

    // Add to accepted list
    final updatedAccepted = List<String>.from(_currentEvent!.getListValue<String>('participants_accepted'));
    if (!updatedAccepted.contains(userId)) { // Prevent duplicates
      updatedAccepted.add(userId);
    }

    try {
      await _pbService.updateEventParticipants(
        eventId: _currentEvent!.id,
        participantsWaiting: updatedWaiting,
        participantsAccepted: updatedAccepted,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Participant accepted!'), backgroundColor: Colors.green),
      );
      _loadParticipants(); // Reload lists after update
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to accept participant: $e'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Participants - ${_currentEvent?.getStringValue('title') ?? 'Loading...'}'),
        backgroundColor: Color(0xFF6C63FF),
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: Color(0xFF6C63FF)))
          : RefreshIndicator(
              onRefresh: _loadParticipants, // Enable pull-to-refresh
              color: Color(0xFF6C63FF),
              child: CustomScrollView(
                slivers: [
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
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
                              child: Text('No participants waiting.', style: TextStyle(color: Color(0xFF718096))),
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
                      padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
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
                              child: Text('No accepted participants yet.', style: TextStyle(color: Color(0xFF718096))),
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
                  SliverToBoxAdapter(child: SizedBox(height: 24)), // Padding at the bottom
                ],
              ),
            ),
    );
  }

  Widget _buildParticipantTile(RecordModel participant, {required bool isWaiting}) {
    String? avatarUrl = _pbService.getFileUrl(participant, participant.getStringValue('avatar'));

    return Card(
      margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                    participant.getStringValue('name') ?? 'Unknown User',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Color(0xFF2D3748),
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    participant.getStringValue('email') ?? 'No Email',
                    style: TextStyle(
                      fontSize: 13,
                      color: Color(0xFF718096),
                    ),
                  ),
                  SizedBox(height: 8),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: isWaiting ? Colors.orange.withOpacity(0.1) : Colors.green.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      isWaiting ? 'Status: Waiting' : 'Status: Accepted',
                      style: TextStyle(
                        color: isWaiting ? Colors.orange : Colors.green,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (isWaiting)
              SizedBox(width: 8), // Spacing for the button
              if (isWaiting)
                ElevatedButton(
                  onPressed: () => _acceptParticipant(participant.id),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF6C63FF),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                  child: Text('Accept'),
                ),
          ],
        ),
      ),
    );
  }
}
