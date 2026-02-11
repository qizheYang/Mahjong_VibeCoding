import 'package:flutter_test/flutter_test.dart';
import 'package:mahjong/models/game_config.dart';

void main() {
  group('GameConfig defaults', () {
    test('default config is Riichi 136', () {
      const config = GameConfig();
      expect(config.tileCount, 136);
      expect(config.isRiichi, true);
      expect(config.hasBaida, false);
      expect(config.startingPoints, 25000);
    });
  });

  group('GameConfig variant getters', () {
    test('isSichuan', () {
      const config = GameConfig(tileCount: 108, isRiichi: false);
      expect(config.isSichuan, true);
      expect(config.isShanghai, false);
      expect(config.isSuzhou, false);
    });

    test('isShanghai', () {
      const config =
          GameConfig(tileCount: 144, isRiichi: false, hasBaida: true);
      expect(config.isShanghai, true);
      expect(config.isSichuan, false);
      expect(config.isSuzhou, false);
    });

    test('isSuzhou', () {
      const config = GameConfig(tileCount: 152, isRiichi: false);
      expect(config.isSuzhou, true);
      expect(config.isSichuan, false);
      expect(config.isShanghai, false);
    });

    test('hasFlowers', () {
      expect(const GameConfig(tileCount: 108).hasFlowers, false);
      expect(const GameConfig(tileCount: 136).hasFlowers, false);
      expect(const GameConfig(tileCount: 144).hasFlowers, true);
      expect(const GameConfig(tileCount: 152).hasFlowers, true);
    });

    test('hasDora only for Riichi 136', () {
      expect(
          const GameConfig(tileCount: 136, isRiichi: true).hasDora, true);
      expect(
          const GameConfig(tileCount: 136, isRiichi: false).hasDora, false);
      expect(
          const GameConfig(tileCount: 144, isRiichi: false).hasDora, false);
    });

    test('hasDeadWall only for Riichi 136', () {
      expect(
          const GameConfig(tileCount: 136, isRiichi: true).hasDeadWall,
          true);
      expect(
          const GameConfig(tileCount: 136, isRiichi: false).hasDeadWall,
          false);
      expect(
          const GameConfig(tileCount: 144, isRiichi: false).hasDeadWall,
          false);
    });

    test('deadWallSize', () {
      expect(
          const GameConfig(tileCount: 136, isRiichi: true).deadWallSize, 14);
      expect(
          const GameConfig(tileCount: 136, isRiichi: false).deadWallSize, 0);
    });
  });

  group('GameConfig.variantKey', () {
    test('all variants', () {
      expect(
          const GameConfig(tileCount: 108, isRiichi: false).variantKey,
          'sichuan');
      expect(const GameConfig(tileCount: 136, isRiichi: true).variantKey,
          'riichi');
      expect(
          const GameConfig(tileCount: 136, isRiichi: false).variantKey,
          'guobiao');
      expect(
          const GameConfig(tileCount: 144, isRiichi: false).variantKey,
          'guobiaoFlowers');
      expect(
          const GameConfig(
                  tileCount: 144, isRiichi: false, hasBaida: true)
              .variantKey,
          'shanghai');
      expect(
          const GameConfig(tileCount: 152, isRiichi: false).variantKey,
          'suzhou');
    });
  });

  group('GameConfig.generateTileIds', () {
    test('Sichuan 108 tiles', () {
      const config = GameConfig(tileCount: 108, isRiichi: false);
      final ids = config.generateTileIds();
      expect(ids.length, 108);
      expect(ids.first, 0);
      expect(ids.last, 107);
    });

    test('Standard 136 tiles', () {
      const config = GameConfig(tileCount: 136);
      final ids = config.generateTileIds();
      expect(ids.length, 136);
      expect(ids.first, 0);
      expect(ids.last, 135);
    });

    test('Flowers 144 tiles', () {
      const config = GameConfig(tileCount: 144, isRiichi: false);
      final ids = config.generateTileIds();
      expect(ids.length, 144);
      expect(ids.last, 143);
    });

    test('Suzhou 152 tiles', () {
      const config = GameConfig(tileCount: 152, isRiichi: false);
      final ids = config.generateTileIds();
      expect(ids.length, 152);
      expect(ids.last, 151);
    });
  });

  group('GameConfig.isFlowerTile', () {
    test('standard variant: id >= 136 is flower', () {
      const config = GameConfig(tileCount: 144, isRiichi: false);
      expect(config.isFlowerTile(135), false);
      expect(config.isFlowerTile(136), true);
      expect(config.isFlowerTile(143), true);
    });

    test('Suzhou: 百搭 (144-147) NOT flowers', () {
      const config = GameConfig(tileCount: 152, isRiichi: false);
      expect(config.isFlowerTile(136), true); // 春
      expect(config.isFlowerTile(143), true); // 菊
      expect(config.isFlowerTile(144), false); // 百搭 1
      expect(config.isFlowerTile(145), false); // 百搭 2
      expect(config.isFlowerTile(146), false); // 百搭 3
      expect(config.isFlowerTile(147), false); // 百搭 4
      expect(config.isFlowerTile(148), true); // 老鼠
      expect(config.isFlowerTile(149), true); // 财神
      expect(config.isFlowerTile(150), true); // 猫
      expect(config.isFlowerTile(151), true); // 聚宝盆
    });
  });

  group('GameConfig serialization', () {
    test('toJson roundtrip', () {
      const config = GameConfig(
        tileCount: 144,
        isRiichi: false,
        hasBaida: true,
        startingPoints: 0,
      );
      final json = config.toJson();
      final restored = GameConfig.fromJson(json);
      expect(restored.tileCount, 144);
      expect(restored.isRiichi, false);
      expect(restored.hasBaida, true);
      expect(restored.startingPoints, 0);
    });

    test('fromJson with defaults', () {
      final config = GameConfig.fromJson({});
      expect(config.tileCount, 136);
      expect(config.isRiichi, true);
      expect(config.hasBaida, false);
      expect(config.startingPoints, 25000);
    });

    test('fromJson with all fields', () {
      final config = GameConfig.fromJson({
        'tileCount': 108,
        'isRiichi': false,
        'hasBaida': false,
        'startingPoints': 0,
      });
      expect(config.tileCount, 108);
      expect(config.isRiichi, false);
    });
  });

  group('GameConfig.defaultPoints', () {
    test('Riichi 136 = 25000', () {
      expect(GameConfig.defaultPoints(136, true), 25000);
    });

    test('all others = 0', () {
      expect(GameConfig.defaultPoints(108, false), 0);
      expect(GameConfig.defaultPoints(136, false), 0);
      expect(GameConfig.defaultPoints(144, false), 0);
      expect(GameConfig.defaultPoints(152, false), 0);
    });
  });
}
