import 'dart:io';
import 'dart:convert';
import 'dart:math';

import 'game_config.dart';
import 'models.dart';
import 'table_logic.dart';

/// A single game room with up to 4 players.
class Room {
  final String code;
  final List<WebSocket?> _sockets = List.filled(4, null);
  final List<String> _nicknames = List.filled(4, '');
  final ServerState _state = ServerState();
  final Random _random = Random();
  int _hostSeat = 0;

  Room(this.code);

  bool get isEmpty => _sockets.every((s) => s == null);

  bool hasSocket(WebSocket ws) => _sockets.contains(ws);

  int? _seatOf(WebSocket ws) {
    final i = _sockets.indexOf(ws);
    return i >= 0 ? i : null;
  }

  /// Add a player. Returns true on success.
  bool addPlayer(WebSocket ws, String nickname) {
    final seat = _sockets.indexOf(null);
    if (seat < 0) {
      _send(ws, {'type': 'error', 'message': '房间已满 / Room full'});
      return false;
    }
    _sockets[seat] = ws;
    _nicknames[seat] = nickname;
    _state.nicknames[seat] = nickname;

    _send(ws, {
      'type': 'joined',
      'code': code,
      'seat': seat,
    });
    _broadcastLobby();
    return true;
  }

  void removePlayer(WebSocket ws) {
    final seat = _seatOf(ws);
    if (seat == null) return;
    _sockets[seat] = null;
    _nicknames[seat] = '';
    _state.nicknames[seat] = '';

    // Reassign host if needed
    if (seat == _hostSeat) {
      for (int i = 0; i < 4; i++) {
        if (_sockets[i] != null) {
          _hostSeat = i;
          break;
        }
      }
    }

    _broadcastLobby();
    // Notify remaining players
    _broadcast({
      'type': 'playerLeft',
      'seat': seat,
    });
  }

  void _broadcastLobby() {
    final seats = List.generate(4, (i) {
      if (_sockets[i] == null) return null;
      return {'nickname': _nicknames[i], 'isHost': i == _hostSeat};
    });
    _broadcast({'type': 'lobby', 'seats': seats});
  }

  void handleMessage(WebSocket ws, Map<String, dynamic> msg) {
    final seat = _seatOf(ws);
    if (seat == null) return;

    final type = msg['type'] as String;

    if (type == 'start') {
      if (seat != _hostSeat) {
        _send(ws, {'type': 'error', 'message': '只有房主可以开始'});
        return;
      }
      // Apply game config if provided
      final configJson = msg['config'] as Map<String, dynamic>?;
      if (configJson != null) {
        _state.applyConfig(GameConfig.fromJson(configJson));
      }
      TableLogic.deal(_state, _random);
      _broadcastState();
      return;
    }

    if (type == 'action') {
      _handleAction(seat, msg);
      return;
    }
  }

  void _handleAction(int seat, Map<String, dynamic> msg) {
    final action = msg['action'] as String?;
    if (action == null) return;

    switch (action) {
      case 'draw':
        TableLogic.draw(_state, seat);
      case 'drawDeadWall':
        TableLogic.drawDeadWall(_state, seat);
      case 'discard':
        TableLogic.discard(_state, seat, msg['tileId'] as int);
      case 'chi':
        final tileIds = (msg['tileIds'] as List).cast<int>();
        TableLogic.chi(_state, seat, tileIds);
      case 'pon':
        final tileIds = (msg['tileIds'] as List).cast<int>();
        TableLogic.pon(_state, seat, tileIds);
      case 'openKan':
        final tileIds = (msg['tileIds'] as List).cast<int>();
        TableLogic.openKan(_state, seat, tileIds);
      case 'closedKan':
        final tileIds = (msg['tileIds'] as List).cast<int>();
        TableLogic.closedKan(_state, seat, tileIds);
      case 'addedKan':
        TableLogic.addedKan(
            _state, seat, msg['tileId'] as int, msg['meldIndex'] as int);
      case 'riichi':
        TableLogic.riichi(_state, seat, msg['tileId'] as int);
      case 'declareWin':
        TableLogic.declareWin(_state, seat, msg['isTsumo'] as bool,
            msg['han'] as int, msg['fu'] as int);
      case 'confirmWin':
        TableLogic.confirmWin(_state, seat);
      case 'rejectWin':
        TableLogic.rejectWin(_state, seat);
      case 'objection':
        _broadcastObjection(seat, msg['message'] as String? ?? '');
        return; // don't broadcast state for objection
      case 'exchangePropose':
        TableLogic.exchangePropose(
            _state, seat, msg['targetSeat'] as int, msg['amount'] as int);
      case 'exchangeConfirm':
        TableLogic.exchangeConfirm(_state, seat);
      case 'exchangeReject':
        TableLogic.exchangeReject(_state, seat);
      case 'revealDora':
        TableLogic.revealDora(_state);
      case 'newRound':
        TableLogic.newRound(
            _state, _random, msg['keepDealer'] as bool? ?? false);
      case 'sortHand':
        TableLogic.sortHand(_state, seat);
      case 'showHand':
        TableLogic.showHand(_state, seat);
      case 'hideHand':
        TableLogic.hideHand(_state, seat);
      case 'undoDiscard':
        TableLogic.undoDiscard(_state, seat);
      case 'adjustScore':
        TableLogic.adjustScore(
            _state, msg['targetSeat'] as int, msg['amount'] as int);
      case 'drawFlower':
        TableLogic.drawFlower(_state, seat, msg['tileId'] as int);
      default:
        return;
    }

    _broadcastState();
  }

  void _broadcastObjection(int seat, String message) {
    _broadcast({
      'type': 'objection',
      'seat': seat,
      'nickname': _nicknames[seat],
      'message': message,
    });
  }

  void _broadcastState() {
    for (int i = 0; i < 4; i++) {
      if (_sockets[i] != null) {
        _send(_sockets[i]!, {
          'type': 'state',
          'state': _state.toJsonForSeat(i),
        });
      }
    }
  }

  void _broadcast(Map<String, dynamic> msg) {
    final json = jsonEncode(msg);
    for (final ws in _sockets) {
      if (ws != null) {
        try {
          ws.add(json);
        } catch (_) {}
      }
    }
  }

  void _send(WebSocket ws, Map<String, dynamic> msg) {
    try {
      ws.add(jsonEncode(msg));
    } catch (_) {}
  }
}
