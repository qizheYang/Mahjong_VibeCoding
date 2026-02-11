import 'package:flutter_test/flutter_test.dart';
import 'package:mahjong/engine/tile/tile.dart';
import 'package:mahjong/engine/tile/tile_type.dart';

void main() {
  group('Tile basic properties', () {
    test('standard tile kind = id ~/ 4', () {
      expect(Tile(0).kind, 0); // 1m copy 0
      expect(Tile(3).kind, 0); // 1m copy 3
      expect(Tile(4).kind, 1); // 2m copy 0
      expect(Tile(135).kind, 33); // Chun copy 3
    });

    test('standard tile copyIndex = id % 4', () {
      expect(Tile(0).copyIndex, 0);
      expect(Tile(1).copyIndex, 1);
      expect(Tile(2).copyIndex, 2);
      expect(Tile(3).copyIndex, 3);
      expect(Tile(4).copyIndex, 0);
    });

    test('flower tile kind = 34 + (id - 136)', () {
      expect(Tile(136).kind, 34); // 春
      expect(Tile(137).kind, 35); // 夏
      expect(Tile(143).kind, 41); // 菊
      expect(Tile(144).kind, 42); // 百搭 1
      expect(Tile(151).kind, 49); // 聚宝盆
    });

    test('flower tile copyIndex always 0', () {
      expect(Tile(136).copyIndex, 0);
      expect(Tile(144).copyIndex, 0);
      expect(Tile(151).copyIndex, 0);
    });
  });

  group('Tile types', () {
    test('man tiles (kinds 0-8)', () {
      for (int k = 0; k < 9; k++) {
        expect(Tile(k * 4).type, TileType.man);
      }
    });

    test('pin tiles (kinds 9-17)', () {
      for (int k = 9; k < 18; k++) {
        expect(Tile(k * 4).type, TileType.pin);
      }
    });

    test('sou tiles (kinds 18-26)', () {
      for (int k = 18; k < 27; k++) {
        expect(Tile(k * 4).type, TileType.sou);
      }
    });

    test('wind tiles (kinds 27-30)', () {
      for (int k = 27; k < 31; k++) {
        expect(Tile(k * 4).type, TileType.wind);
      }
    });

    test('dragon tiles (kinds 31-33)', () {
      for (int k = 31; k < 34; k++) {
        expect(Tile(k * 4).type, TileType.dragon);
      }
    });

    test('flower tiles (id >= 136)', () {
      expect(Tile(136).type, TileType.flower);
      expect(Tile(144).type, TileType.flower);
      expect(Tile(151).type, TileType.flower);
    });
  });

  group('Tile number', () {
    test('man tiles are 1-9', () {
      for (int i = 0; i < 9; i++) {
        expect(Tile(i * 4).number, i + 1);
      }
    });

    test('pin tiles are 1-9', () {
      for (int i = 0; i < 9; i++) {
        expect(Tile((9 + i) * 4).number, i + 1);
      }
    });

    test('wind tiles are 1-4', () {
      expect(Tile(27 * 4).number, 1); // East
      expect(Tile(28 * 4).number, 2); // South
      expect(Tile(29 * 4).number, 3); // West
      expect(Tile(30 * 4).number, 4); // North
    });

    test('dragon tiles are 1-3', () {
      expect(Tile(31 * 4).number, 1); // Haku
      expect(Tile(32 * 4).number, 2); // Hatsu
      expect(Tile(33 * 4).number, 3); // Chun
    });

    test('flower tile number is index from 136', () {
      expect(Tile(136).number, 0);
      expect(Tile(140).number, 4);
      expect(Tile(151).number, 15);
    });
  });

  group('Tile flags', () {
    test('red dora tiles', () {
      expect(Tile(16).isRedDora, true); // 5m copy 0
      expect(Tile(52).isRedDora, true); // 5p copy 0
      expect(Tile(88).isRedDora, true); // 5s copy 0
      expect(Tile(17).isRedDora, false); // 5m copy 1
      expect(Tile(0).isRedDora, false);
    });

    test('terminal tiles', () {
      expect(Tile(0).isTerminal, true); // 1m
      expect(Tile(32).isTerminal, true); // 9m
      expect(Tile(4).isTerminal, false); // 2m
      expect(Tile(108).isTerminal, false); // East wind
    });

    test('honor tiles', () {
      expect(Tile(108).isHonor, true); // East
      expect(Tile(124).isHonor, true); // Haku
      expect(Tile(0).isHonor, false);
      expect(Tile(136).isHonor, false); // flowers are not honors
    });

    test('isFlower', () {
      expect(Tile(135).isFlower, false);
      expect(Tile(136).isFlower, true);
      expect(Tile(151).isFlower, true);
    });

    test('isSuited', () {
      expect(Tile(0).isSuited, true); // 1m
      expect(Tile(107).isSuited, true); // 9s last copy
      expect(Tile(108).isSuited, false); // East wind
    });

    test('isBaida', () {
      expect(Tile(143).isBaida, false); // 菊
      expect(Tile(144).isBaida, true); // 百搭 1
      expect(Tile(147).isBaida, true); // 百搭 4
      expect(Tile(148).isBaida, false); // 老鼠
    });
  });

  group('Tile suitIndex', () {
    test('man = 0, pin = 1, sou = 2', () {
      expect(Tile(0).suitIndex, 0); // 1m
      expect(Tile(36).suitIndex, 1); // 1p
      expect(Tile(72).suitIndex, 2); // 1s
    });
  });

  group('Tile flowerGroup', () {
    test('seasons = 0', () {
      expect(Tile(136).flowerGroup, 0); // 春
      expect(Tile(139).flowerGroup, 0); // 冬
    });

    test('plants = 1', () {
      expect(Tile(140).flowerGroup, 1); // 梅
      expect(Tile(143).flowerGroup, 1); // 菊
    });

    test('joker = 2', () {
      expect(Tile(144).flowerGroup, 2); // 百搭 1
      expect(Tile(147).flowerGroup, 2); // 百搭 4
    });

    test('suzhou specials = 3', () {
      expect(Tile(148).flowerGroup, 3); // 老鼠
      expect(Tile(151).flowerGroup, 3); // 聚宝盆
    });
  });

  group('Tile shortName', () {
    test('suited tiles', () {
      expect(Tile(0).shortName, '1m');
      expect(Tile(36).shortName, '1p');
      expect(Tile(72).shortName, '1s');
      expect(Tile(32).shortName, '9m');
    });

    test('wind tiles', () {
      expect(Tile(108).shortName, 'East');
      expect(Tile(112).shortName, 'South');
      expect(Tile(116).shortName, 'West');
      expect(Tile(120).shortName, 'North');
    });

    test('dragon tiles', () {
      expect(Tile(124).shortName, 'Haku');
      expect(Tile(128).shortName, 'Hatsu');
      expect(Tile(132).shortName, 'Chun');
    });

    test('standard flower tiles', () {
      expect(Tile(136).shortName, '春');
      expect(Tile(137).shortName, '夏');
      expect(Tile(138).shortName, '秋');
      expect(Tile(139).shortName, '冬');
      expect(Tile(140).shortName, '梅');
      expect(Tile(141).shortName, '兰');
      expect(Tile(142).shortName, '竹');
      expect(Tile(143).shortName, '菊');
    });

    test('suzhou special tiles', () {
      expect(Tile(144).shortName, '百搭');
      expect(Tile(145).shortName, '百搭');
      expect(Tile(148).shortName, '鼠');
      expect(Tile(149).shortName, '财');
      expect(Tile(150).shortName, '猫');
      expect(Tile(151).shortName, '宝');
    });
  });

  group('Tile.fromKind factory', () {
    test('standard tiles', () {
      expect(Tile.fromKind(0, 0).id, 0);
      expect(Tile.fromKind(0, 3).id, 3);
      expect(Tile.fromKind(33, 2).id, 134);
    });

    test('flower tiles', () {
      expect(Tile.fromKind(34).id, 136); // 春
      expect(Tile.fromKind(49).id, 151); // 聚宝盆
    });
  });

  group('Tile equality', () {
    test('same id are equal', () {
      expect(Tile(0) == Tile(0), true);
      expect(Tile(136) == Tile(136), true);
    });

    test('different id are not equal', () {
      expect(Tile(0) == Tile(1), false);
    });
  });
}
