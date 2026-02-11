import 'package:test/test.dart';
import 'package:mahjong_server/sichuan_ai.dart';

void main() {
  group('SichuanAi.chooseMissingSuit', () {
    test('picks suit with fewest tiles', () {
      // 2 man, 5 pin, 6 sou → should pick man (suit 0)
      final hand = [
        0, 4, // 1m, 2m
        36, 40, 44, 48, 52, // 1p-5p
        72, 76, 80, 84, 88, 92, // 1s-6s
      ];
      expect(SichuanAi.chooseMissingSuit(hand), 0);
    });

    test('picks pin when fewest', () {
      // 5 man, 1 pin, 4 sou
      final hand = [
        0, 4, 8, 12, 16, // 1m-5m
        36, // 1p
        72, 76, 80, 84, // 1s-4s
      ];
      expect(SichuanAi.chooseMissingSuit(hand), 1);
    });
  });

  group('SichuanAi.chooseDiscard', () {
    test('discards missing suit tile first', () {
      final hand = [0, 4, 8, 36, 72, 76]; // has man, pin, sou
      final discard = SichuanAi.chooseDiscard(hand, 1); // missing pin
      // Should discard the pin tile (36)
      expect(discard ~/ 4, greaterThanOrEqualTo(9));
      expect(discard ~/ 4, lessThan(18));
    });

    test('discards from valid tiles when no missing suit tiles', () {
      final hand = [0, 4, 8, 72, 76, 80]; // man + sou, missing pin
      final discard = SichuanAi.chooseDiscard(hand, 1);
      // Should not discard a pin tile (none in hand)
      expect(hand.contains(discard), true);
    });
  });

  group('SichuanAi.shouldPon', () {
    test('pons when has 2 matching tiles', () {
      final hand = [0, 1, 4, 8, 72, 76]; // has 2x kind-0 (1m)
      expect(SichuanAi.shouldPon(hand, 0, 1), true); // pon 1m, missing pin
    });

    test('does not pon missing suit', () {
      final hand = [36, 37, 4, 8, 72, 76]; // has 2x kind-9 (1p)
      expect(SichuanAi.shouldPon(hand, 9, 1), false); // missing pin, don't pon pin
    });

    test('does not pon when only 1 matching', () {
      final hand = [0, 4, 8, 72, 76, 80];
      expect(SichuanAi.shouldPon(hand, 0, 1), false); // only 1 of kind-0
    });
  });

  group('SichuanAi.isWinningHand', () {
    test('valid winning hand: 4 groups + 1 pair', () {
      // 1m1m1m 2m3m4m 5m6m7m 1s2s3s 9s9s — 14 tiles
      final hand = [
        0, 1, 2, // 1m 1m 1m (triplet)
        4, 8, 12, // 2m 3m 4m (sequence)
        16, 20, 24, // 5m 6m 7m (sequence)
        72, 76, 80, // 1s 2s 3s (sequence)
        104, 105, // 9s 9s (pair)
      ];
      expect(SichuanAi.isWinningHand(hand, 1), true); // missing pin
    });

    test('not winning with missing suit tiles', () {
      // Same hand but include a pin tile
      final hand = [
        0, 1, 2, // 1m 1m 1m
        4, 8, 12, // 2m 3m 4m
        16, 20, 24, // 5m 6m 7m
        36, 40, 44, // 1p 2p 3p — invalid for missing pin
        104, 105, // 9s 9s
      ];
      expect(SichuanAi.isWinningHand(hand, 1), false);
    });

    test('not winning with incomplete hand', () {
      final hand = [0, 1, 4, 8, 72, 76];
      expect(SichuanAi.isWinningHand(hand, 1), false);
    });
  });

  group('SichuanAi.countHan', () {
    test('base 1 han', () {
      final hand = [
        0, 1, 2, // 1m triplet
        4, 8, 12, // 2m 3m 4m sequence
        16, 20, 24, // 5m 6m 7m sequence
        72, 76, 80, // 1s 2s 3s sequence
        104, 105, // 9s pair
      ];
      expect(SichuanAi.countHan(hand, 1), 1);
    });

    test('all triplets = +1 han', () {
      // All triplets + pair
      final hand = [
        0, 1, 2, // 1m x3
        4, 5, 6, // 2m x3
        8, 9, 10, // 3m x3
        72, 73, 74, // 1s x3
        76, 77, // 2s pair
      ];
      expect(SichuanAi.countHan(hand, 1), 2);
    });

    test('single suit = +1 han', () {
      // All man tiles
      final hand = [
        0, 1, 2, // 1m x3
        4, 8, 12, // 2m 3m 4m
        16, 20, 24, // 5m 6m 7m
        28, 29, 30, // 8m x3
        32, 33, // 9m pair
      ];
      expect(SichuanAi.countHan(hand, 1), 2);
    });
  });
}
