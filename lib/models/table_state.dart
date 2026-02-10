import '../engine/tile/tile.dart';
import '../engine/state/meld.dart';

/// Client-side table state received from server.
class TableState {
  final int wallRemaining;
  final List<int> doraIndicatorTileIds;
  final int deadWallCount;
  final int doraRevealed;
  final List<SeatState> seats;
  final List<String> nicknames;
  final int dealerSeat;
  final int currentTurn;
  final int? lastDiscardedBy;
  final int? lastDiscardedTileId;
  final List<int> scores;
  final int roundWind;
  final int roundNumber;
  final int honbaCount;
  final int riichiSticksOnTable;
  final bool gameStarted;
  final bool suggestKeepDealer;
  final bool hasDrawnThisTurn;
  final WinProposal? pendingWin;
  final ExchangeProposal? pendingExchange;
  final List<ActionLogEntry> actionLog;

  const TableState({
    required this.wallRemaining,
    required this.doraIndicatorTileIds,
    required this.deadWallCount,
    required this.doraRevealed,
    required this.seats,
    required this.nicknames,
    required this.dealerSeat,
    required this.currentTurn,
    this.lastDiscardedBy,
    this.lastDiscardedTileId,
    required this.scores,
    required this.roundWind,
    required this.roundNumber,
    required this.honbaCount,
    required this.riichiSticksOnTable,
    required this.gameStarted,
    required this.suggestKeepDealer,
    required this.hasDrawnThisTurn,
    this.pendingWin,
    this.pendingExchange,
    required this.actionLog,
  });

  factory TableState.fromJson(Map<String, dynamic> json) {
    return TableState(
      wallRemaining: json['wallRemaining'] as int,
      doraIndicatorTileIds:
          (json['doraIndicatorTileIds'] as List).cast<int>(),
      deadWallCount: json['deadWallCount'] as int,
      doraRevealed: json['doraRevealed'] as int,
      seats: (json['seats'] as List)
          .map((s) => SeatState.fromJson(s as Map<String, dynamic>))
          .toList(),
      nicknames: (json['nicknames'] as List).cast<String>(),
      dealerSeat: json['dealerSeat'] as int,
      currentTurn: json['currentTurn'] as int,
      lastDiscardedBy: json['lastDiscardedBy'] as int?,
      lastDiscardedTileId: json['lastDiscardedTileId'] as int?,
      scores: (json['scores'] as List).cast<int>(),
      roundWind: json['roundWind'] as int,
      roundNumber: json['roundNumber'] as int,
      honbaCount: json['honbaCount'] as int,
      riichiSticksOnTable: json['riichiSticksOnTable'] as int,
      gameStarted: json['gameStarted'] as bool,
      suggestKeepDealer: json['suggestKeepDealer'] as bool? ?? false,
      hasDrawnThisTurn: json['hasDrawnThisTurn'] as bool? ?? false,
      pendingWin: json['pendingWin'] != null
          ? WinProposal.fromJson(json['pendingWin'] as Map<String, dynamic>)
          : null,
      pendingExchange: json['pendingExchange'] != null
          ? ExchangeProposal.fromJson(
              json['pendingExchange'] as Map<String, dynamic>)
          : null,
      actionLog: (json['actionLog'] as List?)
              ?.map((e) =>
                  ActionLogEntry.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }

  /// Get dora indicator tiles as Tile objects.
  List<Tile> get doraIndicators =>
      doraIndicatorTileIds.map((id) => Tile(id)).toList();

  /// Last discarded tile as Tile object.
  Tile? get lastDiscardedTile =>
      lastDiscardedTileId != null ? Tile(lastDiscardedTileId!) : null;
}

class SeatState {
  final List<int>? handTileIds; // null for other players
  final int handCount;
  final List<DiscardEntry> discards;
  final List<ClientMeld> melds;
  final bool isRiichi;
  final bool handRevealed;
  final int? justDrewTileId;

  const SeatState({
    this.handTileIds,
    required this.handCount,
    required this.discards,
    required this.melds,
    required this.isRiichi,
    required this.handRevealed,
    this.justDrewTileId,
  });

  factory SeatState.fromJson(Map<String, dynamic> json) {
    return SeatState(
      handTileIds: json.containsKey('handTileIds')
          ? (json['handTileIds'] as List).cast<int>()
          : null,
      handCount: json['handCount'] as int,
      discards: (json['discards'] as List)
          .map((d) => DiscardEntry.fromJson(d as Map<String, dynamic>))
          .toList(),
      melds: (json['melds'] as List)
          .map((m) => ClientMeld.fromJson(m as Map<String, dynamic>))
          .toList(),
      isRiichi: json['isRiichi'] as bool,
      handRevealed: json['handRevealed'] as bool? ?? false,
      justDrewTileId: json['justDrewTileId'] as int?,
    );
  }

  /// Hand as Tile objects (only available for own seat or revealed hands).
  List<Tile>? get handTiles =>
      handTileIds?.map((id) => Tile(id)).toList();

  /// Just-drew tile as Tile object.
  Tile? get justDrew =>
      justDrewTileId != null ? Tile(justDrewTileId!) : null;
}

class DiscardEntry {
  final int tileId;
  final bool isTsumogiri;
  final bool isRiichiDiscard;

  const DiscardEntry({
    required this.tileId,
    this.isTsumogiri = false,
    this.isRiichiDiscard = false,
  });

  factory DiscardEntry.fromJson(Map<String, dynamic> json) {
    return DiscardEntry(
      tileId: json['id'] as int,
      isTsumogiri: json['tsumogiri'] as bool? ?? false,
      isRiichiDiscard: json['riichi'] as bool? ?? false,
    );
  }

  Tile get tile => Tile(tileId);
}

/// Client-side meld that bridges to the engine Meld class for display.
class ClientMeld {
  final String type;
  final List<int> tileIds;
  final int? calledFrom;
  final int? calledTileId;

  const ClientMeld({
    required this.type,
    required this.tileIds,
    this.calledFrom,
    this.calledTileId,
  });

  factory ClientMeld.fromJson(Map<String, dynamic> json) {
    return ClientMeld(
      type: json['type'] as String,
      tileIds: (json['tileIds'] as List).cast<int>(),
      calledFrom: json['calledFrom'] as int?,
      calledTileId: json['calledTileId'] as int?,
    );
  }

  List<Tile> get tiles => tileIds.map((id) => Tile(id)).toList();

  /// Convert to engine Meld for display widgets.
  Meld toMeld() {
    return Meld(
      type: _meldType,
      tiles: tiles,
      calledFrom: calledFrom,
      calledTile: calledTileId != null ? Tile(calledTileId!) : null,
    );
  }

  MeldType get _meldType {
    switch (type) {
      case 'chi':
        return MeldType.chi;
      case 'pon':
        return MeldType.pon;
      case 'openKan':
        return MeldType.openKan;
      case 'closedKan':
        return MeldType.closedKan;
      case 'addedKan':
        return MeldType.addedKan;
      default:
        return MeldType.pon;
    }
  }
}

class WinProposal {
  final int seatIndex;
  final bool isTsumo;
  final int han;
  final int fu;
  final String tierName;
  final int totalPoints;
  final Map<int, int> payments;
  final List<int> confirmed;
  final List<int> rejected;

  const WinProposal({
    required this.seatIndex,
    required this.isTsumo,
    required this.han,
    required this.fu,
    required this.tierName,
    required this.totalPoints,
    required this.payments,
    required this.confirmed,
    required this.rejected,
  });

  factory WinProposal.fromJson(Map<String, dynamic> json) {
    final paymentsRaw = json['payments'] as Map<String, dynamic>;
    return WinProposal(
      seatIndex: json['seatIndex'] as int,
      isTsumo: json['isTsumo'] as bool,
      han: json['han'] as int,
      fu: json['fu'] as int,
      tierName: json['tierName'] as String,
      totalPoints: json['totalPoints'] as int,
      payments:
          paymentsRaw.map((k, v) => MapEntry(int.parse(k), v as int)),
      confirmed: (json['confirmed'] as List).cast<int>(),
      rejected: (json['rejected'] as List).cast<int>(),
    );
  }
}

class ExchangeProposal {
  final int fromSeat;
  final int toSeat;
  final int amount;

  const ExchangeProposal({
    required this.fromSeat,
    required this.toSeat,
    required this.amount,
  });

  factory ExchangeProposal.fromJson(Map<String, dynamic> json) {
    return ExchangeProposal(
      fromSeat: json['fromSeat'] as int,
      toSeat: json['toSeat'] as int,
      amount: json['amount'] as int,
    );
  }
}

class ActionLogEntry {
  final int seat;
  final String nickname;
  final String action;
  final int? tileId;
  final String? detail;

  const ActionLogEntry({
    required this.seat,
    required this.nickname,
    required this.action,
    this.tileId,
    this.detail,
  });

  factory ActionLogEntry.fromJson(Map<String, dynamic> json) {
    return ActionLogEntry(
      seat: json['seat'] as int,
      nickname: json['nickname'] as String? ?? '',
      action: json['action'] as String,
      tileId: json['tileId'] as int?,
      detail: json['detail'] as String?,
    );
  }
}
