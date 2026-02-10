import 'dart:math';
import '../tile/tile.dart';
import '../tile/tile_constants.dart';

/// The 136-tile wall with live wall, dead wall, and dora indicators.
class Wall {
  final List<Tile> liveTiles;
  final List<Tile> deadWall; // 14 tiles
  int _doraRevealed;

  Wall._({
    required this.liveTiles,
    required this.deadWall,
    required int doraRevealed,
  }) : _doraRevealed = doraRevealed;

  /// Create and shuffle a new wall.
  factory Wall.shuffled({Random? random, bool useRedDora = true}) {
    final rng = random ?? Random();
    final allTiles = List.generate(136, (i) => Tile(i));
    allTiles.shuffle(rng);

    // Dead wall is the last 14 tiles
    final dead = allTiles.sublist(allTiles.length - 14);
    final live = allTiles.sublist(0, allTiles.length - 14);

    return Wall._(liveTiles: live, deadWall: dead, doraRevealed: 1);
  }

  /// Number of remaining drawable tiles.
  int get remaining => liveTiles.length;

  /// Number of dora indicators revealed.
  int get doraRevealedCount => _doraRevealed;

  /// The currently revealed dora indicator tiles.
  /// Indicators are at positions 0, 2, 4, 6, 8 in the dead wall.
  List<Tile> get doraIndicators {
    final indicators = <Tile>[];
    for (int i = 0; i < _doraRevealed && i < 5; i++) {
      indicators.add(deadWall[i * 2]);
    }
    return indicators;
  }

  /// Ura-dora indicators (under the regular dora indicators).
  /// At positions 1, 3, 5, 7, 9 in the dead wall.
  List<Tile> get uraDoraIndicators {
    final indicators = <Tile>[];
    for (int i = 0; i < _doraRevealed && i < 5; i++) {
      indicators.add(deadWall[i * 2 + 1]);
    }
    return indicators;
  }

  /// The actual dora tile kinds (derived from indicators).
  List<int> get doraKinds {
    return doraIndicators
        .map((t) => TileConstants.doraFromIndicator(t.kind))
        .toList();
  }

  /// The actual ura-dora tile kinds.
  List<int> get uraDoraKinds {
    return uraDoraIndicators
        .map((t) => TileConstants.doraFromIndicator(t.kind))
        .toList();
  }

  /// Draw one tile from the live wall. Returns null if empty.
  Tile? draw() {
    if (liveTiles.isEmpty) return null;
    return liveTiles.removeAt(0);
  }

  /// Draw from the dead wall (for kan replacement). Uses tiles from index 10+.
  Tile? drawFromDeadWall() {
    if (deadWall.length <= 10) return null;
    final tile = deadWall.removeAt(deadWall.length - 1);
    // Move one tile from live wall to dead wall to maintain dead wall size
    if (liveTiles.isNotEmpty) {
      deadWall.add(liveTiles.removeLast());
    }
    return tile;
  }

  /// Reveal the next dora indicator (called after each kan).
  void revealNewDoraIndicator() {
    if (_doraRevealed < 5) {
      _doraRevealed++;
    }
  }

  /// Create a deep copy of this wall.
  Wall copy() {
    return Wall._(
      liveTiles: List.from(liveTiles),
      deadWall: List.from(deadWall),
      doraRevealed: _doraRevealed,
    );
  }
}
