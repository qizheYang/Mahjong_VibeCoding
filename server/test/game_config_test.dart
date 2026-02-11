import 'package:test/test.dart';
import 'package:mahjong_server/game_config.dart';

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
    });

    test('isShanghai', () {
      const config =
          GameConfig(tileCount: 144, isRiichi: false, hasBaida: true);
      expect(config.isShanghai, true);
    });

    test('isSuzhou', () {
      const config = GameConfig(tileCount: 152, isRiichi: false);
      expect(config.isSuzhou, true);
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
    });

    test('hasDeadWall only for Riichi 136', () {
      expect(
          const GameConfig(tileCount: 136, isRiichi: true).hasDeadWall,
          true);
      expect(
          const GameConfig(tileCount: 136, isRiichi: false).hasDeadWall,
          false);
    });
  });

  group('GameConfig.generateTileIds', () {
    test('correct counts for all variants', () {
      expect(
          const GameConfig(tileCount: 108, isRiichi: false)
              .generateTileIds()
              .length,
          108);
      expect(const GameConfig(tileCount: 136).generateTileIds().length, 136);
      expect(
          const GameConfig(tileCount: 144, isRiichi: false)
              .generateTileIds()
              .length,
          144);
      expect(
          const GameConfig(tileCount: 152, isRiichi: false)
              .generateTileIds()
              .length,
          152);
    });

    test('IDs are sequential from 0', () {
      final ids = const GameConfig(tileCount: 152, isRiichi: false)
          .generateTileIds();
      for (int i = 0; i < 152; i++) {
        expect(ids[i], i);
      }
    });
  });

  group('GameConfig.isFlowerTile', () {
    test('standard 144: all >= 136 are flowers', () {
      const config = GameConfig(tileCount: 144, isRiichi: false);
      expect(config.isFlowerTile(135), false);
      expect(config.isFlowerTile(136), true);
      expect(config.isFlowerTile(143), true);
    });

    test('Suzhou 152: 百搭 (144-147) NOT flowers', () {
      const config = GameConfig(tileCount: 152, isRiichi: false);
      expect(config.isFlowerTile(136), true);
      expect(config.isFlowerTile(143), true);
      expect(config.isFlowerTile(144), false);
      expect(config.isFlowerTile(147), false);
      expect(config.isFlowerTile(148), true);
      expect(config.isFlowerTile(151), true);
    });
  });

  group('GameConfig serialization', () {
    test('toJson/fromJson roundtrip', () {
      const config = GameConfig(
        tileCount: 152,
        isRiichi: false,
        hasBaida: false,
        startingPoints: 100,
      );
      final json = config.toJson();
      final restored = GameConfig.fromJson(json);
      expect(restored.tileCount, config.tileCount);
      expect(restored.isRiichi, config.isRiichi);
      expect(restored.hasBaida, config.hasBaida);
      expect(restored.startingPoints, config.startingPoints);
    });

    test('fromJson defaults', () {
      final config = GameConfig.fromJson({});
      expect(config.tileCount, 136);
      expect(config.isRiichi, true);
    });
  });
}
