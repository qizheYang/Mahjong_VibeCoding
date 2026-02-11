import 'tile_type.dart';
import 'tile_constants.dart';

/// Represents one physical mahjong tile.
///
/// Standard tiles: IDs 0-135 (34 kinds × 4 copies).
/// Flower tiles: IDs 136-151 (each unique, 1 copy).
///
/// Layout:
///   kinds 0-8:   1m-9m (man/characters)
///   kinds 9-17:  1p-9p (pin/circles)
///   kinds 18-26: 1s-9s (sou/bamboo)
///   kinds 27-30: East, South, West, North winds
///   kinds 31-33: Haku, Hatsu, Chun dragons
///   kinds 34-41: 春夏秋冬梅兰竹菊 (season/plant flowers)
///   kinds 42-49: 福禄寿喜琴棋书画 (extra flowers)
class Tile {
  final int id;

  const Tile(this.id) : assert(id >= 0 && id <= 151);

  /// Which of the unique faces this tile is.
  /// Standard tiles: kind = id ~/ 4 (0-33).
  /// Flower tiles: kind = 34 + (id - 136).
  int get kind {
    if (id >= 136) return 34 + (id - 136);
    return id ~/ 4;
  }

  /// Which copy of this kind (0-3 for standard, always 0 for flowers).
  int get copyIndex {
    if (id >= 136) return 0;
    return id % 4;
  }

  /// The suit/category of this tile.
  TileType get type => TileConstants.typeOf(kind);

  /// Face number: 1-9 for suited tiles, 1-4 for winds, 1-3 for dragons.
  /// For flowers, returns the flower index (0-15).
  int get number {
    if (id >= 136) return id - 136;
    return TileConstants.numberOf(kind);
  }

  bool get isRedDora => TileConstants.redDoraIds.contains(id);
  bool get isTerminal => id < 136 && TileConstants.isTerminal(kind);
  bool get isHonor => id < 136 && TileConstants.isHonor(kind);
  bool get isTerminalOrHonor => isTerminal || isHonor;
  bool get isSuited => kind < 27;
  bool get isFlower => id >= 136;

  /// The suit index (0=man, 1=pin, 2=sou). Only valid for suited tiles.
  int get suitIndex {
    assert(isSuited);
    return kind ~/ 9;
  }

  /// Flower group: 0=seasons(春夏秋冬), 1=plants(梅兰竹菊),
  /// 2=auspicious(福禄寿喜), 3=arts(琴棋书画).
  int get flowerGroup {
    assert(isFlower);
    return (id - 136) ~/ 4;
  }

  /// Short string like "1m", "5p", "East", "Chun", "春".
  String get shortName {
    if (isFlower) {
      final idx = id - 136;
      if (idx < TileConstants.flowerNames.length) {
        return TileConstants.flowerNames[idx];
      }
      return '花$idx';
    }
    switch (type) {
      case TileType.man:
        return '${number}m';
      case TileType.pin:
        return '${number}p';
      case TileType.sou:
        return '${number}s';
      case TileType.wind:
        return const ['East', 'South', 'West', 'North'][number - 1];
      case TileType.dragon:
        return const ['Haku', 'Hatsu', 'Chun'][number - 1];
      case TileType.flower:
        return '花'; // fallback
    }
  }

  @override
  bool operator ==(Object other) => other is Tile && other.id == id;

  @override
  int get hashCode => id;

  @override
  String toString() => 'Tile($shortName#$copyIndex${isRedDora ? "r" : ""})';

  /// Create a tile from kind and copy index.
  factory Tile.fromKind(int kind, [int copyIndex = 0]) {
    if (kind >= 34) {
      // Flower tiles: each is unique, copyIndex ignored
      return Tile(136 + (kind - 34));
    }
    return Tile(kind * 4 + copyIndex);
  }
}
