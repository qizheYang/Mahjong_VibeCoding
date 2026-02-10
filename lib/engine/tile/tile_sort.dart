import 'tile.dart';

class TileSort {
  TileSort._();

  /// Sort tiles by kind, then by copy index. Standard display order:
  /// man (1-9) → pin (1-9) → sou (1-9) → winds (E/S/W/N) → dragons (Haku/Hatsu/Chun).
  static List<Tile> sort(List<Tile> tiles) {
    final sorted = List<Tile>.from(tiles);
    sorted.sort((a, b) {
      final kindCmp = a.kind.compareTo(b.kind);
      if (kindCmp != 0) return kindCmp;
      return a.copyIndex.compareTo(b.copyIndex);
    });
    return sorted;
  }

  /// Comparison function for two tiles.
  static int compare(Tile a, Tile b) {
    final kindCmp = a.kind.compareTo(b.kind);
    if (kindCmp != 0) return kindCmp;
    return a.copyIndex.compareTo(b.copyIndex);
  }
}
