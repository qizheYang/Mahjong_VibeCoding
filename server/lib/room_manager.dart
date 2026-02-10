import 'dart:io';
import 'dart:convert';
import 'dart:math';

import 'room.dart';

/// Manages all active rooms and WebSocket connections.
class RoomManager {
  final Map<String, Room> _rooms = {};
  final Map<WebSocket, Room> _socketToRoom = {};
  final Random _random = Random();
  static const _codeChars = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';

  String _generateCode() {
    String code;
    do {
      code = String.fromCharCodes(
        List.generate(
            4, (_) => _codeChars.codeUnitAt(_random.nextInt(_codeChars.length))),
      );
    } while (_rooms.containsKey(code));
    return code;
  }

  void handleConnection(WebSocket ws) {
    ws.listen(
      (data) {
        try {
          final msg = jsonDecode(data as String) as Map<String, dynamic>;
          _handleMessage(ws, msg);
        } catch (e) {
          _send(ws, {'type': 'error', 'message': 'Invalid message: $e'});
        }
      },
      onDone: () => _handleDisconnect(ws),
      onError: (_) => _handleDisconnect(ws),
    );
  }

  void _handleMessage(WebSocket ws, Map<String, dynamic> msg) {
    final type = msg['type'] as String?;
    if (type == null) return;

    switch (type) {
      case 'create':
        _createRoom(ws, msg['nickname'] as String? ?? '???');
      case 'join':
        _joinRoom(
            ws, msg['code'] as String? ?? '', msg['nickname'] as String? ?? '???');
      case 'start':
      case 'action':
        final room = _socketToRoom[ws];
        if (room != null) {
          room.handleMessage(ws, msg);
        } else {
          _send(ws, {'type': 'error', 'message': '未在房间中'});
        }
      default:
        _send(ws, {'type': 'error', 'message': 'Unknown type: $type'});
    }
  }

  void _createRoom(WebSocket ws, String nickname) {
    // Remove from old room if any
    _handleDisconnect(ws);

    final code = _generateCode();
    final room = Room(code);
    _rooms[code] = room;
    room.addPlayer(ws, nickname);
    _socketToRoom[ws] = room;
    // ignore: avoid_print
    print('[Room $code] Created by $nickname');
  }

  void _joinRoom(WebSocket ws, String code, String nickname) {
    final room = _rooms[code.toUpperCase()];
    if (room == null) {
      _send(ws, {'type': 'error', 'message': '房间不存在 / Room not found'});
      return;
    }
    if (room.addPlayer(ws, nickname)) {
      _socketToRoom[ws] = room;
      // ignore: avoid_print
      print('[Room $code] $nickname joined');
    }
  }

  void _handleDisconnect(WebSocket ws) {
    final room = _socketToRoom.remove(ws);
    if (room != null) {
      room.removePlayer(ws);
      if (room.isEmpty) {
        _rooms.remove(room.code);
        // ignore: avoid_print
        print('[Room ${room.code}] Closed (empty)');
      }
    }
  }

  void _send(WebSocket ws, Map<String, dynamic> msg) {
    try {
      ws.add(jsonEncode(msg));
    } catch (_) {}
  }
}
