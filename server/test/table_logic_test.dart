import 'dart:math';
import 'package:test/test.dart';
import 'package:mahjong_server/game_config.dart';
import 'package:mahjong_server/models.dart';
import 'package:mahjong_server/table_logic.dart';

/// Helper to create a state with config applied and dealt.
ServerState _dealtState({
  GameConfig config = const GameConfig(),
  int seed = 42,
}) {
  final state = ServerState();
  state.applyConfig(config);
  TableLogic.deal(state, Random(seed));
  return state;
}

void main() {
  group('ServerState.applyConfig', () {
    test('sets config and scores', () {
      final state = ServerState();
      state.applyConfig(
          const GameConfig(tileCount: 108, isRiichi: false, startingPoints: 0));
      expect(state.config.tileCount, 108);
      expect(state.scores, [0, 0, 0, 0]);
    });

    test('overrides default scores', () {
      final state = ServerState();
      state.applyConfig(const GameConfig(startingPoints: 50000));
      expect(state.scores, [50000, 50000, 50000, 50000]);
    });
  });

  group('TableLogic.deal', () {
    test('Riichi 136: each player gets 13/14 tiles, dead wall exists', () {
      final state = _dealtState(config: const GameConfig());
      // Dealer gets 14
      expect(state.seats[state.dealerSeat].handTileIds.length, 14);
      // Others get 13
      for (int i = 0; i < 4; i++) {
        if (i != state.dealerSeat) {
          expect(state.seats[i].handTileIds.length, 13);
        }
      }
      // Dead wall
      expect(state.deadWallTileIds.length, 14);
      // Total dealt + wall + dead wall = 136
      final totalDealt =
          state.seats.fold<int>(0, (sum, s) => sum + s.handTileIds.length);
      expect(totalDealt + state.liveTileIds.length +
          state.deadWallTileIds.length, 136);
      // Dora revealed
      expect(state.doraRevealed, 1);
      expect(state.gameStarted, true);
      expect(state.hasDrawnThisTurn, true);
    });

    test('Sichuan 108: no dead wall, no dora', () {
      final state = _dealtState(
          config: const GameConfig(tileCount: 108, isRiichi: false));
      expect(state.deadWallTileIds.length, 0);
      expect(state.doraRevealed, 0);
      final totalDealt =
          state.seats.fold<int>(0, (sum, s) => sum + s.handTileIds.length);
      expect(totalDealt + state.liveTileIds.length, 108);
    });

    test('Guobiao 136: no dead wall, no dora', () {
      final state = _dealtState(
          config: const GameConfig(tileCount: 136, isRiichi: false));
      expect(state.deadWallTileIds.length, 0);
      expect(state.doraRevealed, 0);
    });

    test('Flowers 144: no dead wall', () {
      final state = _dealtState(
          config: const GameConfig(tileCount: 144, isRiichi: false));
      expect(state.deadWallTileIds.length, 0);
      final totalDealt =
          state.seats.fold<int>(0, (sum, s) => sum + s.handTileIds.length);
      expect(totalDealt + state.liveTileIds.length, 144);
    });

    test('Suzhou 152: all 152 tiles distributed', () {
      final state = _dealtState(
          config: const GameConfig(tileCount: 152, isRiichi: false));
      expect(state.deadWallTileIds.length, 0);
      final totalDealt =
          state.seats.fold<int>(0, (sum, s) => sum + s.handTileIds.length);
      expect(totalDealt + state.liveTileIds.length, 152);
    });

    test('Shanghai 百搭: flips reference tile', () {
      final state = _dealtState(
          config: const GameConfig(
              tileCount: 144, isRiichi: false, hasBaida: true));
      expect(state.baidaReferenceTileId, isNotNull);
      // Total should still add up: dealt + wall + 1 baida reference = 144
      final totalDealt =
          state.seats.fold<int>(0, (sum, s) => sum + s.handTileIds.length);
      expect(totalDealt + state.liveTileIds.length + 1, 144);
    });

    test('Non-百搭 variants: no reference tile', () {
      final state = _dealtState(config: const GameConfig());
      expect(state.baidaReferenceTileId, isNull);
    });

    test('deal resets seat state', () {
      final state = _dealtState();
      for (final seat in state.seats) {
        expect(seat.discards, isEmpty);
        expect(seat.melds, isEmpty);
        expect(seat.isRiichi, false);
        expect(seat.handRevealed, false);
        expect(seat.flowerTileIds, isEmpty);
        expect(seat.missingSuit, isNull);
      }
    });

    test('action log contains deal entry', () {
      final state = _dealtState();
      expect(state.actionLog.isNotEmpty, true);
      expect(state.actionLog.any((e) => e.action == 'deal'), true);
    });
  });

  group('TableLogic.draw', () {
    test('draws from front of live wall', () {
      final state = _dealtState();
      final seat = (state.dealerSeat + 1) % 4;
      state.currentTurn = seat;
      state.hasDrawnThisTurn = false;
      final wallBefore = state.liveTileIds.length;
      final expectedTile = state.liveTileIds.first;

      TableLogic.draw(state, seat);

      expect(state.seats[seat].handTileIds.length, 14);
      expect(state.seats[seat].handTileIds.last, expectedTile);
      expect(state.liveTileIds.length, wallBefore - 1);
      expect(state.hasDrawnThisTurn, true);
      expect(state.seats[seat].justDrewTileId, expectedTile);
    });

    test('does not draw if already drawn this turn', () {
      final state = _dealtState();
      final seat = state.dealerSeat;
      final handBefore = state.seats[seat].handTileIds.length;

      TableLogic.draw(state, seat); // already drawn (dealer's 14th)

      expect(state.seats[seat].handTileIds.length, handBefore);
    });

    test('does not draw if wall is empty', () {
      final state = _dealtState();
      state.liveTileIds.clear();
      state.hasDrawnThisTurn = false;
      final seat = state.currentTurn;
      final handBefore = state.seats[seat].handTileIds.length;

      TableLogic.draw(state, seat);

      expect(state.seats[seat].handTileIds.length, handBefore);
    });
  });

  group('TableLogic.drawDeadWall', () {
    test('draws from back of live wall', () {
      final state = _dealtState();
      final seat = (state.dealerSeat + 1) % 4;
      state.currentTurn = seat;
      state.hasDrawnThisTurn = false;
      final expectedTile = state.liveTileIds.last;

      TableLogic.drawDeadWall(state, seat);

      expect(state.seats[seat].handTileIds.last, expectedTile);
      expect(state.hasDrawnThisTurn, true);
    });
  });

  group('TableLogic.discard', () {
    test('removes tile from hand and adds to discards', () {
      final state = _dealtState();
      final seat = state.dealerSeat;
      final tileId = state.seats[seat].handTileIds.first;

      TableLogic.discard(state, seat, tileId);

      expect(state.seats[seat].handTileIds.contains(tileId), false);
      expect(state.seats[seat].discards.length, 1);
      expect(state.seats[seat].discards.last.tileId, tileId);
      expect(state.lastDiscardedBy, seat);
      expect(state.lastDiscardedTileId, tileId);
      expect(state.currentTurn, (seat + 1) % 4);
      expect(state.hasDrawnThisTurn, false);
    });

    test('tsumogiri flag set when discarding just-drew tile', () {
      final state = _dealtState();
      final seat = state.dealerSeat;
      final drewTile = state.seats[seat].justDrewTileId!;

      TableLogic.discard(state, seat, drewTile);

      expect(state.seats[seat].discards.last.isTsumogiri, true);
    });

    test('tsumogiri flag not set for other tiles', () {
      final state = _dealtState();
      final seat = state.dealerSeat;
      // Discard the first tile (not the just-drew tile)
      final tileId = state.seats[seat].handTileIds.first;
      if (tileId != state.seats[seat].justDrewTileId) {
        TableLogic.discard(state, seat, tileId);
        expect(state.seats[seat].discards.last.isTsumogiri, false);
      }
    });
  });

  group('TableLogic.chi', () {
    test('forms chi meld from 2 hand tiles + discard', () {
      final state = _dealtState();
      final seat = 0;
      final prevSeat = 3;

      // Manually set up chi scenario
      state.seats[seat].handTileIds.clear();
      state.seats[seat].handTileIds.addAll([0, 4, 8, 12, 16, 20, 24, 28, 32,
          36, 40, 44, 48]); // 1m-1m-2m-...
      state.seats[prevSeat].discards
          .add(DiscardEntry(tileId: 8)); // 3m discarded
      state.lastDiscardedBy = prevSeat;
      state.lastDiscardedTileId = 8;

      TableLogic.chi(state, seat, [0, 4]); // chi with 1m, 2m + 3m discard

      expect(state.seats[seat].melds.length, 1);
      expect(state.seats[seat].melds.first.type, 'chi');
      expect(state.seats[seat].melds.first.calledFrom, prevSeat);
      expect(state.seats[seat].melds.first.calledTileId, 8);
      expect(state.currentTurn, seat);
      expect(state.hasDrawnThisTurn, true);
    });
  });

  group('TableLogic.pon', () {
    test('forms pon meld', () {
      final state = _dealtState();
      final seat = 1;
      final discardSeat = 0;

      state.seats[seat].handTileIds.clear();
      state.seats[seat].handTileIds
          .addAll([0, 1, 4, 8, 12, 16, 20, 24, 28, 32, 36, 40, 44]);
      state.seats[discardSeat].discards.add(DiscardEntry(tileId: 2));
      state.lastDiscardedBy = discardSeat;
      state.lastDiscardedTileId = 2;

      TableLogic.pon(state, seat, [0, 1]); // pon 1m with copies 0,1 + discard copy 2

      expect(state.seats[seat].melds.length, 1);
      expect(state.seats[seat].melds.first.type, 'pon');
      expect(state.seats[seat].melds.first.tileIds, containsAll([0, 1, 2]));
      expect(state.currentTurn, seat);
    });
  });

  group('TableLogic.openKan', () {
    test('forms open kan meld', () {
      final state = _dealtState();
      final seat = 1;
      final discardSeat = 0;

      state.seats[seat].handTileIds.clear();
      state.seats[seat].handTileIds
          .addAll([0, 1, 2, 8, 12, 16, 20, 24, 28, 32, 36, 40, 44]);
      state.seats[discardSeat].discards.add(DiscardEntry(tileId: 3));
      state.lastDiscardedBy = discardSeat;
      state.lastDiscardedTileId = 3;

      TableLogic.openKan(state, seat, [0, 1, 2]);

      expect(state.seats[seat].melds.length, 1);
      expect(state.seats[seat].melds.first.type, 'openKan');
      expect(state.hasDrawnThisTurn, false); // needs to draw from dead wall
    });
  });

  group('TableLogic.closedKan', () {
    test('forms closed kan from 4 hand tiles', () {
      final state = _dealtState();
      final seat = state.dealerSeat;

      state.seats[seat].handTileIds.clear();
      state.seats[seat].handTileIds
          .addAll([0, 1, 2, 3, 8, 12, 16, 20, 24, 28, 32, 36, 40, 44]);

      TableLogic.closedKan(state, seat, [0, 1, 2, 3]);

      expect(state.seats[seat].melds.length, 1);
      expect(state.seats[seat].melds.first.type, 'closedKan');
      expect(state.seats[seat].handTileIds.contains(0), false);
      expect(state.hasDrawnThisTurn, false);
    });
  });

  group('TableLogic.addedKan', () {
    test('upgrades pon to addedKan', () {
      final state = _dealtState();
      final seat = 0;

      // Set up existing pon with tiles not in dealt hand
      state.seats[seat].melds.add(MeldData(
        type: 'pon',
        tileIds: [0, 1, 2],
        calledFrom: 1,
        calledTileId: 2,
      ));
      // Remove tile 3 from hand first (if present from deal), then add it back
      state.seats[seat].handTileIds.remove(3);
      state.seats[seat].handTileIds.add(3);

      TableLogic.addedKan(state, seat, 3, 0);

      expect(state.seats[seat].melds.first.type, 'addedKan');
      expect(state.seats[seat].melds.first.tileIds.length, 4);
      expect(state.seats[seat].handTileIds.contains(3), false);
    });

    test('does not upgrade non-pon meld', () {
      final state = _dealtState();
      final seat = 0;

      state.seats[seat].melds.add(MeldData(
        type: 'chi',
        tileIds: [0, 4, 8],
      ));
      state.seats[seat].handTileIds.add(12);

      TableLogic.addedKan(state, seat, 12, 0);

      expect(state.seats[seat].melds.first.type, 'chi'); // unchanged
    });
  });

  group('TableLogic.riichi', () {
    test('sets riichi flag, deducts 1000, discards tile', () {
      final state = _dealtState();
      final seat = state.dealerSeat;
      final tileId = state.seats[seat].handTileIds.first;
      final scoreBefore = state.scores[seat];

      TableLogic.riichi(state, seat, tileId);

      expect(state.seats[seat].isRiichi, true);
      expect(state.scores[seat], scoreBefore - 1000);
      expect(state.riichiSticksOnTable, 1);
      expect(state.seats[seat].discards.last.isRiichiDiscard, true);
      expect(state.lastDiscardedTileId, tileId);
    });

    test('does not double-riichi', () {
      final state = _dealtState();
      final seat = state.dealerSeat;
      state.seats[seat].isRiichi = true;
      final scoreBefore = state.scores[seat];

      TableLogic.riichi(state, seat, state.seats[seat].handTileIds.first);

      expect(state.scores[seat], scoreBefore); // unchanged
    });
  });

  group('TableLogic.drawFlower', () {
    test('moves flower from hand to display, draws replacement', () {
      final state = _dealtState(
          config: const GameConfig(tileCount: 144, isRiichi: false));
      final seat = state.dealerSeat;

      // Find a flower tile in hand, or manually add one
      final flowerTileId = 136; // 春
      state.seats[seat].handTileIds.add(flowerTileId);
      final wallBefore = state.liveTileIds.length;

      TableLogic.drawFlower(state, seat, flowerTileId);

      expect(state.seats[seat].handTileIds.contains(flowerTileId), false);
      expect(state.seats[seat].flowerTileIds.contains(flowerTileId), true);
      expect(state.liveTileIds.length, wallBefore - 1);
    });

    test('does not draw flower if tile not in hand', () {
      final state = _dealtState(
          config: const GameConfig(tileCount: 144, isRiichi: false));
      final seat = state.dealerSeat;
      final wallBefore = state.liveTileIds.length;

      TableLogic.drawFlower(state, seat, 999); // invalid tile

      expect(state.seats[seat].flowerTileIds, isEmpty);
      expect(state.liveTileIds.length, wallBefore);
    });
  });

  group('TableLogic.chooseMissingSuit', () {
    test('sets missing suit', () {
      final state = _dealtState(
          config: const GameConfig(tileCount: 108, isRiichi: false));
      TableLogic.chooseMissingSuit(state, 0, 0);
      expect(state.seats[0].missingSuit, 0);

      TableLogic.chooseMissingSuit(state, 1, 2);
      expect(state.seats[1].missingSuit, 2);
    });

    test('rejects invalid suit', () {
      final state = _dealtState();
      TableLogic.chooseMissingSuit(state, 0, 3); // invalid
      expect(state.seats[0].missingSuit, isNull);

      TableLogic.chooseMissingSuit(state, 0, -1); // invalid
      expect(state.seats[0].missingSuit, isNull);
    });
  });

  group('TableLogic.sortHand', () {
    test('sorts by kind', () {
      final state = _dealtState();
      final seat = 0;
      // Shuffle hand manually
      state.seats[seat].handTileIds.shuffle(Random(99));
      final unsorted = List<int>.from(state.seats[seat].handTileIds);

      TableLogic.sortHand(state, seat);

      final sorted = state.seats[seat].handTileIds;
      // Verify sorted by kind
      for (int i = 0; i < sorted.length - 1; i++) {
        final kindA = sorted[i] >= 136 ? sorted[i] : sorted[i] ~/ 4;
        final kindB =
            sorted[i + 1] >= 136 ? sorted[i + 1] : sorted[i + 1] ~/ 4;
        expect(kindA <= kindB, true,
            reason: 'Hand not sorted at index $i: $kindA > $kindB');
      }
      // Same tiles, just reordered
      expect(sorted.toSet(), unsorted.toSet());
    });
  });

  group('TableLogic.showHand / hideHand', () {
    test('showHand reveals, hideHand conceals', () {
      final state = _dealtState();
      expect(state.seats[0].handRevealed, false);

      TableLogic.showHand(state, 0);
      expect(state.seats[0].handRevealed, true);

      TableLogic.hideHand(state, 0);
      expect(state.seats[0].handRevealed, false);
    });
  });

  group('TableLogic.undoDiscard', () {
    test('returns tile to hand', () {
      final state = _dealtState();
      final seat = state.dealerSeat;
      final tileId = state.seats[seat].handTileIds.first;

      TableLogic.discard(state, seat, tileId);
      expect(state.seats[seat].handTileIds.contains(tileId), false);

      TableLogic.undoDiscard(state, seat);
      expect(state.seats[seat].handTileIds.contains(tileId), true);
      expect(state.seats[seat].discards, isEmpty);
      expect(state.lastDiscardedBy, isNull);
      expect(state.hasDrawnThisTurn, true);
    });

    test('cannot undo riichi discard', () {
      final state = _dealtState();
      final seat = state.dealerSeat;
      final tileId = state.seats[seat].handTileIds.first;

      TableLogic.riichi(state, seat, tileId);

      TableLogic.undoDiscard(state, seat);
      // Riichi discard should NOT be undone
      expect(state.seats[seat].discards.length, 1);
    });

    test('cannot undo if not the last discarder', () {
      final state = _dealtState();
      final seat = state.dealerSeat;
      final tileId = state.seats[seat].handTileIds.first;

      TableLogic.discard(state, seat, tileId);

      // Different seat tries to undo
      TableLogic.undoDiscard(state, (seat + 1) % 4);
      expect(state.seats[seat].discards.length, 1); // unchanged
    });
  });

  group('TableLogic.declareWin', () {
    test('creates pending win proposal', () {
      final state = _dealtState();
      TableLogic.declareWin(state, 0, true, 3, 30);

      expect(state.pendingWin, isNotNull);
      expect(state.pendingWin!.seatIndex, 0);
      expect(state.pendingWin!.isTsumo, true);
      expect(state.pendingWin!.han, 3);
      expect(state.pendingWin!.fu, 30);
    });
  });

  group('TableLogic.confirmWin / rejectWin', () {
    test('2 confirms applies win', () {
      final state = _dealtState();
      TableLogic.declareWin(state, 0, true, 3, 30);

      TableLogic.confirmWin(state, 1);
      expect(state.pendingWin, isNotNull); // still pending

      TableLogic.confirmWin(state, 2);
      expect(state.pendingWin, isNull); // applied
    });

    test('2 rejects cancels win', () {
      final state = _dealtState();
      TableLogic.declareWin(state, 0, true, 3, 30);

      TableLogic.rejectWin(state, 1);
      expect(state.pendingWin, isNotNull);

      TableLogic.rejectWin(state, 2);
      expect(state.pendingWin, isNull); // cancelled
    });

    test('winner cannot confirm own win', () {
      final state = _dealtState();
      TableLogic.declareWin(state, 0, true, 3, 30);

      TableLogic.confirmWin(state, 0); // self-confirm
      expect(state.pendingWin!.confirmed, isEmpty);
    });
  });

  group('TableLogic.exchangePropose/Confirm/Reject', () {
    test('propose creates pending exchange', () {
      final state = _dealtState();
      TableLogic.exchangePropose(state, 0, 1, 5000);

      expect(state.pendingExchange, isNotNull);
      expect(state.pendingExchange!.fromSeat, 0);
      expect(state.pendingExchange!.toSeat, 1);
      expect(state.pendingExchange!.amount, 5000);
    });

    test('confirm applies exchange', () {
      final state = _dealtState();
      final s0Before = state.scores[0];
      final s1Before = state.scores[1];
      TableLogic.exchangePropose(state, 0, 1, 5000);
      TableLogic.exchangeConfirm(state, 1);

      expect(state.scores[0], s0Before - 5000);
      expect(state.scores[1], s1Before + 5000);
      expect(state.pendingExchange, isNull);
    });

    test('reject cancels exchange', () {
      final state = _dealtState();
      final s0Before = state.scores[0];
      TableLogic.exchangePropose(state, 0, 1, 5000);
      TableLogic.exchangeReject(state, 1);

      expect(state.scores[0], s0Before); // unchanged
      expect(state.pendingExchange, isNull);
    });

    test('wrong seat cannot confirm', () {
      final state = _dealtState();
      TableLogic.exchangePropose(state, 0, 1, 5000);
      TableLogic.exchangeConfirm(state, 2); // wrong seat

      expect(state.pendingExchange, isNotNull); // still pending
    });
  });

  group('TableLogic.adjustScore', () {
    test('adjusts score by delta', () {
      final state = _dealtState();
      final before = state.scores[2];

      TableLogic.adjustScore(state, 2, 1000);
      expect(state.scores[2], before + 1000);

      TableLogic.adjustScore(state, 2, -500);
      expect(state.scores[2], before + 500);
    });
  });

  group('TableLogic.revealDora', () {
    test('increments dora count up to 5', () {
      final state = _dealtState();
      expect(state.doraRevealed, 1);

      TableLogic.revealDora(state);
      expect(state.doraRevealed, 2);

      for (int i = 0; i < 10; i++) {
        TableLogic.revealDora(state);
      }
      expect(state.doraRevealed, 5); // capped at 5
    });

    test('noKanDora blocks additional reveals after initial', () {
      final state = _dealtState(config: const GameConfig(
        tileCount: 136,
        isRiichi: true,
        riichiMode: 'custom',
        noKanDora: true,
      ));
      expect(state.doraRevealed, 1); // initial dora

      TableLogic.revealDora(state);
      expect(state.doraRevealed, 1); // blocked by noKanDora
    });
  });

  group('TableLogic.declareWinSichuan', () {
    test('creates sichuan win proposal with 2^han payments', () {
      final state = _dealtState(config: const GameConfig(
        tileCount: 108,
        isRiichi: false,
      ));
      TableLogic.declareWinSichuan(state, 0, true, 3);

      expect(state.pendingWin, isNotNull);
      expect(state.pendingWin!.seatIndex, 0);
      expect(state.pendingWin!.isTsumo, true);
      // 2^3 = 8 per player, tsumo total = 24
      expect(state.pendingWin!.totalPoints, 24);
      expect(state.pendingWin!.payments[1], -8);
      expect(state.pendingWin!.payments[2], -8);
      expect(state.pendingWin!.payments[3], -8);
    });
  });

  group('TableLogic.declareWinDirect', () {
    test('creates direct win proposal', () {
      final state = _dealtState(config: const GameConfig(
        tileCount: 136,
        isRiichi: false,
      ));
      TableLogic.declareWinDirect(state, 2, true, 10);

      expect(state.pendingWin, isNotNull);
      expect(state.pendingWin!.seatIndex, 2);
      expect(state.pendingWin!.totalPoints, 30);
      expect(state.pendingWin!.payments[0], -10);
      expect(state.pendingWin!.payments[1], -10);
      expect(state.pendingWin!.payments[3], -10);
    });

    test('direct ron: only loser pays', () {
      final state = _dealtState(config: const GameConfig(
        tileCount: 136,
        isRiichi: false,
      ));
      // Set up a last discard
      state.lastDiscardedBy = 1;
      TableLogic.declareWinDirect(state, 0, false, 8);

      expect(state.pendingWin!.payments[0], 8);
      expect(state.pendingWin!.payments[1], -8);
      expect(state.pendingWin!.payments[2], 0);
      expect(state.pendingWin!.payments[3], 0);
    });
  });

  group('TableLogic.newRound', () {
    test('rotate dealer advances dealer seat', () {
      final state = _dealtState();
      final oldDealer = state.dealerSeat;

      TableLogic.newRound(state, Random(99), false);

      expect(state.dealerSeat, (oldDealer + 1) % 4);
      expect(state.honbaCount, 0);
      expect(state.gameStarted, true); // re-dealt
    });

    test('keep dealer increments honba', () {
      final state = _dealtState();
      final oldDealer = state.dealerSeat;

      TableLogic.newRound(state, Random(99), true);

      expect(state.dealerSeat, oldDealer); // same
      expect(state.honbaCount, 1);
    });

    test('round wind advances after 4 rotations', () {
      final state = _dealtState();
      expect(state.roundWind, 0); // East

      for (int i = 0; i < 4; i++) {
        TableLogic.newRound(state, Random(i), false);
      }
      expect(state.roundWind, 1); // South
    });
  });

  group('ServerState.toJsonForSeat', () {
    test('includes all required fields', () {
      final state = _dealtState();
      final json = state.toJsonForSeat(0);

      expect(json['wallRemaining'], isA<int>());
      expect(json['doraIndicatorTileIds'], isA<List>());
      expect(json['seats'], isA<List>());
      expect(json['nicknames'], isA<List>());
      expect(json['scores'], isA<List>());
      expect(json['gameStarted'], true);
      expect(json['config'], isA<Map>());
    });

    test('viewer seat sees hand tile IDs', () {
      final state = _dealtState();
      final json = state.toJsonForSeat(0);
      final seat0 = json['seats'][0] as Map<String, dynamic>;
      final seat1 = json['seats'][1] as Map<String, dynamic>;

      expect(seat0.containsKey('handTileIds'), true);
      expect(seat1.containsKey('handTileIds'), false);
    });

    test('includes baida reference when set', () {
      final state = _dealtState(
          config: const GameConfig(
              tileCount: 144, isRiichi: false, hasBaida: true));
      final json = state.toJsonForSeat(0);
      expect(json.containsKey('baidaReferenceTileId'), true);
    });

    test('excludes baida reference when null', () {
      final state = _dealtState();
      final json = state.toJsonForSeat(0);
      expect(json.containsKey('baidaReferenceTileId'), false);
    });
  });

  group('ServerState action log', () {
    test('caps at 50 entries', () {
      final state = _dealtState();
      for (int i = 0; i < 100; i++) {
        state.addLog(0, 'test', detail: 'entry $i');
      }
      expect(state.actionLog.length, lessThanOrEqualTo(50));
    });
  });
}
