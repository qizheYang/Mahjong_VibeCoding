import '../tile/tile.dart';

enum MeldType { chi, pon, openKan, closedKan, addedKan }

/// Represents a declared meld (set of tiles called or declared).
class Meld {
  final MeldType type;
  final List<Tile> tiles;

  /// The seat index of the player the tile was called from (null for closed kan).
  final int? calledFrom;

  /// Which specific tile was the called one (for display: rotated tile).
  final Tile? calledTile;

  const Meld({
    required this.type,
    required this.tiles,
    this.calledFrom,
    this.calledTile,
  });

  bool get isOpen => type != MeldType.closedKan;

  /// Whether this meld is a kan (any variant).
  bool get isKan =>
      type == MeldType.openKan ||
      type == MeldType.closedKan ||
      type == MeldType.addedKan;

  /// The kind of all tiles in this meld (they share the same kind except for
  /// chi, where we use the lowest kind).
  int get kind => tiles.first.kind;

  /// All kinds in this meld (sorted).
  List<int> get kinds {
    final k = tiles.map((t) => t.kind).toList()..sort();
    return k;
  }

  /// Convert added kan back for scoring (treat as pon + 1).
  int get tileCount => tiles.length;

  Meld copyWith({
    MeldType? type,
    List<Tile>? tiles,
    int? calledFrom,
    Tile? calledTile,
  }) {
    return Meld(
      type: type ?? this.type,
      tiles: tiles ?? this.tiles,
      calledFrom: calledFrom ?? this.calledFrom,
      calledTile: calledTile ?? this.calledTile,
    );
  }

  @override
  String toString() => 'Meld($type, ${tiles.join(", ")})';
}
