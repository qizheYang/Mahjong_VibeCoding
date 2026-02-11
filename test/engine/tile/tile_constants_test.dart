import 'package:flutter_test/flutter_test.dart';
import 'package:mahjong/engine/tile/tile_constants.dart';
import 'package:mahjong/engine/tile/tile_type.dart';

void main() {
  group('TileConstants.typeOf', () {
    test('man kinds 0-8', () {
      for (int k = 0; k < 9; k++) {
        expect(TileConstants.typeOf(k), TileType.man);
      }
    });

    test('pin kinds 9-17', () {
      for (int k = 9; k < 18; k++) {
        expect(TileConstants.typeOf(k), TileType.pin);
      }
    });

    test('sou kinds 18-26', () {
      for (int k = 18; k < 27; k++) {
        expect(TileConstants.typeOf(k), TileType.sou);
      }
    });

    test('wind kinds 27-30', () {
      for (int k = 27; k < 31; k++) {
        expect(TileConstants.typeOf(k), TileType.wind);
      }
    });

    test('dragon kinds 31-33', () {
      for (int k = 31; k < 34; k++) {
        expect(TileConstants.typeOf(k), TileType.dragon);
      }
    });

    test('flower kinds 34+', () {
      expect(TileConstants.typeOf(34), TileType.flower);
      expect(TileConstants.typeOf(49), TileType.flower);
    });
  });

  group('TileConstants.numberOf', () {
    test('suited tiles return 1-9', () {
      for (int suit = 0; suit < 3; suit++) {
        for (int n = 0; n < 9; n++) {
          expect(TileConstants.numberOf(suit * 9 + n), n + 1);
        }
      }
    });

    test('wind tiles return 1-4', () {
      expect(TileConstants.numberOf(27), 1);
      expect(TileConstants.numberOf(28), 2);
      expect(TileConstants.numberOf(29), 3);
      expect(TileConstants.numberOf(30), 4);
    });

    test('dragon tiles return 1-3', () {
      expect(TileConstants.numberOf(31), 1);
      expect(TileConstants.numberOf(32), 2);
      expect(TileConstants.numberOf(33), 3);
    });
  });

  group('TileConstants terminal/honor checks', () {
    test('isTerminal for 1 and 9 of each suit', () {
      expect(TileConstants.isTerminal(0), true); // 1m
      expect(TileConstants.isTerminal(8), true); // 9m
      expect(TileConstants.isTerminal(9), true); // 1p
      expect(TileConstants.isTerminal(17), true); // 9p
      expect(TileConstants.isTerminal(18), true); // 1s
      expect(TileConstants.isTerminal(26), true); // 9s
    });

    test('isTerminal false for middle tiles', () {
      expect(TileConstants.isTerminal(4), false); // 5m
      expect(TileConstants.isTerminal(13), false); // 5p
    });

    test('isTerminal false for honor tiles', () {
      expect(TileConstants.isTerminal(27), false);
      expect(TileConstants.isTerminal(31), false);
    });

    test('isHonor for winds and dragons', () {
      for (int k = 27; k < 34; k++) {
        expect(TileConstants.isHonor(k), true);
      }
    });

    test('isHonor false for suited and flower', () {
      expect(TileConstants.isHonor(0), false);
      expect(TileConstants.isHonor(34), false);
    });
  });

  group('TileConstants.doraFromIndicator', () {
    test('suited tiles wrap within suit', () {
      expect(TileConstants.doraFromIndicator(0), 1); // 1m -> 2m
      expect(TileConstants.doraFromIndicator(7), 8); // 8m -> 9m
      expect(TileConstants.doraFromIndicator(8), 0); // 9m -> 1m (wrap)
      expect(TileConstants.doraFromIndicator(9), 10); // 1p -> 2p
      expect(TileConstants.doraFromIndicator(17), 9); // 9p -> 1p (wrap)
      expect(TileConstants.doraFromIndicator(26), 18); // 9s -> 1s (wrap)
    });

    test('wind tiles cycle E->S->W->N->E', () {
      expect(TileConstants.doraFromIndicator(27), 28); // E -> S
      expect(TileConstants.doraFromIndicator(28), 29); // S -> W
      expect(TileConstants.doraFromIndicator(29), 30); // W -> N
      expect(TileConstants.doraFromIndicator(30), 27); // N -> E (wrap)
    });

    test('dragon tiles cycle Haku->Hatsu->Chun->Haku', () {
      expect(TileConstants.doraFromIndicator(31), 32); // Haku -> Hatsu
      expect(TileConstants.doraFromIndicator(32), 33); // Hatsu -> Chun
      expect(TileConstants.doraFromIndicator(33), 31); // Chun -> Haku (wrap)
    });
  });

  group('TileConstants.flowerNames', () {
    test('has 16 names', () {
      expect(TileConstants.flowerNames.length, 16);
    });

    test('first 8 are standard flowers', () {
      expect(TileConstants.flowerNames[0], '春');
      expect(TileConstants.flowerNames[7], '菊');
    });

    test('8-11 are 百搭', () {
      expect(TileConstants.flowerNames[8], '百搭');
      expect(TileConstants.flowerNames[11], '百搭');
    });

    test('12-15 are Suzhou specials', () {
      expect(TileConstants.flowerNames[12], '鼠');
      expect(TileConstants.flowerNames[13], '财');
      expect(TileConstants.flowerNames[14], '猫');
      expect(TileConstants.flowerNames[15], '宝');
    });
  });

  group('TileConstants.redDoraIds', () {
    test('contains exactly 3 ids', () {
      expect(TileConstants.redDoraIds, {16, 52, 88});
    });

    test('correspond to 5m, 5p, 5s copy 0', () {
      // 5m = kind 4, copy 0 = id 16
      expect(4 * 4 + 0, 16);
      // 5p = kind 13, copy 0 = id 52
      expect(13 * 4 + 0, 52);
      // 5s = kind 22, copy 0 = id 88
      expect(22 * 4 + 0, 88);
    });
  });

  group('TileConstants.kokushiKinds', () {
    test('has 13 kinds', () {
      expect(TileConstants.kokushiKinds.length, 13);
    });

    test('contains all terminals and honors', () {
      final expected = {0, 8, 9, 17, 18, 26, 27, 28, 29, 30, 31, 32, 33};
      expect(TileConstants.kokushiKinds.toSet(), expected);
    });
  });
}
