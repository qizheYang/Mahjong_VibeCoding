import 'tile_type.dart';
import 'tile_constants.dart';

/// Represents one of the 136 physical tiles in a mahjong set.
///
/// Each tile has a unique [id] (0-135). Every 4 consecutive IDs share the same
/// [kind] (0-33), representing the 34 unique tile faces.
///
/// Layout:
///   kinds 0-8:   1m-9m (man/characters)
///   kinds 9-17:  1p-9p (pin/circles)
///   kinds 18-26: 1s-9s (sou/bamboo)
///   kinds 27-30: East, South, West, North winds
///   kinds 31-33: Haku, Hatsu, Chun dragons
class Tile {
  final int id;

  const Tile(this.id) : assert(id >= 0 && id < 136);

  /// Which of the 34 unique faces this tile is (0-33).
  int get kind => id ~/ 4;

  /// Which copy of this kind (0-3).
  int get copyIndex => id % 4;

  /// The suit/category of this tile.
  TileType get type => TileConstants.typeOf(kind);

  /// Face number: 1-9 for suited tiles, 1-4 for winds, 1-3 for dragons.
  int get number => TileConstants.numberOf(kind);

  bool get isRedDora => TileConstants.redDoraIds.contains(id);
  bool get isTerminal => TileConstants.isTerminal(kind);
  bool get isHonor => TileConstants.isHonor(kind);
  bool get isTerminalOrHonor => isTerminal || isHonor;
  bool get isSuited => kind < 27;

  /// The suit index (0=man, 1=pin, 2=sou). Only valid for suited tiles.
  int get suitIndex {
    assert(isSuited);
    return kind ~/ 9;
  }

  /// Short string like "1m", "5p", "East", "Chun".
  String get shortName {
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
    return Tile(kind * 4 + copyIndex);
  }
}
