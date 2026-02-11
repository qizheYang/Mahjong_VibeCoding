import 'dart:async';
import 'dart:io';
import 'dart:convert';
import 'dart:math';

import 'game_config.dart';
import 'models.dart';
import 'sichuan_ai.dart';
import 'table_logic.dart';

/// A single game room with up to 4 players.
class Room {
  final String code;
  final List<WebSocket?> _sockets = List.filled(4, null);
  final List<String> _nicknames = List.filled(4, '');
  final ServerState _state = ServerState();
  final Random _random = Random();
  int _hostSeat = 0;
  List<bool> _aiSeats = [false, false, false, false];
  Timer? _aiTimer;

  Room(this.code);

  bool get isEmpty => _sockets.every((s) => s == null);

  bool hasSocket(WebSocket ws) => _sockets.contains(ws);

  int? _seatOf(WebSocket ws) {
    final i = _sockets.indexOf(ws);
    return i >= 0 ? i : null;
  }

  /// Add a player. Returns true on success.
  bool addPlayer(WebSocket ws, String nickname) {
    // Find first seat that is not occupied by a human or AI
    int seat = -1;
    for (int i = 0; i < 4; i++) {
      if (_sockets[i] == null && !_aiSeats[i]) {
        seat = i;
        break;
      }
    }
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
      if (_aiSeats[i]) {
        return {'nickname': 'AI', 'isHost': false, 'isAi': true};
      }
      if (_sockets[i] == null) return null;
      return {
        'nickname': _nicknames[i],
        'isHost': i == _hostSeat,
        'isAi': false,
      };
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
        final config = GameConfig.fromJson(configJson);
        _state.applyConfig(config);
        _aiSeats = List<bool>.from(config.aiSeats);
        // Set AI nicknames
        for (int i = 0; i < 4; i++) {
          if (_aiSeats[i]) {
            _nicknames[i] = 'AI';
            _state.nicknames[i] = 'AI';
          }
        }
      }
      TableLogic.deal(_state, _random);
      _broadcastState();
      _scheduleAi();
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
        final variant = msg['variant'] as String?;
        if (variant == 'sichuan') {
          TableLogic.declareWinSichuan(
              _state, seat, msg['isTsumo'] as bool, msg['han'] as int);
        } else if (variant == 'direct') {
          TableLogic.declareWinDirect(
              _state, seat, msg['isTsumo'] as bool, msg['perPlayer'] as int);
        } else {
          TableLogic.declareWin(_state, seat, msg['isTsumo'] as bool,
              msg['han'] as int, msg['fu'] as int);
        }
      case 'confirmWin':
        TableLogic.confirmWin(_state, seat);
      case 'rejectWin':
        TableLogic.rejectWin(_state, seat);
      case 'objection':
        _broadcastObjection(seat, msg['message'] as String? ?? '');
        return; // don't broadcast state for objection
      case 'hold':
        _broadcast({'type': 'hold', 'seat': seat});
        return;
      case 'releaseHold':
        _broadcast({'type': 'releaseHold', 'seat': seat});
        return;
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
      case 'chooseMissingSuit':
        TableLogic.chooseMissingSuit(_state, seat, msg['suit'] as int);
      default:
        return;
    }

    _broadcastState();
    _scheduleAi();
  }

  // ─── AI ────────────────────────────────────────────────────

  void _scheduleAi() {
    _aiTimer?.cancel();
    if (!_aiSeats.any((a) => a)) return;
    if (!_state.gameStarted) return;

    _aiTimer = Timer(const Duration(milliseconds: 800), () {
      _processAiTurn();
    });
  }

  void _processAiTurn() {
    if (!_state.gameStarted) return;
    if (_state.liveTileIds.isEmpty) return;

    // If there's a pending win proposal, AI auto-confirms
    if (_state.pendingWin != null) {
      for (int i = 0; i < 4; i++) {
        if (_aiSeats[i] &&
            i != _state.pendingWin!.seatIndex &&
            !_state.pendingWin!.confirmed.contains(i) &&
            !_state.pendingWin!.rejected.contains(i)) {
          TableLogic.confirmWin(_state, i);
        }
      }
      _broadcastState();
      _scheduleAi();
      return;
    }

    // Check if any AI needs to choose missing suit
    for (int i = 0; i < 4; i++) {
      if (_aiSeats[i] && _state.seats[i].missingSuit == null) {
        final suit =
            SichuanAi.chooseMissingSuit(_state.seats[i].handTileIds);
        TableLogic.chooseMissingSuit(_state, i, suit);
        _broadcastState();
        _scheduleAi();
        return;
      }
    }

    // Wait until all players have chosen missing suit (Sichuan)
    if (_state.config.isSichuan &&
        _state.seats.any((s) => s.missingSuit == null)) {
      return;
    }

    final currentSeat = _state.currentTurn;
    if (!_aiSeats[currentSeat]) {
      // Check if AI can pon the last discard
      _aiCheckPon();
      return;
    }

    // AI's turn
    final seatData = _state.seats[currentSeat];
    final missingSuit = seatData.missingSuit ?? -1;

    // Step 1: Draw if needed
    if (!_state.hasDrawnThisTurn) {
      TableLogic.draw(_state, currentSeat);
      _broadcastState();

      // Check for win after drawing
      if (SichuanAi.isWinningHand(seatData.handTileIds, missingSuit)) {
        final han = SichuanAi.countHan(seatData.handTileIds, missingSuit);
        TableLogic.declareWinSichuan(_state, currentSeat, true, han);
        _broadcastState();
        _scheduleAi();
        return;
      }

      // Schedule discard
      _aiTimer = Timer(const Duration(milliseconds: 600), () {
        _aiDiscard(currentSeat, missingSuit);
      });
      return;
    }

    // Step 2: Already drawn, discard
    _aiDiscard(currentSeat, missingSuit);
  }

  void _aiDiscard(int seat, int missingSuit) {
    if (!_state.gameStarted) return;
    final seatData = _state.seats[seat];
    if (seatData.handTileIds.isEmpty) return;

    final tileId =
        SichuanAi.chooseDiscard(seatData.handTileIds, missingSuit);
    TableLogic.discard(_state, seat, tileId);
    _broadcastState();
    _scheduleAi();
  }

  void _aiCheckPon() {
    final lastDiscard = _state.lastDiscardedTileId;
    final lastDiscardedBy = _state.lastDiscardedBy;
    if (lastDiscard == null || lastDiscardedBy == null) return;

    final discardKind = lastDiscard ~/ 4;

    for (int i = 0; i < 4; i++) {
      if (!_aiSeats[i]) continue;
      if (i == lastDiscardedBy) continue;

      final missingSuit = _state.seats[i].missingSuit ?? -1;
      if (SichuanAi.shouldPon(
          _state.seats[i].handTileIds, discardKind, missingSuit)) {
        // Find 2 tiles of same kind to pon with
        final ponTiles = _state.seats[i].handTileIds
            .where((id) => id ~/ 4 == discardKind)
            .take(2)
            .toList();
        if (ponTiles.length == 2) {
          TableLogic.pon(_state, i, ponTiles);
          _broadcastState();
          _scheduleAi();
          return;
        }
      }
    }
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
