import 'dart:math';
import 'package:test/test.dart';
import 'package:mahjong_server/game_config.dart';
import 'package:mahjong_server/models.dart';
import 'package:mahjong_server/table_logic.dart';
import 'package:mahjong_server/score_calculator.dart';
import 'package:mahjong_server/sichuan_ai.dart';

/// Helper to create a dealt state with config applied.
ServerState _dealtState({
  GameConfig config = const GameConfig(),
  int seed = 42,
}) {
  final state = ServerState();
  state.applyConfig(config);
  TableLogic.deal(state, Random(seed));
  return state;
}

/// Count total tiles in play (hands + melds + discards + wall + dead wall + flowers).
int _totalTiles(ServerState state) {
  int total = state.liveTileIds.length + state.deadWallTileIds.length;
  if (state.baidaReferenceTileId != null) total += 1;
  for (final seat in state.seats) {
    total += seat.handTileIds.length;
    total += seat.flowerTileIds.length;
    for (final meld in seat.melds) {
      total += meld.tileIds.length;
    }
    total += seat.discards.length;
  }
  return total;
}

void main() {
  // ═══════════════════════════════════════════════════════════════
  // 1. RIICHI FULL GAME SIMULATION
  // ═══════════════════════════════════════════════════════════════
  group('Riichi full game simulation', () {
    test('deal → draw/discard → chi → pon → riichi → tsumo win', () {
      final state = _dealtState(
        config: const GameConfig(tileCount: 136, isRiichi: true),
        seed: 100,
      );
      final dealer = state.dealerSeat;

      // Verify initial state
      expect(state.config.isRiichi, true);
      expect(state.config.hasDora, true);
      expect(state.config.hasDeadWall, true);
      expect(state.deadWallTileIds.length, 14);
      expect(state.doraRevealed, 1);
      expect(state.seats[dealer].handTileIds.length, 14);
      for (int i = 0; i < 4; i++) {
        if (i != dealer) {
          expect(state.seats[i].handTileIds.length, 13);
        }
      }

      // Tile conservation: all 136 tiles accounted for
      expect(_totalTiles(state), 136);

      // Dealer discards
      final dealerHand = state.seats[dealer].handTileIds;
      TableLogic.discard(state, dealer, dealerHand.first);
      expect(state.currentTurn, (dealer + 1) % 4);
      expect(state.hasDrawnThisTurn, false);
      expect(_totalTiles(state), 136);

      // Next player draws and discards — 3 full cycles
      for (int cycle = 0; cycle < 3; cycle++) {
        for (int i = 0; i < 4; i++) {
          final seat = (dealer + 1 + i) % 4;
          if (cycle == 0 && i == 0) {
            // First player after dealer needs to draw
            state.currentTurn = seat;
            state.hasDrawnThisTurn = false;
            TableLogic.draw(state, seat);
            expect(state.seats[seat].handTileIds.length, 14);
          } else {
            state.currentTurn = seat;
            state.hasDrawnThisTurn = false;
            TableLogic.draw(state, seat);
          }
          TableLogic.discard(
              state, seat, state.seats[seat].handTileIds.first);
          expect(_totalTiles(state), 136);
        }
      }

      // Set up a chi scenario: seat 1 chis from seat 0's discard
      final chiSeat = 1;
      final prevSeat = 0;
      // Give seat 1 two consecutive tiles and arrange a matching discard
      state.seats[chiSeat].handTileIds.clear();
      state.seats[chiSeat].handTileIds
          .addAll([4, 8, 20, 24, 28, 32, 36, 40, 44, 48, 52, 56, 60]);
      // Discard tile 0 (1m) from seat 0 — seat 1 has 4 (2m) and 8 (3m)
      state.seats[prevSeat].discards.add(DiscardEntry(tileId: 0));
      state.lastDiscardedBy = prevSeat;
      state.lastDiscardedTileId = 0;

      TableLogic.chi(state, chiSeat, [4, 8]);
      expect(state.seats[chiSeat].melds.length, 1);
      expect(state.seats[chiSeat].melds.first.type, 'chi');
      expect(state.seats[chiSeat].melds.first.calledFrom, prevSeat);
      expect(state.currentTurn, chiSeat);
      expect(state.hasDrawnThisTurn, true); // chi counts as draw

      // After chi, player must discard
      TableLogic.discard(
          state, chiSeat, state.seats[chiSeat].handTileIds.first);

      // Set up pon scenario: seat 2 pons a tile
      final ponSeat = 2;
      state.seats[ponSeat].handTileIds.clear();
      state.seats[ponSeat].handTileIds
          .addAll([12, 13, 16, 20, 24, 28, 32, 36, 40, 44, 48, 52, 56]);
      // Someone discards tile 14 (kind 3 = 4m), seat 2 has 12, 13 (kind 3)
      state.seats[3].discards.add(DiscardEntry(tileId: 14));
      state.lastDiscardedBy = 3;
      state.lastDiscardedTileId = 14;

      TableLogic.pon(state, ponSeat, [12, 13]);
      expect(state.seats[ponSeat].melds.length, 1);
      expect(state.seats[ponSeat].melds.first.type, 'pon');
      expect(state.currentTurn, ponSeat);

      // Riichi declaration
      final riichiSeat = 3;
      state.currentTurn = riichiSeat;
      state.hasDrawnThisTurn = false;
      TableLogic.draw(state, riichiSeat);
      final riichiTile = state.seats[riichiSeat].handTileIds.first;
      final scoreBefore = state.scores[riichiSeat];

      TableLogic.riichi(state, riichiSeat, riichiTile);
      expect(state.seats[riichiSeat].isRiichi, true);
      expect(state.scores[riichiSeat], scoreBefore - 1000);
      expect(state.riichiSticksOnTable, 1);
      expect(state.seats[riichiSeat].discards.last.isRiichiDiscard, true);

      // Tsumo win declaration
      final winSeat = 0;
      final scoresBefore = List<int>.from(state.scores);
      TableLogic.declareWin(state, winSeat, true, 3, 30);

      expect(state.pendingWin, isNotNull);
      expect(state.pendingWin!.seatIndex, winSeat);
      expect(state.pendingWin!.isTsumo, true);
      expect(state.pendingWin!.han, 3);
      expect(state.pendingWin!.fu, 30);

      // Other players confirm
      TableLogic.confirmWin(state, 1);
      expect(state.pendingWin, isNotNull); // 1 confirm not enough
      TableLogic.confirmWin(state, 2);
      expect(state.pendingWin, isNull); // 2 confirms → applied

      // Scores changed
      expect(state.scores[winSeat] > scoresBefore[winSeat], true);
      // Total scores always sum to starting total (25000 * 4 = 100000)
      // Riichi stick was deducted from scores and put on table, then
      // returned to winner — so total is restored to 100000.
      final totalAfter = state.scores.fold<int>(0, (a, b) => a + b);
      expect(totalAfter, 100000);
    });

    test('ron win: loser pays, others unaffected', () {
      final state = _dealtState(seed: 200);
      final winSeat = 1;
      final loserSeat = 2;

      // Set up a discard
      state.lastDiscardedBy = loserSeat;
      state.lastDiscardedTileId = 50;

      final scoresBefore = List<int>.from(state.scores);
      TableLogic.declareWin(state, winSeat, false, 4, 30);

      expect(state.pendingWin!.isTsumo, false);

      TableLogic.confirmWin(state, 0);
      TableLogic.confirmWin(state, 3);
      expect(state.pendingWin, isNull);

      // Winner gained, loser lost, others unchanged
      expect(state.scores[winSeat] > scoresBefore[winSeat], true);
      expect(state.scores[loserSeat] < scoresBefore[loserSeat], true);
      expect(state.scores[0], scoresBefore[0]);
      expect(state.scores[3], scoresBefore[3]);
    });

    test('honba affects scoring', () {
      final state = _dealtState(seed: 300);
      state.honbaCount = 2;

      // Ron with honba
      state.lastDiscardedBy = 1;
      TableLogic.declareWin(state, 0, false, 3, 30);
      final withHonba = state.pendingWin!.totalPoints;

      // Compare without honba
      final state2 = _dealtState(seed: 300);
      state2.lastDiscardedBy = 1;
      TableLogic.declareWin(state2, 0, false, 3, 30);
      final withoutHonba = state2.pendingWin!.totalPoints;

      expect(withHonba > withoutHonba, true);
      expect(withHonba - withoutHonba, 600); // 2 honba * 300
    });
  });

  // ═══════════════════════════════════════════════════════════════
  // 2. RIICHI DEAD WALL MAINTENANCE
  // ═══════════════════════════════════════════════════════════════
  group('Riichi dead wall maintenance after kan', () {
    test('closed kan → drawDeadWall → dead wall stays at 14', () {
      final state = _dealtState(
        config: const GameConfig(tileCount: 136, isRiichi: true),
        seed: 50,
      );
      final seat = state.dealerSeat;

      // Give player 4 of the same tile for kan
      state.seats[seat].handTileIds.clear();
      state.seats[seat].handTileIds
          .addAll([0, 1, 2, 3, 8, 12, 16, 20, 24, 28, 32, 36, 40, 44]);

      final wallBefore = state.liveTileIds.length;
      final deadBefore = state.deadWallTileIds.length;
      expect(deadBefore, 14);

      // Closed kan
      TableLogic.closedKan(state, seat, [0, 1, 2, 3]);
      expect(state.hasDrawnThisTurn, false);
      expect(state.seats[seat].melds.first.type, 'closedKan');

      // Draw from dead wall (back of live wall + transfer)
      TableLogic.drawDeadWall(state, seat);

      expect(state.deadWallTileIds.length, 14 + 1); // 14 original + 1 transferred
      expect(state.liveTileIds.length, wallBefore - 2); // -1 drawn, -1 transferred
      expect(state.hasDrawnThisTurn, true);
      expect(_totalTiles(state), 136);
    });

    test('open kan → drawDeadWall → dead wall maintained', () {
      final state = _dealtState(
        config: const GameConfig(tileCount: 136, isRiichi: true),
        seed: 55,
      );
      final seat = 1;

      state.seats[seat].handTileIds.clear();
      state.seats[seat].handTileIds
          .addAll([0, 1, 2, 8, 12, 16, 20, 24, 28, 32, 36, 40, 44]);
      state.seats[0].discards.add(DiscardEntry(tileId: 3));
      state.lastDiscardedBy = 0;
      state.lastDiscardedTileId = 3;

      final wallBefore = state.liveTileIds.length;

      TableLogic.openKan(state, seat, [0, 1, 2]);
      expect(state.hasDrawnThisTurn, false);

      TableLogic.drawDeadWall(state, seat);
      expect(state.deadWallTileIds.length, 15); // 14 + 1 transferred
      expect(state.liveTileIds.length, wallBefore - 2);
    });

    test('added kan → drawDeadWall → dead wall maintained', () {
      final state = _dealtState(
        config: const GameConfig(tileCount: 136, isRiichi: true),
        seed: 60,
      );
      final seat = 0;

      state.seats[seat].melds.add(MeldData(
        type: 'pon',
        tileIds: [0, 1, 2],
        calledFrom: 1,
        calledTileId: 2,
      ));
      state.seats[seat].handTileIds.remove(3);
      state.seats[seat].handTileIds.add(3);

      final wallBefore = state.liveTileIds.length;

      TableLogic.addedKan(state, seat, 3, 0);
      expect(state.seats[seat].melds.first.type, 'addedKan');
      expect(state.hasDrawnThisTurn, false);

      TableLogic.drawDeadWall(state, seat);
      expect(state.deadWallTileIds.length, 15);
      expect(state.liveTileIds.length, wallBefore - 2);
    });

    test('multiple kans → dead wall grows, live wall shrinks by 2 each', () {
      final state = _dealtState(
        config: const GameConfig(tileCount: 136, isRiichi: true),
        seed: 70,
      );
      final seat = state.dealerSeat;

      // Prepare hand with two sets of 4 identical tiles
      state.seats[seat].handTileIds.clear();
      state.seats[seat].handTileIds.addAll([
        0, 1, 2, 3, // kan set 1
        4, 5, 6, 7, // kan set 2
        12, 16, 20, 24, 28, 32, // filler
      ]);

      final wallStart = state.liveTileIds.length;

      // First kan + draw
      TableLogic.closedKan(state, seat, [0, 1, 2, 3]);
      TableLogic.drawDeadWall(state, seat);
      expect(state.deadWallTileIds.length, 15);
      expect(state.liveTileIds.length, wallStart - 2);

      // Discard to reset draw flag
      state.hasDrawnThisTurn = false;

      // Second kan + draw
      TableLogic.closedKan(state, seat, [4, 5, 6, 7]);
      TableLogic.drawDeadWall(state, seat);
      expect(state.deadWallTileIds.length, 16);
      expect(state.liveTileIds.length, wallStart - 4);
    });

    test('dora reveal after kan', () {
      final state = _dealtState(
        config: const GameConfig(tileCount: 136, isRiichi: true),
      );
      expect(state.doraRevealed, 1);

      TableLogic.revealDora(state);
      expect(state.doraRevealed, 2);

      TableLogic.revealDora(state);
      expect(state.doraRevealed, 3);

      // Cap at 5
      for (int i = 0; i < 10; i++) {
        TableLogic.revealDora(state);
      }
      expect(state.doraRevealed, 5);
    });

    test('noKanDora prevents dora reveal after initial', () {
      final state = _dealtState(
        config: const GameConfig(
          tileCount: 136,
          isRiichi: true,
          riichiMode: 'custom',
          noKanDora: true,
        ),
      );
      expect(state.doraRevealed, 1);

      TableLogic.revealDora(state);
      expect(state.doraRevealed, 1); // blocked
    });
  });

  // ═══════════════════════════════════════════════════════════════
  // 3. SICHUAN FULL GAME SIMULATION
  // ═══════════════════════════════════════════════════════════════
  group('Sichuan full game simulation', () {
    const sichuanConfig = GameConfig(tileCount: 108, isRiichi: false);

    test('deal → choose missing suit → draw/discard cycles → win', () {
      final state = _dealtState(config: sichuanConfig, seed: 111);
      final dealer = state.dealerSeat;

      // Verify Sichuan setup
      expect(state.config.isSichuan, true);
      expect(state.deadWallTileIds.length, 0);
      expect(state.doraRevealed, 0);
      expect(_totalTiles(state), 108);

      // All tiles should be within 0-107 (no honors)
      for (final seat in state.seats) {
        for (final id in seat.handTileIds) {
          expect(id, lessThan(108));
          expect(id, greaterThanOrEqualTo(0));
        }
      }

      // Choose missing suit for all players
      for (int i = 0; i < 4; i++) {
        final suit = SichuanAi.chooseMissingSuit(state.seats[i].handTileIds);
        TableLogic.chooseMissingSuit(state, i, suit);
        expect(state.seats[i].missingSuit, isNotNull);
        expect(state.seats[i].missingSuit, inInclusiveRange(0, 2));
      }

      // Simulate 5 draw/discard cycles
      TableLogic.discard(
          state, dealer, state.seats[dealer].handTileIds.first);
      for (int cycle = 0; cycle < 5; cycle++) {
        for (int i = 0; i < 4; i++) {
          final seat = state.currentTurn;
          state.hasDrawnThisTurn = false;
          TableLogic.draw(state, seat);
          TableLogic.discard(
              state, seat, state.seats[seat].handTileIds.first);
          expect(_totalTiles(state), 108);
        }
      }

      // Sichuan win declaration
      TableLogic.declareWinSichuan(state, 0, true, 2);
      expect(state.pendingWin, isNotNull);
      expect(state.pendingWin!.totalPoints, 12); // 2^2=4 * 3 players = 12
      expect(state.pendingWin!.payments[1], -4);
      expect(state.pendingWin!.payments[2], -4);
      expect(state.pendingWin!.payments[3], -4);

      // Confirm
      TableLogic.confirmWin(state, 1);
      TableLogic.confirmWin(state, 2);
      expect(state.pendingWin, isNull);
    });

    test('missing suit validation rejects invalid values', () {
      final state = _dealtState(config: sichuanConfig);
      TableLogic.chooseMissingSuit(state, 0, -1);
      expect(state.seats[0].missingSuit, isNull);

      TableLogic.chooseMissingSuit(state, 0, 3);
      expect(state.seats[0].missingSuit, isNull);

      TableLogic.chooseMissingSuit(state, 0, 5);
      expect(state.seats[0].missingSuit, isNull);
    });

    test('Sichuan pon scenario', () {
      final state = _dealtState(config: sichuanConfig, seed: 222);

      // Set up pon scenario
      final ponSeat = 1;
      final discardSeat = 0;
      state.seats[ponSeat].handTileIds.clear();
      // Give two 1m tiles (kind 0)
      state.seats[ponSeat].handTileIds
          .addAll([0, 1, 4, 8, 72, 76, 80, 84, 88, 92, 96, 100, 104]);
      state.seats[discardSeat].discards.add(DiscardEntry(tileId: 2));
      state.lastDiscardedBy = discardSeat;
      state.lastDiscardedTileId = 2;

      TableLogic.pon(state, ponSeat, [0, 1]);
      expect(state.seats[ponSeat].melds.length, 1);
      expect(state.seats[ponSeat].melds.first.type, 'pon');
      expect(state.seats[ponSeat].melds.first.tileIds, containsAll([0, 1, 2]));
      expect(state.currentTurn, ponSeat);
    });

    test('Sichuan kan draws from front (live wall)', () {
      final state = _dealtState(config: sichuanConfig, seed: 333);
      final seat = state.dealerSeat;

      // Set up closed kan
      state.seats[seat].handTileIds.clear();
      state.seats[seat].handTileIds
          .addAll([0, 1, 2, 3, 8, 72, 76, 80, 84, 88, 92, 96, 100, 104]);

      final firstWallTile = state.liveTileIds.first;

      TableLogic.closedKan(state, seat, [0, 1, 2, 3]);
      expect(state.hasDrawnThisTurn, false);

      // In Sichuan, draw from FRONT
      TableLogic.draw(state, seat);
      expect(state.seats[seat].handTileIds.last, firstWallTile);
      expect(state.hasDrawnThisTurn, true);

      // No dead wall transfer (Sichuan has no dead wall)
      expect(state.deadWallTileIds.length, 0);
    });

    test('Sichuan ron: loser pays 2^han', () {
      final state = _dealtState(config: sichuanConfig, seed: 444);
      state.lastDiscardedBy = 2;
      state.lastDiscardedTileId = 50;

      TableLogic.declareWinSichuan(state, 0, false, 3);
      expect(state.pendingWin!.payments[0], 8); // 2^3 = 8
      expect(state.pendingWin!.payments[2], -8);
      expect(state.pendingWin!.payments[1], 0);
      expect(state.pendingWin!.payments[3], 0);
    });

    test('Sichuan scoring: 1-5 han covers full range', () {
      for (int han = 1; han <= 5; han++) {
        final payments = ScoreCalculator.sichuanPayments(
          han: han,
          isTsumo: true,
          winnerSeat: 0,
          loserSeat: null,
        );
        final perPlayer = 1 << han;
        expect(payments[1], -perPlayer);
        expect(payments[2], -perPlayer);
        expect(payments[3], -perPlayer);
        expect(payments[0], perPlayer * 3);
        // Zero-sum
        final sum = payments.values.fold<int>(0, (a, b) => a + b);
        expect(sum, 0);
      }
    });
  });

  // ═══════════════════════════════════════════════════════════════
  // 4. SICHUAN AI COMPREHENSIVE TESTS
  // ═══════════════════════════════════════════════════════════════
  group('Sichuan AI comprehensive', () {
    test('chooseMissingSuit picks suit with fewest tiles - tie breaks', () {
      // All three suits have equal count → should pick suit 0 (first)
      final hand = [0, 36, 72]; // 1 man, 1 pin, 1 sou
      expect(SichuanAi.chooseMissingSuit(hand), 0);
    });

    test('chooseMissingSuit with empty suit picks it', () {
      // 0 man, 5 pin, 5 sou → should pick man
      final hand = [36, 40, 44, 48, 52, 72, 76, 80, 84, 88];
      expect(SichuanAi.chooseMissingSuit(hand), 0);
    });

    test('chooseDiscard prioritizes missing suit tiles', () {
      // Hand: man + pin + sou, missing pin (suit 1)
      final hand = [0, 4, 8, 36, 40, 72, 76, 80, 84, 88, 92, 96, 100];
      final discard = SichuanAi.chooseDiscard(hand, 1);
      // Should discard a pin tile (kind 9-17, IDs 36-71)
      expect(discard >= 36 && discard < 72, true,
          reason: 'Should discard from missing suit (pin)');
    });

    test('chooseDiscard picks most isolated tile', () {
      // All pin cleared, only man + sou left. Missing pin.
      // Hand has 1m, 2m, 3m (connected) and isolated 9s
      final hand = [0, 4, 8, 72, 76, 80, 84, 88, 92, 96, 100, 104, 107];
      final discard = SichuanAi.chooseDiscard(hand, 1);
      // Should discard from hand, not crash
      expect(hand.contains(discard), true);
    });

    test('shouldPon rejects missing suit tile', () {
      final hand = [36, 37, 0, 4, 72, 76, 80, 84, 88, 92, 96, 100, 104];
      // Kind 9 (1p) — should not pon if missing pin (suit 1)
      expect(SichuanAi.shouldPon(hand, 9, 1), false);
      // But should pon if missing man (suit 0)
      expect(SichuanAi.shouldPon(hand, 9, 0), true);
    });

    test('shouldPon requires at least 2 matching tiles', () {
      final hand = [0, 4, 8, 72, 76, 80, 84, 88, 92, 96, 100, 104, 107];
      // Only 1 of kind 0 in hand → can't pon
      expect(SichuanAi.shouldPon(hand, 0, 1), false);
    });

    test('isWinningHand: all triplets win', () {
      final hand = [
        0, 1, 2, // 1m x3
        4, 5, 6, // 2m x3
        8, 9, 10, // 3m x3
        72, 73, 74, // 1s x3
        76, 77, // 2s pair
      ];
      expect(SichuanAi.isWinningHand(hand, 1), true);
    });

    test('isWinningHand: mixed sequences and triplets', () {
      final hand = [
        0, 4, 8, // 1m 2m 3m (sequence)
        12, 16, 20, // 4m 5m 6m (sequence)
        72, 73, 74, // 1s x3 (triplet)
        76, 80, 84, // 2s 3s 4s (sequence)
        88, 89, // 5s pair
      ];
      expect(SichuanAi.isWinningHand(hand, 1), true);
    });

    test('isWinningHand: rejects hand with missing suit tiles', () {
      final hand = [
        0, 1, 2, 4, 5, 6, 8, 9, 10,
        36, 37, // pin tiles — invalid if missing pin
        72, 73, 74,
      ];
      expect(SichuanAi.isWinningHand(hand, 1), false);
    });

    test('isWinningHand: rejects non-winning hand', () {
      // Random tiles that don't form valid groups
      final hand = [0, 4, 12, 16, 24, 72, 76, 84, 88, 96, 100, 104, 107, 103];
      expect(SichuanAi.isWinningHand(hand, 1), false);
    });

    test('countHan: base 1 han for standard win', () {
      final hand = [
        0, 4, 8, // 1m 2m 3m
        12, 16, 20, // 4m 5m 6m
        72, 76, 80, // 1s 2s 3s
        84, 88, 92, // 4s 5s 6s
        96, 97, // 7s pair
      ];
      expect(SichuanAi.countHan(hand, 1), 1);
    });

    test('countHan: +1 for all triplets (对对和)', () {
      final hand = [
        0, 1, 2, // 1m x3
        4, 5, 6, // 2m x3
        8, 9, 10, // 3m x3
        72, 73, 74, // 1s x3
        76, 77, // 2s pair
      ];
      expect(SichuanAi.countHan(hand, 1), 2);
    });

    test('countHan: +1 for single suit (清一色)', () {
      final hand = [
        0, 4, 8, // 1m 2m 3m
        12, 16, 20, // 4m 5m 6m
        24, 25, 26, // 7m x3
        28, 29, 30, // 8m x3
        32, 33, // 9m pair
      ];
      expect(SichuanAi.countHan(hand, 1), 2);
    });

    test('countHan: +2 for all triplets + single suit', () {
      final hand = [
        0, 1, 2, // 1m x3
        4, 5, 6, // 2m x3
        8, 9, 10, // 3m x3
        12, 13, 14, // 4m x3
        16, 17, // 5m pair
      ];
      expect(SichuanAi.countHan(hand, 1), 3);
    });

    test('countHan: capped at 5', () {
      // Even extreme hands can't exceed 5
      final hand = [
        0, 1, 2, 4, 5, 6, 8, 9, 10, 12, 13, 14, 16, 17,
      ];
      final han = SichuanAi.countHan(hand, 1);
      expect(han, lessThanOrEqualTo(5));
    });
  });

  // ═══════════════════════════════════════════════════════════════
  // 5. GUOBIAO FULL GAME SIMULATION
  // ═══════════════════════════════════════════════════════════════
  group('Guobiao full game simulation', () {
    const guobiaoConfig =
        GameConfig(tileCount: 136, isRiichi: false, startingPoints: 0);

    test('deal → no dead wall, no dora', () {
      final state = _dealtState(config: guobiaoConfig, seed: 555);

      expect(state.config.isRiichi, false);
      expect(state.config.hasDora, false);
      expect(state.config.hasDeadWall, false);
      expect(state.deadWallTileIds.length, 0);
      expect(state.doraRevealed, 0);
      expect(_totalTiles(state), 136);
    });

    test('full draw/discard cycle with chi and pon', () {
      final state = _dealtState(config: guobiaoConfig, seed: 666);
      final dealer = state.dealerSeat;

      // Dealer discards
      TableLogic.discard(
          state, dealer, state.seats[dealer].handTileIds.first);

      // 3 rounds of draw/discard
      for (int round = 0; round < 3; round++) {
        for (int i = 0; i < 4; i++) {
          final seat = state.currentTurn;
          state.hasDrawnThisTurn = false;
          TableLogic.draw(state, seat);
          TableLogic.discard(
              state, seat, state.seats[seat].handTileIds.first);
        }
      }
      expect(_totalTiles(state), 136);

      // Chi
      final chiSeat = 1;
      state.seats[chiSeat].handTileIds.clear();
      state.seats[chiSeat].handTileIds
          .addAll([4, 8, 20, 24, 28, 108, 112, 116, 120, 124, 128, 132, 135]);
      state.seats[0].discards.add(DiscardEntry(tileId: 0));
      state.lastDiscardedBy = 0;
      state.lastDiscardedTileId = 0;

      TableLogic.chi(state, chiSeat, [4, 8]);
      expect(state.seats[chiSeat].melds.length, 1);
      expect(state.seats[chiSeat].melds.first.type, 'chi');

      // Discard after chi
      TableLogic.discard(
          state, chiSeat, state.seats[chiSeat].handTileIds.first);

      // Direct win declaration (Guobiao uses direct entry)
      final winSeat = 2;
      TableLogic.declareWinDirect(state, winSeat, true, 8);

      expect(state.pendingWin, isNotNull);
      expect(state.pendingWin!.totalPoints, 24); // 8 * 3 players
      expect(state.pendingWin!.payments[0], -8);
      expect(state.pendingWin!.payments[1], -8);
      expect(state.pendingWin!.payments[3], -8);
      expect(state.pendingWin!.payments[winSeat], 24);

      // Confirm
      TableLogic.confirmWin(state, 0);
      TableLogic.confirmWin(state, 1);
      expect(state.pendingWin, isNull);
    });

    test('Guobiao kan draws from back (no dead wall transfer)', () {
      final state = _dealtState(config: guobiaoConfig, seed: 777);
      final seat = state.dealerSeat;

      state.seats[seat].handTileIds.clear();
      state.seats[seat].handTileIds
          .addAll([0, 1, 2, 3, 8, 12, 108, 112, 116, 120, 124, 128, 132, 135]);

      final wallBefore = state.liveTileIds.length;
      final lastWallTile = state.liveTileIds.last;

      // Closed kan
      TableLogic.closedKan(state, seat, [0, 1, 2, 3]);

      // Draw from back (drawDeadWall without dead wall maintenance)
      TableLogic.drawDeadWall(state, seat);
      expect(state.seats[seat].handTileIds.last, lastWallTile);
      expect(state.deadWallTileIds.length, 0); // no dead wall transfer
      expect(state.liveTileIds.length, wallBefore - 1); // only -1 (no transfer)
    });

    test('Guobiao direct ron: only loser pays', () {
      final state = _dealtState(config: guobiaoConfig, seed: 888);
      state.lastDiscardedBy = 3;

      TableLogic.declareWinDirect(state, 1, false, 16);
      expect(state.pendingWin!.payments[1], 16);
      expect(state.pendingWin!.payments[3], -16);
      expect(state.pendingWin!.payments[0], 0);
      expect(state.pendingWin!.payments[2], 0);
    });
  });

  // ═══════════════════════════════════════════════════════════════
  // 6. FLOWER TILE HANDLING (144 / 152)
  // ═══════════════════════════════════════════════════════════════
  group('Flower tile handling', () {
    test('144 tiles: drawFlower replaces from back of wall', () {
      final config = const GameConfig(
          tileCount: 144, isRiichi: false, startingPoints: 0);
      final state = _dealtState(config: config, seed: 999);

      final seat = state.dealerSeat;
      // Add a flower tile to hand
      final flowerTile = 136;
      state.seats[seat].handTileIds.add(flowerTile);
      final handBefore = state.seats[seat].handTileIds.length;
      final wallBefore = state.liveTileIds.length;
      final lastWallTile = state.liveTileIds.last;

      TableLogic.drawFlower(state, seat, flowerTile);

      // Flower moved to display
      expect(state.seats[seat].flowerTileIds.contains(flowerTile), true);
      expect(state.seats[seat].handTileIds.contains(flowerTile), false);
      // Replacement drawn from back
      expect(state.seats[seat].handTileIds.last, lastWallTile);
      // Hand size unchanged (removed flower, added replacement)
      expect(state.seats[seat].handTileIds.length, handBefore - 1 + 1);
      expect(state.liveTileIds.length, wallBefore - 1);
    });

    test('multiple flowers drawn in succession', () {
      final config = const GameConfig(
          tileCount: 144, isRiichi: false, startingPoints: 0);
      final state = _dealtState(config: config, seed: 1000);

      final seat = state.dealerSeat;
      // Add 3 flowers to hand
      state.seats[seat].handTileIds.addAll([136, 137, 138]);
      final wallBefore = state.liveTileIds.length;

      TableLogic.drawFlower(state, seat, 136);
      expect(state.seats[seat].flowerTileIds.length, 1);

      TableLogic.drawFlower(state, seat, 137);
      expect(state.seats[seat].flowerTileIds.length, 2);

      TableLogic.drawFlower(state, seat, 138);
      expect(state.seats[seat].flowerTileIds.length, 3);

      // 3 tiles drawn from wall
      expect(state.liveTileIds.length, wallBefore - 3);
    });

    test('drawFlower with invalid tile does nothing', () {
      final config = const GameConfig(
          tileCount: 144, isRiichi: false, startingPoints: 0);
      final state = _dealtState(config: config, seed: 1001);

      final seat = state.dealerSeat;
      final wallBefore = state.liveTileIds.length;

      TableLogic.drawFlower(state, seat, 999);
      expect(state.seats[seat].flowerTileIds, isEmpty);
      expect(state.liveTileIds.length, wallBefore);
    });

    test('Suzhou 152 tiles: flower identification', () {
      final config = const GameConfig(
          tileCount: 152, isRiichi: false, startingPoints: 0);

      // Tiles 136-143: flowers
      expect(config.isFlowerTile(136), true);
      expect(config.isFlowerTile(143), true);
      // Tiles 144-147: baida (NOT flowers in Suzhou)
      expect(config.isFlowerTile(144), false);
      expect(config.isFlowerTile(147), false);
      // Tiles 148-151: flowers
      expect(config.isFlowerTile(148), true);
      expect(config.isFlowerTile(151), true);
      // Regular tiles: not flowers
      expect(config.isFlowerTile(0), false);
      expect(config.isFlowerTile(135), false);
    });
  });

  // ═══════════════════════════════════════════════════════════════
  // 7. SHANGHAI 百搭 (BAIDA) HANDLING
  // ═══════════════════════════════════════════════════════════════
  group('Shanghai baida handling', () {
    test('deal flips baida reference tile', () {
      final config = const GameConfig(
        tileCount: 144,
        isRiichi: false,
        hasBaida: true,
        startingPoints: 0,
      );
      final state = _dealtState(config: config, seed: 1100);

      expect(state.baidaReferenceTileId, isNotNull);
      expect(state.config.isShanghai, true);
      // Reference tile consumed from wall
      final totalDealt = state.seats
          .fold<int>(0, (sum, s) => sum + s.handTileIds.length);
      expect(totalDealt + state.liveTileIds.length + 1, 144);
    });

    test('non-baida variants have null reference', () {
      final configs = [
        const GameConfig(tileCount: 136, isRiichi: true),
        const GameConfig(tileCount: 108, isRiichi: false),
        const GameConfig(tileCount: 144, isRiichi: false, hasBaida: false),
      ];
      for (final config in configs) {
        final state = _dealtState(config: config, seed: 1200);
        expect(state.baidaReferenceTileId, isNull);
      }
    });
  });

  // ═══════════════════════════════════════════════════════════════
  // 8. WIN PROPOSAL FLOW (detailed)
  // ═══════════════════════════════════════════════════════════════
  group('Win proposal detailed flow', () {
    test('exactly 2 confirms needed', () {
      final state = _dealtState();
      TableLogic.declareWin(state, 0, true, 3, 30);

      TableLogic.confirmWin(state, 1);
      expect(state.pendingWin, isNotNull);
      expect(state.pendingWin!.confirmed.length, 1);

      TableLogic.confirmWin(state, 2);
      expect(state.pendingWin, isNull); // applied
    });

    test('exactly 2 rejects needed', () {
      final state = _dealtState();
      TableLogic.declareWin(state, 0, true, 3, 30);

      TableLogic.rejectWin(state, 1);
      expect(state.pendingWin, isNotNull);
      expect(state.pendingWin!.rejected.length, 1);

      TableLogic.rejectWin(state, 2);
      expect(state.pendingWin, isNull); // cancelled
    });

    test('1 confirm + 1 reject = still pending', () {
      final state = _dealtState();
      TableLogic.declareWin(state, 0, true, 3, 30);

      TableLogic.confirmWin(state, 1);
      TableLogic.rejectWin(state, 2);
      expect(state.pendingWin, isNotNull);
      expect(state.pendingWin!.confirmed.length, 1);
      expect(state.pendingWin!.rejected.length, 1);
    });

    test('winner self-confirm is ignored', () {
      final state = _dealtState();
      TableLogic.declareWin(state, 0, true, 3, 30);

      TableLogic.confirmWin(state, 0);
      expect(state.pendingWin!.confirmed, isEmpty);
    });

    test('winner self-reject is ignored', () {
      final state = _dealtState();
      TableLogic.declareWin(state, 0, true, 3, 30);

      TableLogic.rejectWin(state, 0);
      expect(state.pendingWin!.rejected, isEmpty);
    });

    test('duplicate confirm from same seat is counted once', () {
      final state = _dealtState();
      TableLogic.declareWin(state, 0, true, 3, 30);

      TableLogic.confirmWin(state, 1);
      TableLogic.confirmWin(state, 1);
      expect(state.pendingWin, isNotNull);
      expect(state.pendingWin!.confirmed.length, 1); // Set deduplicates
    });

    test('applied win modifies scores correctly', () {
      final state = _dealtState();
      final scoresBefore = List<int>.from(state.scores);

      // Tsumo 3 han 30 fu by non-dealer
      state.lastDiscardedBy = null;
      TableLogic.declareWin(state, 1, true, 3, 30);
      final payments = Map<int, int>.from(state.pendingWin!.payments);

      TableLogic.confirmWin(state, 2);
      TableLogic.confirmWin(state, 3);

      for (int i = 0; i < 4; i++) {
        expect(state.scores[i], scoresBefore[i] + payments[i]!);
      }
    });

    test('rejected win does not modify scores', () {
      final state = _dealtState();
      final scoresBefore = List<int>.from(state.scores);

      TableLogic.declareWin(state, 0, true, 5, 30);
      TableLogic.rejectWin(state, 1);
      TableLogic.rejectWin(state, 2);

      expect(state.scores, scoresBefore);
    });

    test('suggest keep dealer when dealer wins', () {
      final state = _dealtState();
      final dealer = state.dealerSeat;

      TableLogic.declareWin(state, dealer, true, 3, 30);
      TableLogic.confirmWin(state, (dealer + 1) % 4);
      TableLogic.confirmWin(state, (dealer + 2) % 4);

      expect(state.suggestKeepDealer, true);
    });

    test('no suggest keep dealer when non-dealer wins', () {
      final state = _dealtState();
      final nonDealer = (state.dealerSeat + 1) % 4;

      state.lastDiscardedBy = state.dealerSeat;
      TableLogic.declareWin(state, nonDealer, false, 3, 30);
      TableLogic.confirmWin(state, (nonDealer + 1) % 4);
      TableLogic.confirmWin(state, (nonDealer + 2) % 4);

      expect(state.suggestKeepDealer, false);
    });
  });

  // ═══════════════════════════════════════════════════════════════
  // 9. MULTI-ROUND SIMULATION
  // ═══════════════════════════════════════════════════════════════
  group('Multi-round simulation', () {
    test('4 non-keep rotations cycle through all dealers', () {
      final state = _dealtState(seed: 1300);
      final startDealer = state.dealerSeat;

      for (int i = 0; i < 4; i++) {
        expect(state.dealerSeat, (startDealer + i) % 4);
        TableLogic.newRound(state, Random(1300 + i), false);
      }

      // After 4 rotations, back to start dealer
      expect(state.dealerSeat, startDealer);
      expect(state.roundWind, 1); // Advanced to South
    });

    test('keep dealer increments honba', () {
      final state = _dealtState(seed: 1400);
      final dealer = state.dealerSeat;

      TableLogic.newRound(state, Random(1401), true);
      expect(state.dealerSeat, dealer);
      expect(state.honbaCount, 1);

      TableLogic.newRound(state, Random(1402), true);
      expect(state.dealerSeat, dealer);
      expect(state.honbaCount, 2);

      // Then rotate
      TableLogic.newRound(state, Random(1403), false);
      expect(state.dealerSeat, (dealer + 1) % 4);
      expect(state.honbaCount, 0);
    });

    test('round wind advances after full rotation', () {
      final state = _dealtState(seed: 1500);
      expect(state.roundWind, 0); // East

      // 4 rotations
      for (int i = 0; i < 4; i++) {
        TableLogic.newRound(state, Random(1500 + i), false);
      }
      expect(state.roundWind, 1); // South

      for (int i = 0; i < 4; i++) {
        TableLogic.newRound(state, Random(1600 + i), false);
      }
      expect(state.roundWind, 2); // West

      for (int i = 0; i < 4; i++) {
        TableLogic.newRound(state, Random(1700 + i), false);
      }
      expect(state.roundWind, 3); // North
    });

    test('scores persist across rounds', () {
      final state = _dealtState(seed: 1800);

      // Win in round 1
      TableLogic.declareWin(state, 0, true, 3, 30);
      TableLogic.confirmWin(state, 1);
      TableLogic.confirmWin(state, 2);
      final scoresAfterR1 = List<int>.from(state.scores);

      // New round — scores preserved
      TableLogic.newRound(state, Random(1801), false);
      expect(state.scores, scoresAfterR1);
      expect(state.gameStarted, true);

      // Win in round 2
      TableLogic.declareWin(state, 2, true, 5, 30);
      TableLogic.confirmWin(state, 0);
      TableLogic.confirmWin(state, 1);

      // Scores changed from round 1 values
      expect(state.scores[2] > scoresAfterR1[2], true);
    });

    test('new round resets game state but not scores', () {
      final state = _dealtState(seed: 1900);

      // Simulate some game actions
      TableLogic.discard(
          state, state.dealerSeat, state.seats[state.dealerSeat].handTileIds.first);
      state.riichiSticksOnTable = 2;

      // New round
      TableLogic.newRound(state, Random(1901), false);

      // State reset
      expect(state.gameStarted, true);
      expect(state.pendingWin, isNull);
      expect(state.pendingExchange, isNull);
      for (final seat in state.seats) {
        expect(seat.discards, isEmpty);
        expect(seat.melds, isEmpty);
        expect(seat.isRiichi, false);
      }
      // Riichi sticks preserved (cleared only on win)
      expect(state.riichiSticksOnTable, 2);
    });
  });

  // ═══════════════════════════════════════════════════════════════
  // 10. RIICHI-SPECIFIC RULES
  // ═══════════════════════════════════════════════════════════════
  group('Riichi-specific rules', () {
    test('riichi deducts 1000 points', () {
      final state = _dealtState(seed: 2000);
      final seat = state.dealerSeat;
      final scoreBefore = state.scores[seat];

      TableLogic.riichi(
          state, seat, state.seats[seat].handTileIds.first);
      expect(state.scores[seat], scoreBefore - 1000);
      expect(state.riichiSticksOnTable, 1);
    });

    test('cannot double riichi', () {
      final state = _dealtState(seed: 2100);
      final seat = state.dealerSeat;
      state.seats[seat].isRiichi = true;
      final scoreBefore = state.scores[seat];
      final sticksBefore = state.riichiSticksOnTable;

      TableLogic.riichi(
          state, seat, state.seats[seat].handTileIds.first);
      expect(state.scores[seat], scoreBefore); // unchanged
      expect(state.riichiSticksOnTable, sticksBefore); // unchanged
    });

    test('riichi discard is marked', () {
      final state = _dealtState(seed: 2200);
      final seat = state.dealerSeat;

      TableLogic.riichi(
          state, seat, state.seats[seat].handTileIds.first);
      expect(state.seats[seat].discards.last.isRiichiDiscard, true);
    });

    test('cannot undo riichi discard', () {
      final state = _dealtState(seed: 2300);
      final seat = state.dealerSeat;

      TableLogic.riichi(
          state, seat, state.seats[seat].handTileIds.first);

      // Try to undo
      TableLogic.undoDiscard(state, seat);
      // Should not undo
      expect(state.seats[seat].discards.length, 1);
      expect(state.seats[seat].isRiichi, true);
    });

    test('riichi sticks collected by winner', () {
      final state = _dealtState(seed: 2400);

      // Two players riichi
      final s0 = state.dealerSeat;
      TableLogic.riichi(
          state, s0, state.seats[s0].handTileIds.first);

      final s1 = (s0 + 1) % 4;
      state.currentTurn = s1;
      state.hasDrawnThisTurn = false;
      TableLogic.draw(state, s1);
      TableLogic.riichi(
          state, s1, state.seats[s1].handTileIds.first);

      expect(state.riichiSticksOnTable, 2);

      // Player 2 wins
      final s2 = (s0 + 2) % 4;
      state.lastDiscardedBy = s1;
      TableLogic.declareWin(state, s2, false, 3, 30);

      final winPayment = state.pendingWin!.totalPoints;
      // Winner should get riichi sticks too (2000 pts)
      expect(winPayment, greaterThan(0));

      TableLogic.confirmWin(state, s0);
      TableLogic.confirmWin(state, (s2 + 1) % 4 == s0
          ? (s2 + 2) % 4
          : (s2 + 1) % 4);

      expect(state.riichiSticksOnTable, 0);
    });
  });

  // ═══════════════════════════════════════════════════════════════
  // 11. UNDO DISCARD SCENARIOS
  // ═══════════════════════════════════════════════════════════════
  group('Undo discard scenarios', () {
    test('undo returns tile to hand and restores state', () {
      final state = _dealtState(seed: 2500);
      final seat = state.dealerSeat;
      final tileId = state.seats[seat].handTileIds[3]; // pick middle tile

      TableLogic.discard(state, seat, tileId);
      expect(state.seats[seat].handTileIds.contains(tileId), false);
      expect(state.currentTurn, (seat + 1) % 4);

      TableLogic.undoDiscard(state, seat);
      expect(state.seats[seat].handTileIds.contains(tileId), true);
      expect(state.currentTurn, seat);
      expect(state.hasDrawnThisTurn, true);
      expect(state.lastDiscardedBy, isNull);
    });

    test('only the discarder can undo', () {
      final state = _dealtState(seed: 2600);
      final seat = state.dealerSeat;
      final tileId = state.seats[seat].handTileIds.first;

      TableLogic.discard(state, seat, tileId);

      // Other player tries to undo
      TableLogic.undoDiscard(state, (seat + 1) % 4);
      expect(state.seats[seat].discards.length, 1); // unchanged
    });

    test('undo then re-discard different tile', () {
      final state = _dealtState(seed: 2700);
      final seat = state.dealerSeat;
      final tile1 = state.seats[seat].handTileIds[0];
      final tile2 = state.seats[seat].handTileIds[1];

      TableLogic.discard(state, seat, tile1);
      TableLogic.undoDiscard(state, seat);

      // Now discard a different tile
      TableLogic.discard(state, seat, tile2);
      expect(state.seats[seat].handTileIds.contains(tile1), true);
      expect(state.seats[seat].handTileIds.contains(tile2), false);
    });
  });

  // ═══════════════════════════════════════════════════════════════
  // 12. EXCHANGE & ADJUST SCORE
  // ═══════════════════════════════════════════════════════════════
  group('Exchange and adjust score', () {
    test('exchange propose → confirm transfers points', () {
      final state = _dealtState(seed: 2800);
      final s0 = state.scores[0];
      final s1 = state.scores[1];

      TableLogic.exchangePropose(state, 0, 1, 3000);
      expect(state.pendingExchange, isNotNull);
      expect(state.pendingExchange!.fromSeat, 0);
      expect(state.pendingExchange!.toSeat, 1);
      expect(state.pendingExchange!.amount, 3000);

      // Target confirms
      TableLogic.exchangeConfirm(state, 1);
      expect(state.scores[0], s0 - 3000);
      expect(state.scores[1], s1 + 3000);
      expect(state.pendingExchange, isNull);
    });

    test('exchange propose → reject keeps scores', () {
      final state = _dealtState(seed: 2900);
      final s0 = state.scores[0];

      TableLogic.exchangePropose(state, 0, 1, 5000);
      TableLogic.exchangeReject(state, 1);

      expect(state.scores[0], s0);
      expect(state.pendingExchange, isNull);
    });

    test('wrong seat cannot confirm exchange', () {
      final state = _dealtState(seed: 3000);
      TableLogic.exchangePropose(state, 0, 1, 5000);

      // Seat 2 tries to confirm
      TableLogic.exchangeConfirm(state, 2);
      expect(state.pendingExchange, isNotNull); // still pending
    });

    test('adjustScore positive and negative', () {
      final state = _dealtState(seed: 3100);
      final before = state.scores[3];

      TableLogic.adjustScore(state, 3, 5000);
      expect(state.scores[3], before + 5000);

      TableLogic.adjustScore(state, 3, -2000);
      expect(state.scores[3], before + 3000);
    });
  });

  // ═══════════════════════════════════════════════════════════════
  // 13. SCORING FORMULA VERIFICATION
  // ═══════════════════════════════════════════════════════════════
  group('Riichi scoring formula verification', () {
    test('1 han 30 fu: base 240', () {
      expect(ScoreCalculator.basePoints(1, 30), 240);
    });

    test('2 han 25 fu: base 400', () {
      // 25 * 2^4 = 400
      expect(ScoreCalculator.basePoints(2, 25), 400);
    });

    test('3 han 30 fu: base 960', () {
      expect(ScoreCalculator.basePoints(3, 30), 960);
    });

    test('4 han 30 fu: base 1920', () {
      expect(ScoreCalculator.basePoints(4, 30), 1920);
    });

    test('4 han 40 fu: kiriage mangan → 2000', () {
      expect(ScoreCalculator.basePoints(4, 40), 2000);
    });

    test('3 han 70 fu: kiriage mangan → 2000', () {
      // 70 * 2^5 = 2240 > 2000
      expect(ScoreCalculator.basePoints(3, 70), 2000);
    });

    test('mangan tiers', () {
      expect(ScoreCalculator.basePoints(5, 30), 2000);
      expect(ScoreCalculator.basePoints(6, 30), 3000);
      expect(ScoreCalculator.basePoints(7, 30), 3000);
      expect(ScoreCalculator.basePoints(8, 30), 4000);
      expect(ScoreCalculator.basePoints(10, 30), 4000);
      expect(ScoreCalculator.basePoints(11, 30), 6000);
      expect(ScoreCalculator.basePoints(12, 30), 6000);
      expect(ScoreCalculator.basePoints(13, 30), 8000);
    });

    test('dealer tsumo mangan: each pays 4000, total 12000', () {
      final payments = ScoreCalculator.calculatePayments(
        han: 5,
        fu: 30,
        winnerSeat: 0,
        dealerSeat: 0,
        isTsumo: true,
        loserSeat: null,
        honbaCount: 0,
        riichiSticks: 0,
      );
      expect(payments[0], 12000);
      expect(payments[1], -4000);
      expect(payments[2], -4000);
      expect(payments[3], -4000);
    });

    test('non-dealer tsumo mangan: dealer 4000, others 2000', () {
      final payments = ScoreCalculator.calculatePayments(
        han: 5,
        fu: 30,
        winnerSeat: 1,
        dealerSeat: 0,
        isTsumo: true,
        loserSeat: null,
        honbaCount: 0,
        riichiSticks: 0,
      );
      expect(payments[1], 8000);
      expect(payments[0], -4000); // dealer
      expect(payments[2], -2000); // non-dealer
      expect(payments[3], -2000); // non-dealer
    });

    test('dealer ron mangan: 12000', () {
      final payments = ScoreCalculator.calculatePayments(
        han: 5,
        fu: 30,
        winnerSeat: 0,
        dealerSeat: 0,
        isTsumo: false,
        loserSeat: 2,
        honbaCount: 0,
        riichiSticks: 0,
      );
      expect(payments[0], 12000);
      expect(payments[2], -12000);
    });

    test('non-dealer ron mangan: 8000', () {
      final payments = ScoreCalculator.calculatePayments(
        han: 5,
        fu: 30,
        winnerSeat: 1,
        dealerSeat: 0,
        isTsumo: false,
        loserSeat: 3,
        honbaCount: 0,
        riichiSticks: 0,
      );
      expect(payments[1], 8000);
      expect(payments[3], -8000);
    });

    test('yakuman: 32000 ron / 48000 tsumo (dealer)', () {
      final payments = ScoreCalculator.calculatePayments(
        han: 13,
        fu: 30,
        winnerSeat: 0,
        dealerSeat: 0,
        isTsumo: false,
        loserSeat: 1,
        honbaCount: 0,
        riichiSticks: 0,
      );
      // Dealer ron yakuman: base 8000 * 6 = 48000
      expect(payments[0], 48000);
      expect(payments[1], -48000);

      final tsumoPayments = ScoreCalculator.calculatePayments(
        han: 13,
        fu: 30,
        winnerSeat: 0,
        dealerSeat: 0,
        isTsumo: true,
        loserSeat: null,
        honbaCount: 0,
        riichiSticks: 0,
      );
      // Dealer tsumo yakuman: each pays ceil(8000*2/100)*100 = 16000
      expect(tsumoPayments[1], -16000);
      expect(tsumoPayments[0], 48000);
    });

    test('non-dealer yakuman ron = 32000', () {
      final payments = ScoreCalculator.calculatePayments(
        han: 13,
        fu: 30,
        winnerSeat: 1,
        dealerSeat: 0,
        isTsumo: false,
        loserSeat: 2,
        honbaCount: 0,
        riichiSticks: 0,
      );
      // Non-dealer ron yakuman: base 8000 * 4 = 32000
      expect(payments[1], 32000);
      expect(payments[2], -32000);
    });

    test('all payment sums are zero (zero-sum game)', () {
      final testCases = [
        {'han': 1, 'fu': 30, 'dealer': true, 'tsumo': true},
        {'han': 1, 'fu': 30, 'dealer': true, 'tsumo': false},
        {'han': 1, 'fu': 30, 'dealer': false, 'tsumo': true},
        {'han': 1, 'fu': 30, 'dealer': false, 'tsumo': false},
        {'han': 3, 'fu': 30, 'dealer': true, 'tsumo': true},
        {'han': 3, 'fu': 30, 'dealer': false, 'tsumo': false},
        {'han': 5, 'fu': 30, 'dealer': true, 'tsumo': true},
        {'han': 5, 'fu': 30, 'dealer': false, 'tsumo': true},
        {'han': 8, 'fu': 30, 'dealer': true, 'tsumo': false},
        {'han': 13, 'fu': 30, 'dealer': true, 'tsumo': true},
        {'han': 13, 'fu': 30, 'dealer': false, 'tsumo': false},
      ];

      for (final tc in testCases) {
        final isDealer = tc['dealer'] as bool;
        final isTsumo = tc['tsumo'] as bool;
        final payments = ScoreCalculator.calculatePayments(
          han: tc['han'] as int,
          fu: tc['fu'] as int,
          winnerSeat: isDealer ? 0 : 1,
          dealerSeat: 0,
          isTsumo: isTsumo,
          loserSeat: isTsumo ? null : 2,
          honbaCount: 0,
          riichiSticks: 0,
        );
        final sum = payments.values.fold<int>(0, (a, b) => a + b);
        expect(sum, 0,
            reason:
                'Payments not zero-sum for ${tc['han']}han ${tc['fu']}fu '
                'dealer=$isDealer tsumo=$isTsumo');
      }
    });
  });

  // ═══════════════════════════════════════════════════════════════
  // 14. TILE CONSERVATION ACROSS VARIANTS
  // ═══════════════════════════════════════════════════════════════
  group('Tile conservation across variants', () {
    test('Riichi 136: tiles conserved through actions', () {
      final state = _dealtState(
        config: const GameConfig(tileCount: 136, isRiichi: true),
        seed: 3200,
      );
      expect(_totalTiles(state), 136);

      // Draw and discard
      final seat = state.dealerSeat;
      TableLogic.discard(state, seat, state.seats[seat].handTileIds.first);
      expect(_totalTiles(state), 136);

      // Draw
      final nextSeat = state.currentTurn;
      TableLogic.draw(state, nextSeat);
      expect(_totalTiles(state), 136);

      // Discard
      TableLogic.discard(
          state, nextSeat, state.seats[nextSeat].handTileIds.first);
      expect(_totalTiles(state), 136);
    });

    test('Sichuan 108: tiles conserved through kan', () {
      final state = _dealtState(
        config: const GameConfig(tileCount: 108, isRiichi: false),
        seed: 3300,
      );
      expect(_totalTiles(state), 108);

      final seat = state.dealerSeat;
      state.seats[seat].handTileIds.clear();
      state.seats[seat].handTileIds
          .addAll([0, 1, 2, 3, 8, 72, 76, 80, 84, 88, 92, 96, 100, 104]);

      TableLogic.closedKan(state, seat, [0, 1, 2, 3]);
      expect(_totalTiles(state), 108);

      TableLogic.draw(state, seat);
      expect(_totalTiles(state), 108);
    });

    test('144 tiles: tiles conserved through flower draw', () {
      final config = const GameConfig(
          tileCount: 144, isRiichi: false, startingPoints: 0);
      final state = _dealtState(config: config, seed: 3400);

      final seat = state.dealerSeat;
      state.seats[seat].handTileIds.add(136);

      // Total is now 145 because we added an extra tile manually
      // That's fine for testing — we just verify drawFlower conserves
      final totalBefore = _totalTiles(state);
      TableLogic.drawFlower(state, seat, 136);
      expect(_totalTiles(state), totalBefore);
    });
  });

  // ═══════════════════════════════════════════════════════════════
  // 15. SERIALIZATION / JSON
  // ═══════════════════════════════════════════════════════════════
  group('ServerState JSON serialization', () {
    test('toJsonForSeat includes all fields', () {
      final state = _dealtState(seed: 3500);
      final json = state.toJsonForSeat(0);

      expect(json['wallRemaining'], isA<int>());
      expect(json['deadWallCount'], isA<int>());
      expect(json['doraRevealed'], isA<int>());
      expect(json['doraIndicatorTileIds'], isA<List>());
      expect(json['seats'], isA<List>());
      expect((json['seats'] as List).length, 4);
      expect(json['nicknames'], isA<List>());
      expect(json['dealerSeat'], isA<int>());
      expect(json['currentTurn'], isA<int>());
      expect(json['scores'], isA<List>());
      expect(json['roundWind'], isA<int>());
      expect(json['roundNumber'], isA<int>());
      expect(json['honbaCount'], isA<int>());
      expect(json['riichiSticksOnTable'], isA<int>());
      expect(json['gameStarted'], true);
      expect(json['hasDrawnThisTurn'], isA<bool>());
      expect(json['config'], isA<Map>());
      expect(json['actionLog'], isA<List>());
    });

    test('viewer sees own hand, not others', () {
      final state = _dealtState(seed: 3600);

      for (int viewer = 0; viewer < 4; viewer++) {
        final json = state.toJsonForSeat(viewer);
        final seats = json['seats'] as List;
        for (int i = 0; i < 4; i++) {
          final seatJson = seats[i] as Map<String, dynamic>;
          if (i == viewer) {
            expect(seatJson.containsKey('handTileIds'), true,
                reason: 'Viewer $viewer should see own hand');
          } else {
            expect(seatJson.containsKey('handTileIds'), false,
                reason: 'Viewer $viewer should not see seat $i hand');
          }
          expect(seatJson['handCount'], isA<int>());
        }
      }
    });

    test('revealed hand visible to all', () {
      final state = _dealtState(seed: 3700);
      TableLogic.showHand(state, 2);

      for (int viewer = 0; viewer < 4; viewer++) {
        final json = state.toJsonForSeat(viewer);
        final seat2 = (json['seats'] as List)[2] as Map<String, dynamic>;
        expect(seat2.containsKey('handTileIds'), true,
            reason: 'Revealed hand should be visible to viewer $viewer');
        expect(seat2['handRevealed'], true);
      }
    });

    test('pending win included in JSON', () {
      final state = _dealtState(seed: 3800);
      TableLogic.declareWin(state, 0, true, 3, 30);

      final json = state.toJsonForSeat(0);
      expect(json.containsKey('pendingWin'), true);
      final pw = json['pendingWin'] as Map<String, dynamic>;
      expect(pw['seatIndex'], 0);
      expect(pw['isTsumo'], true);
      expect(pw['han'], 3);
      expect(pw['fu'], 30);
    });

    test('pending exchange included in JSON', () {
      final state = _dealtState(seed: 3900);
      TableLogic.exchangePropose(state, 0, 1, 5000);

      final json = state.toJsonForSeat(0);
      expect(json.containsKey('pendingExchange'), true);
      final pe = json['pendingExchange'] as Map<String, dynamic>;
      expect(pe['fromSeat'], 0);
      expect(pe['toSeat'], 1);
      expect(pe['amount'], 5000);
    });

    test('dora indicators correctly extracted from dead wall', () {
      final state = _dealtState(seed: 4000);
      expect(state.doraRevealed, 1);

      final json = state.toJsonForSeat(0);
      final indicators = json['doraIndicatorTileIds'] as List;
      expect(indicators.length, 1);
      // Should be the first tile of the dead wall (index 0)
      expect(indicators.first, state.deadWallTileIds[0]);

      // Reveal more
      TableLogic.revealDora(state);
      final json2 = state.toJsonForSeat(0);
      final indicators2 = json2['doraIndicatorTileIds'] as List;
      expect(indicators2.length, 2);
      // Second indicator is dead wall index 2
      expect(indicators2[1], state.deadWallTileIds[2]);
    });

    test('Sichuan missing suit in seat JSON', () {
      final state = _dealtState(
        config: const GameConfig(tileCount: 108, isRiichi: false),
        seed: 4100,
      );
      TableLogic.chooseMissingSuit(state, 0, 2);

      final json = state.toJsonForSeat(0);
      final seat0 = (json['seats'] as List)[0] as Map<String, dynamic>;
      expect(seat0['missingSuit'], 2);

      // Other seats have no missing suit yet
      final seat1 = (json['seats'] as List)[1] as Map<String, dynamic>;
      expect(seat1.containsKey('missingSuit'), false);
    });
  });

  // ═══════════════════════════════════════════════════════════════
  // 16. EDGE CASES
  // ═══════════════════════════════════════════════════════════════
  group('Edge cases', () {
    test('draw from empty wall does nothing', () {
      final state = _dealtState(seed: 4200);
      state.liveTileIds.clear();
      state.hasDrawnThisTurn = false;
      final seat = state.currentTurn;
      final handBefore = state.seats[seat].handTileIds.length;

      TableLogic.draw(state, seat);
      expect(state.seats[seat].handTileIds.length, handBefore);
      expect(state.hasDrawnThisTurn, false);
    });

    test('drawDeadWall from empty wall does nothing', () {
      final state = _dealtState(seed: 4300);
      state.liveTileIds.clear();
      state.hasDrawnThisTurn = false;
      final seat = state.currentTurn;

      TableLogic.drawDeadWall(state, seat);
      expect(state.hasDrawnThisTurn, false);
    });

    test('cannot draw twice in same turn', () {
      final state = _dealtState(seed: 4400);
      final seat = (state.dealerSeat + 1) % 4;
      state.currentTurn = seat;
      state.hasDrawnThisTurn = false;

      TableLogic.draw(state, seat);
      expect(state.hasDrawnThisTurn, true);
      final handAfterFirst = state.seats[seat].handTileIds.length;

      // Second draw should be blocked
      TableLogic.draw(state, seat);
      expect(state.seats[seat].handTileIds.length, handAfterFirst);
    });

    test('undo with no discards does nothing', () {
      final state = _dealtState(seed: 4500);
      final seat = state.dealerSeat;
      state.lastDiscardedBy = seat;
      state.seats[seat].discards.clear();

      TableLogic.undoDiscard(state, seat);
      // No crash, no change
      expect(state.seats[seat].discards, isEmpty);
    });

    test('addedKan on invalid meld index does nothing', () {
      final state = _dealtState(seed: 4600);
      final seat = 0;
      state.seats[seat].handTileIds.add(3);

      // No melds exist, index 0 is out of bounds
      TableLogic.addedKan(state, seat, 3, 0);
      expect(state.seats[seat].melds, isEmpty);
    });

    test('multiple win declarations: second replaces first', () {
      final state = _dealtState(seed: 4700);
      TableLogic.declareWin(state, 0, true, 3, 30);
      expect(state.pendingWin!.seatIndex, 0);

      // Another player declares win (replaces)
      state.lastDiscardedBy = 0;
      TableLogic.declareWin(state, 1, false, 5, 30);
      expect(state.pendingWin!.seatIndex, 1);
    });

    test('confirm with no pending win does nothing', () {
      final state = _dealtState(seed: 4800);
      expect(state.pendingWin, isNull);

      // Should not crash
      TableLogic.confirmWin(state, 0);
      expect(state.pendingWin, isNull);
    });

    test('reject with no pending win does nothing', () {
      final state = _dealtState(seed: 4900);
      expect(state.pendingWin, isNull);

      TableLogic.rejectWin(state, 0);
      expect(state.pendingWin, isNull);
    });

    test('discard tile not in hand: tile still removed from list', () {
      // TableLogic.discard does list.remove() which returns false for missing
      // but still proceeds with other state changes
      final state = _dealtState(seed: 5000);
      final seat = state.dealerSeat;

      // Discard a tile that's not in hand (shouldn't crash)
      TableLogic.discard(state, seat, 9999);
      // The discard entry is still created (free-form table, no validation)
      expect(state.seats[seat].discards.length, 1);
    });

    test('exchange with self (fromSeat == toSeat) works', () {
      final state = _dealtState(seed: 5100);
      final scoreBefore = state.scores[0];

      TableLogic.exchangePropose(state, 0, 0, 1000);
      TableLogic.exchangeConfirm(state, 0);

      // Self-exchange: -1000 + 1000 = net zero
      expect(state.scores[0], scoreBefore);
    });
  });

  // ═══════════════════════════════════════════════════════════════
  // 17. VARIANT CONFIG GETTERS
  // ═══════════════════════════════════════════════════════════════
  group('Variant config correctness', () {
    test('Riichi 136 has dead wall and dora', () {
      const config = GameConfig(tileCount: 136, isRiichi: true);
      expect(config.isSichuan, false);
      expect(config.isShanghai, false);
      expect(config.isSuzhou, false);
      expect(config.hasDora, true);
      expect(config.hasDeadWall, true);
      expect(config.deadWallSize, 14);
      expect(config.hasFlowers, false);
    });

    test('Sichuan 108 has no dead wall, no dora, no flowers', () {
      const config = GameConfig(tileCount: 108, isRiichi: false);
      expect(config.isSichuan, true);
      expect(config.hasDora, false);
      expect(config.hasDeadWall, false);
      expect(config.deadWallSize, 0);
      expect(config.hasFlowers, false);
    });

    test('Guobiao 136 (non-riichi) has no dead wall, no dora', () {
      const config = GameConfig(tileCount: 136, isRiichi: false);
      expect(config.isSichuan, false);
      expect(config.hasDora, false);
      expect(config.hasDeadWall, false);
    });

    test('Shanghai 144 with baida', () {
      const config =
          GameConfig(tileCount: 144, isRiichi: false, hasBaida: true);
      expect(config.isShanghai, true);
      expect(config.hasFlowers, true);
      expect(config.hasDora, false);
      expect(config.hasDeadWall, false);
    });

    test('Suzhou 152', () {
      const config = GameConfig(tileCount: 152, isRiichi: false);
      expect(config.isSuzhou, true);
      expect(config.hasFlowers, true);
      expect(config.hasDora, false);
    });

    test('Riichi sub-modes', () {
      const free = GameConfig(riichiMode: 'free');
      expect(free.isAutoMode, false);
      expect(free.isCustomMode, false);

      const auto = GameConfig(riichiMode: 'auto');
      expect(auto.isAutoMode, true);
      expect(auto.isCustomMode, false);

      const custom = GameConfig(riichiMode: 'custom');
      expect(custom.isAutoMode, false);
      expect(custom.isCustomMode, true);
    });

    test('AI seat config', () {
      const noAi = GameConfig();
      expect(noAi.hasAiPlayers, false);

      const withAi =
          GameConfig(aiSeats: [false, true, true, true]);
      expect(withAi.hasAiPlayers, true);
    });

    test('tile generation counts', () {
      expect(const GameConfig(tileCount: 108).generateTileIds().length, 108);
      expect(const GameConfig(tileCount: 136).generateTileIds().length, 136);
      expect(const GameConfig(tileCount: 144).generateTileIds().length, 144);
      expect(const GameConfig(tileCount: 152).generateTileIds().length, 152);
    });
  });

  // ═══════════════════════════════════════════════════════════════
  // 18. ACTION LOG
  // ═══════════════════════════════════════════════════════════════
  group('Action log', () {
    test('actions are logged with correct details', () {
      final state = _dealtState(seed: 5200);
      state.nicknames[0] = 'Alice';

      final seat = state.dealerSeat;
      final tileId = state.seats[seat].handTileIds.first;
      TableLogic.discard(state, seat, tileId);

      final log = state.actionLog.last;
      expect(log.action, 'discard');
      expect(log.seat, seat);
      expect(log.tileId, tileId);
    });

    test('log capped at 50 entries', () {
      final state = _dealtState(seed: 5300);
      for (int i = 0; i < 100; i++) {
        state.addLog(0, 'test', detail: 'entry $i');
      }
      expect(state.actionLog.length, lessThanOrEqualTo(50));
    });

    test('chooseMissingSuit logs suit name', () {
      final state = _dealtState(
        config: const GameConfig(tileCount: 108, isRiichi: false),
        seed: 5400,
      );
      TableLogic.chooseMissingSuit(state, 0, 0);
      expect(state.actionLog.last.detail, '缺万');

      TableLogic.chooseMissingSuit(state, 1, 1);
      expect(state.actionLog.last.detail, '缺筒');

      TableLogic.chooseMissingSuit(state, 2, 2);
      expect(state.actionLog.last.detail, '缺索');
    });

    test('win declaration logs tier and type', () {
      final state = _dealtState(seed: 5500);
      TableLogic.declareWin(state, 0, true, 5, 30);

      final log = state.actionLog.last;
      expect(log.action, 'declareWin');
      expect(log.detail, contains('满贯'));
      expect(log.detail, contains('自摸'));
    });
  });
}
