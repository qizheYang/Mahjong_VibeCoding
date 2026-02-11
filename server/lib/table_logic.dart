import 'dart:math';

import 'models.dart';
import 'score_calculator.dart';

/// Pure functions that apply actions to ServerState.
/// No validation — this is a free-form virtual table.
class TableLogic {
  TableLogic._();

  /// Shuffle wall and deal tiles to all players.
  /// Uses the config to determine which tiles to include.
  static void deal(ServerState state, Random random) {
    final config = state.config;
    final allIds = config.generateTileIds();
    allIds.shuffle(random);

    // Dead wall setup based on variant
    if (config.hasDeadWall) {
      final deadSize = config.deadWallSize;
      state.deadWallTileIds = allIds.sublist(allIds.length - deadSize);
      state.liveTileIds = allIds.sublist(0, allIds.length - deadSize);
    } else {
      state.deadWallTileIds = [];
      state.liveTileIds = allIds;
    }

    // Dora: start at 1 for Riichi, 0 for others
    state.doraRevealed = config.hasDora ? 1 : 0;

    // Reset seats
    for (int i = 0; i < 4; i++) {
      state.seats[i].reset();
    }

    // Deal 13 tiles each
    for (int i = 0; i < 4; i++) {
      for (int j = 0; j < 13; j++) {
        state.seats[i].handTileIds.add(state.liveTileIds.removeAt(0));
      }
    }

    // Dealer gets 14th tile
    final dealerTile = state.liveTileIds.removeAt(0);
    state.seats[state.dealerSeat].handTileIds.add(dealerTile);
    state.seats[state.dealerSeat].justDrewTileId = dealerTile;

    state.currentTurn = state.dealerSeat;
    state.lastDiscardedBy = null;
    state.lastDiscardedTileId = null;
    state.gameStarted = true;
    state.hasDrawnThisTurn = true; // dealer's 14th tile counts as draw
    state.pendingWin = null;
    state.pendingExchange = null;
    state.suggestKeepDealer = false;
    state.baidaReferenceTileId = null;
    state.actionLog.clear();
    state.addLog(state.dealerSeat, 'deal');

    // Shanghai 百搭: flip a reference tile from the live wall
    if (config.hasBaida && state.liveTileIds.isNotEmpty) {
      state.baidaReferenceTileId = state.liveTileIds.removeAt(0);
      state.addLog(-1, 'baidaFlip', tileId: state.baidaReferenceTileId);
    }
  }

  /// Draw a tile from the live wall (front).
  static void draw(ServerState state, int seat) {
    if (state.liveTileIds.isEmpty) return;
    if (state.hasDrawnThisTurn) return;
    final tileId = state.liveTileIds.removeAt(0);
    state.seats[seat].handTileIds.add(tileId);
    state.seats[seat].justDrewTileId = tileId;
    state.hasDrawnThisTurn = true;
    state.addLog(seat, 'draw');
  }

  /// Draw from the back of the live wall (after kan).
  static void drawDeadWall(ServerState state, int seat) {
    if (state.liveTileIds.isEmpty) return;
    if (state.hasDrawnThisTurn) return;
    final tileId = state.liveTileIds.removeLast();
    state.seats[seat].handTileIds.add(tileId);
    state.seats[seat].justDrewTileId = tileId;
    state.hasDrawnThisTurn = true;
    state.addLog(seat, 'drawDeadWall');
  }

  /// Draw flower (补花): move flower tile from hand to flowers,
  /// then draw replacement from back of wall.
  static void drawFlower(ServerState state, int seat, int tileId) {
    final seatData = state.seats[seat];
    if (!seatData.handTileIds.contains(tileId)) return;

    // Move tile from hand to flower display
    seatData.handTileIds.remove(tileId);
    seatData.flowerTileIds.add(tileId);

    // Draw replacement from back of live wall
    if (state.liveTileIds.isNotEmpty) {
      final replacement = state.liveTileIds.removeLast();
      seatData.handTileIds.add(replacement);
      seatData.justDrewTileId = replacement;
    }

    state.addLog(seat, 'drawFlower', tileId: tileId);
  }

  /// Discard a tile from hand.
  static void discard(ServerState state, int seat, int tileId) {
    final seatData = state.seats[seat];
    final isTsumogiri = seatData.justDrewTileId == tileId;
    seatData.handTileIds.remove(tileId);
    seatData.discards.add(DiscardEntry(
      tileId: tileId,
      isTsumogiri: isTsumogiri,
    ));
    seatData.justDrewTileId = null;
    state.lastDiscardedBy = seat;
    state.lastDiscardedTileId = tileId;
    state.currentTurn = (seat + 1) % 4;
    state.hasDrawnThisTurn = false;
    state.addLog(seat, 'discard', tileId: tileId);
  }

  /// Call chi: 2 hand tiles + last discard → sequence meld.
  static void chi(ServerState state, int seat, List<int> handTileIds) {
    final discardTileId = state.lastDiscardedTileId;
    final discardedBy = state.lastDiscardedBy;
    if (discardTileId == null || discardedBy == null) return;

    state.seats[discardedBy].discards
        .removeWhere((d) => d.tileId == discardTileId);

    for (final id in handTileIds) {
      state.seats[seat].handTileIds.remove(id);
    }

    final allTiles = [...handTileIds, discardTileId];
    allTiles.sort((a, b) => (a ~/ 4).compareTo(b ~/ 4));
    state.seats[seat].melds.add(MeldData(
      type: 'chi',
      tileIds: allTiles,
      calledFrom: discardedBy,
      calledTileId: discardTileId,
    ));

    state.lastDiscardedBy = null;
    state.lastDiscardedTileId = null;
    state.currentTurn = seat;
    state.hasDrawnThisTurn = true;
    state.seats[seat].justDrewTileId = null;
    state.addLog(seat, 'chi', tileId: discardTileId);
  }

  /// Call pon: 2 hand tiles + last discard → triplet meld.
  static void pon(ServerState state, int seat, List<int> handTileIds) {
    final discardTileId = state.lastDiscardedTileId;
    final discardedBy = state.lastDiscardedBy;
    if (discardTileId == null || discardedBy == null) return;

    state.seats[discardedBy].discards
        .removeWhere((d) => d.tileId == discardTileId);

    for (final id in handTileIds) {
      state.seats[seat].handTileIds.remove(id);
    }

    state.seats[seat].melds.add(MeldData(
      type: 'pon',
      tileIds: [...handTileIds, discardTileId],
      calledFrom: discardedBy,
      calledTileId: discardTileId,
    ));

    state.lastDiscardedBy = null;
    state.lastDiscardedTileId = null;
    state.currentTurn = seat;
    state.hasDrawnThisTurn = true;
    state.seats[seat].justDrewTileId = null;
    state.addLog(seat, 'pon', tileId: discardTileId);
  }

  /// Call open kan: 3 hand tiles + last discard → quad meld.
  static void openKan(ServerState state, int seat, List<int> handTileIds) {
    final discardTileId = state.lastDiscardedTileId;
    final discardedBy = state.lastDiscardedBy;
    if (discardTileId == null || discardedBy == null) return;

    state.seats[discardedBy].discards
        .removeWhere((d) => d.tileId == discardTileId);

    for (final id in handTileIds) {
      state.seats[seat].handTileIds.remove(id);
    }

    state.seats[seat].melds.add(MeldData(
      type: 'openKan',
      tileIds: [...handTileIds, discardTileId],
      calledFrom: discardedBy,
      calledTileId: discardTileId,
    ));

    state.lastDiscardedBy = null;
    state.lastDiscardedTileId = null;
    state.currentTurn = seat;
    state.hasDrawnThisTurn = false;
    state.seats[seat].justDrewTileId = null;
    state.addLog(seat, 'openKan', tileId: discardTileId);
  }

  /// Declare closed kan: 4 hand tiles → concealed quad meld.
  static void closedKan(ServerState state, int seat, List<int> tileIds) {
    for (final id in tileIds) {
      state.seats[seat].handTileIds.remove(id);
    }

    state.seats[seat].melds.add(MeldData(
      type: 'closedKan',
      tileIds: tileIds,
    ));

    state.seats[seat].justDrewTileId = null;
    state.hasDrawnThisTurn = false;
    state.addLog(seat, 'closedKan', tileId: tileIds.first);
  }

  /// Added kan: upgrade existing pon by adding 1 hand tile.
  static void addedKan(
      ServerState state, int seat, int tileId, int meldIndex) {
    if (meldIndex >= state.seats[seat].melds.length) return;
    final meld = state.seats[seat].melds[meldIndex];
    if (meld.type != 'pon') return;

    state.seats[seat].handTileIds.remove(tileId);
    meld.type = 'addedKan';
    meld.tileIds.add(tileId);

    state.seats[seat].justDrewTileId = null;
    state.hasDrawnThisTurn = false;
    state.addLog(seat, 'addedKan', tileId: tileId);
  }

  /// Declare riichi: permanently set riichi, deduct 1000 pts, discard tile.
  static void riichi(ServerState state, int seat, int tileId) {
    final seatData = state.seats[seat];
    if (seatData.isRiichi) return;

    seatData.isRiichi = true;
    state.scores[seat] -= 1000;
    state.riichiSticksOnTable += 1;

    final isTsumogiri = seatData.justDrewTileId == tileId;
    seatData.handTileIds.remove(tileId);
    seatData.discards.add(DiscardEntry(
      tileId: tileId,
      isTsumogiri: isTsumogiri,
      isRiichiDiscard: true,
    ));
    seatData.justDrewTileId = null;
    state.lastDiscardedBy = seat;
    state.lastDiscardedTileId = tileId;
    state.currentTurn = (seat + 1) % 4;
    state.hasDrawnThisTurn = false;
    state.addLog(seat, 'riichi', tileId: tileId);
  }

  /// Declare win (Riichi): create proposal for others to confirm/reject.
  static void declareWin(
      ServerState state, int seat, bool isTsumo, int han, int fu) {
    final tierName = ScoreCalculator.tierName(han, fu);
    final loserSeat = isTsumo ? null : state.lastDiscardedBy;

    final payments = ScoreCalculator.calculatePayments(
      han: han,
      fu: fu,
      winnerSeat: seat,
      dealerSeat: state.dealerSeat,
      isTsumo: isTsumo,
      loserSeat: loserSeat,
      honbaCount: state.honbaCount,
      riichiSticks: state.riichiSticksOnTable,
    );

    final total = payments[seat] ?? 0;

    state.pendingWin = WinProposal(
      seatIndex: seat,
      isTsumo: isTsumo,
      han: han,
      fu: fu,
      tierName: tierName,
      totalPoints: total,
      payments: payments,
    );
    state.addLog(seat, 'declareWin',
        detail: '$tierName ${isTsumo ? "自摸" : "荣和"} $total点');
  }

  /// Declare win (Sichuan): han 1-5, scoring is 2^han per player.
  static void declareWinSichuan(
      ServerState state, int seat, bool isTsumo, int han) {
    final loserSeat = isTsumo ? null : state.lastDiscardedBy;
    final payments = ScoreCalculator.sichuanPayments(
      han: han,
      isTsumo: isTsumo,
      winnerSeat: seat,
      loserSeat: loserSeat,
    );
    final total = payments[seat] ?? 0;
    final perPlayer = 1 << han;
    final tierName = '$han番 ($perPlayer点)';

    state.pendingWin = WinProposal(
      seatIndex: seat,
      isTsumo: isTsumo,
      han: han,
      fu: 0,
      tierName: tierName,
      totalPoints: total,
      payments: payments,
    );
    state.addLog(seat, 'declareWin',
        detail: '$tierName ${isTsumo ? "自摸" : "荣和"} $total点');
  }

  /// Declare win (Direct entry): winner enters per-player amount.
  static void declareWinDirect(
      ServerState state, int seat, bool isTsumo, int perPlayer) {
    final loserSeat = isTsumo ? null : state.lastDiscardedBy;
    final payments = ScoreCalculator.directPayments(
      perPlayer: perPlayer,
      isTsumo: isTsumo,
      winnerSeat: seat,
      loserSeat: loserSeat,
    );
    final total = payments[seat] ?? 0;
    final tierName = '$perPlayer点';

    state.pendingWin = WinProposal(
      seatIndex: seat,
      isTsumo: isTsumo,
      han: 0,
      fu: 0,
      tierName: tierName,
      totalPoints: total,
      payments: payments,
    );
    state.addLog(seat, 'declareWin',
        detail: '$tierName ${isTsumo ? "自摸" : "荣和"} $total点');
  }

  /// Confirm a pending win proposal.
  static void confirmWin(ServerState state, int seat) {
    final proposal = state.pendingWin;
    if (proposal == null) return;
    if (seat == proposal.seatIndex) return;

    proposal.confirmed.add(seat);

    if (proposal.confirmed.length >= 2) {
      _applyWin(state);
    }
  }

  /// Reject a pending win proposal.
  static void rejectWin(ServerState state, int seat) {
    final proposal = state.pendingWin;
    if (proposal == null) return;
    if (seat == proposal.seatIndex) return;

    proposal.rejected.add(seat);

    if (proposal.rejected.length >= 2) {
      state.addLog(proposal.seatIndex, 'winRejected');
      state.pendingWin = null;
    }
  }

  static void _applyWin(ServerState state) {
    final proposal = state.pendingWin!;
    for (final entry in proposal.payments.entries) {
      state.scores[entry.key] += entry.value;
    }
    state.riichiSticksOnTable = 0;
    state.suggestKeepDealer = proposal.seatIndex == state.dealerSeat;
    state.addLog(proposal.seatIndex, 'winConfirmed',
        detail: proposal.tierName);
    state.pendingWin = null;
  }

  /// Reveal next dora indicator.
  /// Blocked if noKanDora is set and initial dora already revealed.
  static void revealDora(ServerState state) {
    if (state.config.noKanDora && state.doraRevealed >= 1) return;
    if (state.doraRevealed < 5) {
      state.doraRevealed++;
      state.addLog(-1, 'revealDora');
    }
  }

  /// Choose missing suit for Sichuan mode (缺一门).
  static void chooseMissingSuit(ServerState state, int seat, int suit) {
    if (suit < 0 || suit > 2) return;
    state.seats[seat].missingSuit = suit;
    final suitNames = ['万', '筒', '索'];
    state.addLog(seat, 'chooseMissingSuit', detail: '缺${suitNames[suit]}');
  }

  /// Sort hand tiles by kind.
  static void sortHand(ServerState state, int seat) {
    state.seats[seat].handTileIds.sort((a, b) {
      final kindA = a >= 136 ? a : a ~/ 4;
      final kindB = b >= 136 ? b : b ~/ 4;
      if (kindA != kindB) return kindA.compareTo(kindB);
      return a.compareTo(b);
    });
  }

  /// Reveal hand to all players.
  static void showHand(ServerState state, int seat) {
    state.seats[seat].handRevealed = true;
    state.addLog(seat, 'showHand');
  }

  /// Hide hand again.
  static void hideHand(ServerState state, int seat) {
    state.seats[seat].handRevealed = false;
  }

  /// Undo last discard (return to hand).
  static void undoDiscard(ServerState state, int seat) {
    if (state.lastDiscardedBy != seat) return;
    final seatData = state.seats[seat];
    if (seatData.discards.isEmpty) return;

    if (seatData.discards.last.isRiichiDiscard) return;

    final lastDiscard = seatData.discards.removeLast();
    seatData.handTileIds.add(lastDiscard.tileId);
    state.lastDiscardedBy = null;
    state.lastDiscardedTileId = null;
    state.currentTurn = seat;
    state.hasDrawnThisTurn = true;
    state.addLog(seat, 'undoDiscard', tileId: lastDiscard.tileId);
  }

  /// Start a new round.
  static void newRound(
      ServerState state, Random random, bool keepDealer) {
    if (keepDealer) {
      state.honbaCount += 1;
    } else {
      state.honbaCount = 0;
      state.dealerSeat = (state.dealerSeat + 1) % 4;
      state.roundNumber += 1;
      if (state.roundNumber >= 4) {
        state.roundNumber = 0;
        state.roundWind = (state.roundWind + 1) % 4;
      }
    }
    deal(state, random);
  }

  /// Propose point exchange.
  static void exchangePropose(
      ServerState state, int fromSeat, int toSeat, int amount) {
    state.pendingExchange = ExchangeProposal(
      fromSeat: fromSeat,
      toSeat: toSeat,
      amount: amount,
    );
    state.addLog(fromSeat, 'exchangePropose',
        detail: '→ ${state.nicknames[toSeat]} $amount点');
  }

  /// Confirm pending exchange.
  static void exchangeConfirm(ServerState state, int seat) {
    final proposal = state.pendingExchange;
    if (proposal == null) return;
    if (seat != proposal.toSeat) return;

    state.scores[proposal.fromSeat] -= proposal.amount;
    state.scores[proposal.toSeat] += proposal.amount;
    state.addLog(seat, 'exchangeConfirmed',
        detail: '${proposal.amount}点');
    state.pendingExchange = null;
  }

  /// Reject pending exchange.
  static void exchangeReject(ServerState state, int seat) {
    final proposal = state.pendingExchange;
    if (proposal == null) return;
    if (seat != proposal.toSeat) return;

    state.addLog(seat, 'exchangeRejected');
    state.pendingExchange = null;
  }

  /// Manually adjust a seat's score.
  static void adjustScore(ServerState state, int targetSeat, int delta) {
    state.scores[targetSeat] += delta;
    state.addLog(targetSeat, 'adjustScore', detail: '${delta > 0 ? "+" : ""}$delta');
  }
}
