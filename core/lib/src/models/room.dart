enum RoomStatus { waiting, active, finished }

class Room {
  const Room({
    required this.id,
    required this.code,
    required this.status,
    required this.signalingChannel,
    this.playerA,
    this.playerB,
    this.puzzleForA,
    this.puzzleForB,
    this.startedAt,
    this.endedAt,
    this.winnerId,
  });

  final String id;
  final String code;
  final RoomStatus status;
  final String signalingChannel;
  final String? playerA;
  final String? playerB;
  final String? puzzleForA;
  final String? puzzleForB;
  final DateTime? startedAt;
  final DateTime? endedAt;
  final String? winnerId;

  factory Room.fromJson(Map<String, dynamic> json) => Room(
        id: json['id'] as String,
        code: json['code'] as String,
        status: RoomStatus.values.firstWhere(
          (s) => s.name == (json['status'] as String),
          orElse: () => RoomStatus.waiting,
        ),
        signalingChannel: json['webrtc_signaling_channel'] as String,
        playerA: json['player_a'] as String?,
        playerB: json['player_b'] as String?,
        puzzleForA: json['puzzle_for_a'] as String?,
        puzzleForB: json['puzzle_for_b'] as String?,
        startedAt: _ts(json['started_at']),
        endedAt: _ts(json['ended_at']),
        winnerId: json['winner_id'] as String?,
      );

  static DateTime? _ts(Object? v) =>
      v is String ? DateTime.tryParse(v) : null;
}

enum RoomEventType {
  joined,
  puzzleRevealed,
  wordDetected,
  won,
  left,
  interrupted,
}

extension RoomEventTypeWire on RoomEventType {
  String get wire {
    switch (this) {
      case RoomEventType.joined:
        return 'joined';
      case RoomEventType.puzzleRevealed:
        return 'puzzle_revealed';
      case RoomEventType.wordDetected:
        return 'word_detected';
      case RoomEventType.won:
        return 'won';
      case RoomEventType.left:
        return 'left';
      case RoomEventType.interrupted:
        return 'interrupted';
    }
  }

  static RoomEventType fromWire(String s) {
    switch (s) {
      case 'joined':
        return RoomEventType.joined;
      case 'puzzle_revealed':
        return RoomEventType.puzzleRevealed;
      case 'word_detected':
        return RoomEventType.wordDetected;
      case 'won':
        return RoomEventType.won;
      case 'left':
        return RoomEventType.left;
      case 'interrupted':
        return RoomEventType.interrupted;
      default:
        throw ArgumentError('Unknown room event type: $s');
    }
  }
}

class RoomEvent {
  const RoomEvent({
    required this.id,
    required this.roomId,
    required this.type,
    required this.createdAt,
    this.actorId,
    this.payload = const {},
  });

  final int id;
  final String roomId;
  final RoomEventType type;
  final String? actorId;
  final Map<String, dynamic> payload;
  final DateTime createdAt;

  factory RoomEvent.fromJson(Map<String, dynamic> json) => RoomEvent(
        id: (json['id'] as num).toInt(),
        roomId: json['room_id'] as String,
        type: RoomEventTypeWire.fromWire(json['event_type'] as String),
        actorId: json['actor_id'] as String?,
        payload: (json['payload'] as Map?)?.cast<String, dynamic>() ?? const {},
        createdAt: DateTime.parse(json['created_at'] as String),
      );
}
