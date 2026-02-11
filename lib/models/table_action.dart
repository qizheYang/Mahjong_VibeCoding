import 'dart:convert';

/// Builds JSON action messages to send to the server.
class TableAction {
  TableAction._();

  static String draw() => _encode('draw');

  static String drawDeadWall() => _encode('drawDeadWall');

  static String discard(int tileId) =>
      _encode('discard', {'tileId': tileId});

  static String chi(List<int> handTileIds) =>
      _encode('chi', {'tileIds': handTileIds});

  static String pon(List<int> handTileIds) =>
      _encode('pon', {'tileIds': handTileIds});

  static String openKan(List<int> handTileIds) =>
      _encode('openKan', {'tileIds': handTileIds});

  static String closedKan(List<int> tileIds) =>
      _encode('closedKan', {'tileIds': tileIds});

  static String addedKan(int tileId, int meldIndex) =>
      _encode('addedKan', {'tileId': tileId, 'meldIndex': meldIndex});

  static String riichi(int tileId) =>
      _encode('riichi', {'tileId': tileId});

  /// Riichi win: han + fu scoring.
  static String declareWin(bool isTsumo, int han, int fu) =>
      _encode('declareWin', {'isTsumo': isTsumo, 'han': han, 'fu': fu});

  /// Sichuan win: han only (1-5), scoring is 2^han.
  static String declareWinSichuan(bool isTsumo, int han) =>
      _encode('declareWin', {'isTsumo': isTsumo, 'han': han, 'variant': 'sichuan'});

  /// Direct point entry win (Guobiao etc.): perPlayer amount.
  static String declareWinDirect(bool isTsumo, int perPlayer) =>
      _encode('declareWin', {'isTsumo': isTsumo, 'perPlayer': perPlayer, 'variant': 'direct'});

  static String confirmWin() => _encode('confirmWin');

  static String rejectWin() => _encode('rejectWin');

  static String objection(String message) =>
      _encode('objection', {'message': message});

  static String exchangePropose(int targetSeat, int amount) =>
      _encode('exchangePropose',
          {'targetSeat': targetSeat, 'amount': amount});

  static String exchangeConfirm() => _encode('exchangeConfirm');

  static String exchangeReject() => _encode('exchangeReject');

  static String revealDora() => _encode('revealDora');

  static String newRound({bool keepDealer = false}) =>
      _encode('newRound', {'keepDealer': keepDealer});

  static String sortHand() => _encode('sortHand');

  static String showHand() => _encode('showHand');

  static String hideHand() => _encode('hideHand');

  static String undoDiscard() => _encode('undoDiscard');

  static String adjustScore(int targetSeat, int amount) =>
      _encode('adjustScore', {'targetSeat': targetSeat, 'amount': amount});

  /// Draw flower (补花): move flower tile from hand to flowers, draw replacement.
  static String drawFlower(int tileId) =>
      _encode('drawFlower', {'tileId': tileId});

  /// Choose missing suit for Sichuan mode (缺一门).
  static String chooseMissingSuit(int suit) =>
      _encode('chooseMissingSuit', {'suit': suit});

  /// Request hold (pause auto-draw for pon/kan decision).
  static String hold() => _encode('hold');

  /// Release hold (resume auto-draw).
  static String releaseHold() => _encode('releaseHold');

  static String _encode(String action, [Map<String, dynamic>? extra]) {
    final msg = <String, dynamic>{
      'type': 'action',
      'action': action,
    };
    if (extra != null) {
      msg.addAll(extra);
    }
    return jsonEncode(msg);
  }
}

/// Non-action messages to the server.
class ServerMessage {
  ServerMessage._();

  static String createRoom(String nickname) =>
      jsonEncode({'type': 'create', 'nickname': nickname});

  static String joinRoom(String code, String nickname) =>
      jsonEncode({'type': 'join', 'code': code, 'nickname': nickname});

  static String startGame({Map<String, dynamic>? config}) => jsonEncode({
        'type': 'start',
        // ignore: use_null_aware_elements
        if (config != null) 'config': config,
      });
}
