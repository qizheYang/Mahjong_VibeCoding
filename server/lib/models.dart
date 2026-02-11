// Server-side state models for the mahjong virtual table.

import 'game_config.dart';

class ServerState {
  List<int> liveTileIds = [];
  List<int> deadWallTileIds = [];
  int doraRevealed = 0;
  List<SeatData> seats = List.generate(4, (_) => SeatData());
  List<String> nicknames = ['', '', '', ''];
  int dealerSeat = 0;
  int currentTurn = 0;
  int? lastDiscardedBy;
  int? lastDiscardedTileId;
  List<int> scores = [25000, 25000, 25000, 25000];
  int roundWind = 0; // 0=East, 1=South, 2=West, 3=North
  int roundNumber = 0; // 0-3
  int honbaCount = 0;
  int riichiSticksOnTable = 0;
  bool gameStarted = false;
  bool suggestKeepDealer = false;
  bool hasDrawnThisTurn = false;
  WinProposal? pendingWin;
  ExchangeProposal? pendingExchange;
  List<ActionLogEntry> actionLog = [];
  GameConfig config = const GameConfig();

  /// Apply config and reset scores to starting points.
  void applyConfig(GameConfig newConfig) {
    config = newConfig;
    scores = List.filled(4, newConfig.startingPoints);
  }

  Map<String, dynamic> toJsonForSeat(int viewerSeat) {
    return {
      'wallRemaining': liveTileIds.length,
      'doraIndicatorTileIds': _revealedDoraIndicators(),
      'deadWallCount': deadWallTileIds.length,
      'doraRevealed': doraRevealed,
      'seats': List.generate(
          4, (i) => seats[i].toJson(isViewer: i == viewerSeat)),
      'nicknames': nicknames,
      'dealerSeat': dealerSeat,
      'currentTurn': currentTurn,
      'lastDiscardedBy': lastDiscardedBy,
      'lastDiscardedTileId': lastDiscardedTileId,
      'scores': scores,
      'roundWind': roundWind,
      'roundNumber': roundNumber,
      'honbaCount': honbaCount,
      'riichiSticksOnTable': riichiSticksOnTable,
      'gameStarted': gameStarted,
      'suggestKeepDealer': suggestKeepDealer,
      'hasDrawnThisTurn': hasDrawnThisTurn,
      if (pendingWin != null) 'pendingWin': pendingWin!.toJson(),
      if (pendingExchange != null)
        'pendingExchange': pendingExchange!.toJson(),
      'actionLog':
          actionLog.map((e) => e.toJson()).toList(),
      'config': config.toJson(),
    };
  }

  List<int> _revealedDoraIndicators() {
    final indicators = <int>[];
    for (int i = 0; i < doraRevealed && i < 5; i++) {
      final idx = i * 2;
      if (idx < deadWallTileIds.length) {
        indicators.add(deadWallTileIds[idx]);
      }
    }
    return indicators;
  }

  void addLog(int seat, String action, {int? tileId, String? detail}) {
    actionLog.add(ActionLogEntry(
      seat: seat,
      nickname: seat >= 0 && seat < 4 ? nicknames[seat] : '',
      action: action,
      tileId: tileId,
      detail: detail,
    ));
    // Keep only last 50 entries
    if (actionLog.length > 50) {
      actionLog.removeRange(0, actionLog.length - 50);
    }
  }
}

class SeatData {
  List<int> handTileIds = [];
  List<DiscardEntry> discards = [];
  List<MeldData> melds = [];
  bool isRiichi = false;
  bool handRevealed = false;
  int? justDrewTileId;
  List<int> flowerTileIds = []; // face-up flower tiles
  int? missingSuit; // 0=man, 1=pin, 2=sou (Sichuan 缺一门)

  Map<String, dynamic> toJson({required bool isViewer}) {
    final showHand = isViewer || handRevealed;
    return {
      if (showHand) 'handTileIds': List<int>.from(handTileIds),
      'handCount': handTileIds.length,
      'discards': discards.map((d) => d.toJson()).toList(),
      'melds': melds.map((m) => m.toJson()).toList(),
      'isRiichi': isRiichi,
      'handRevealed': handRevealed,
      if (isViewer && justDrewTileId != null)
        'justDrewTileId': justDrewTileId,
      'flowerTileIds': flowerTileIds,
      if (missingSuit != null) 'missingSuit': missingSuit,
    };
  }

  void reset() {
    handTileIds.clear();
    discards.clear();
    melds.clear();
    isRiichi = false;
    handRevealed = false;
    justDrewTileId = null;
    flowerTileIds.clear();
    missingSuit = null;
  }
}

class DiscardEntry {
  final int tileId;
  final bool isTsumogiri;
  final bool isRiichiDiscard;

  DiscardEntry({
    required this.tileId,
    this.isTsumogiri = false,
    this.isRiichiDiscard = false,
  });

  Map<String, dynamic> toJson() => {
        'id': tileId,
        'tsumogiri': isTsumogiri,
        'riichi': isRiichiDiscard,
      };
}

class MeldData {
  String type; // "chi", "pon", "openKan", "closedKan", "addedKan"
  List<int> tileIds;
  int? calledFrom; // seat index
  int? calledTileId; // which tile was the called one

  MeldData({
    required this.type,
    required this.tileIds,
    this.calledFrom,
    this.calledTileId,
  });

  Map<String, dynamic> toJson() => {
        'type': type,
        'tileIds': tileIds,
        if (calledFrom != null) 'calledFrom': calledFrom,
        if (calledTileId != null) 'calledTileId': calledTileId,
      };
}

class WinProposal {
  final int seatIndex;
  final bool isTsumo;
  final int han;
  final int fu;
  final String tierName;
  final int totalPoints;
  final Map<int, int> payments; // seat -> point delta
  final Set<int> confirmed = {};
  final Set<int> rejected = {};

  WinProposal({
    required this.seatIndex,
    required this.isTsumo,
    required this.han,
    required this.fu,
    required this.tierName,
    required this.totalPoints,
    required this.payments,
  });

  Map<String, dynamic> toJson() => {
        'seatIndex': seatIndex,
        'isTsumo': isTsumo,
        'han': han,
        'fu': fu,
        'tierName': tierName,
        'totalPoints': totalPoints,
        'payments': payments.map((k, v) => MapEntry(k.toString(), v)),
        'confirmed': confirmed.toList(),
        'rejected': rejected.toList(),
      };
}

class ExchangeProposal {
  final int fromSeat;
  final int toSeat;
  final int amount;

  ExchangeProposal({
    required this.fromSeat,
    required this.toSeat,
    required this.amount,
  });

  Map<String, dynamic> toJson() => {
        'fromSeat': fromSeat,
        'toSeat': toSeat,
        'amount': amount,
      };
}

class ActionLogEntry {
  final int seat;
  final String nickname;
  final String action;
  final int? tileId;
  final String? detail;

  ActionLogEntry({
    required this.seat,
    required this.nickname,
    required this.action,
    this.tileId,
    this.detail,
  });

  Map<String, dynamic> toJson() => {
        'seat': seat,
        'nickname': nickname,
        'action': action,
        if (tileId != null) 'tileId': tileId,
        if (detail != null) 'detail': detail,
      };
}
