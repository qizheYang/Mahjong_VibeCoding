import '../tile/tile.dart';
import '../state/meld.dart';

/// All context needed to evaluate yaku for a winning hand.
class HandContext {
  final List<Tile> closedHandTiles; // tiles in closed portion (including winning tile)
  final List<Meld> melds; // declared melds
  final Tile winningTile;
  final bool isTsumo;
  final bool isRiichi;
  final bool isDoubleRiichi;
  final bool isIppatsu;
  final int seatWind; // 0=E, 1=S, 2=W, 3=N
  final int roundWind; // 0=E, 1=S
  final bool isFirstTurn; // for tenhou/chiihou
  final bool isLastTile; // haitei/houtei
  final bool isAfterKan; // rinshan kaihou
  final bool isChankan; // robbing a kan
  final List<Tile> doraIndicators;
  final List<Tile> uraDoraIndicators;
  final int turnCount; // for chiihou detection

  const HandContext({
    required this.closedHandTiles,
    required this.melds,
    required this.winningTile,
    required this.isTsumo,
    this.isRiichi = false,
    this.isDoubleRiichi = false,
    this.isIppatsu = false,
    required this.seatWind,
    required this.roundWind,
    this.isFirstTurn = false,
    this.isLastTile = false,
    this.isAfterKan = false,
    this.isChankan = false,
    this.doraIndicators = const [],
    this.uraDoraIndicators = const [],
    this.turnCount = 0,
  });

  /// Whether the hand has no open melds.
  bool get isMenzen => melds.every((m) => !m.isOpen);

  /// Build a 34-element kind count array from closed hand tiles.
  List<int> get kindCounts {
    final counts = List<int>.filled(34, 0);
    for (final tile in closedHandTiles) {
      counts[tile.kind]++;
    }
    return counts;
  }

  /// All tiles in the hand (closed + melds), as kinds.
  List<int> get allKinds {
    final kinds = <int>[];
    for (final tile in closedHandTiles) {
      kinds.add(tile.kind);
    }
    for (final meld in melds) {
      for (final tile in meld.tiles) {
        kinds.add(tile.kind);
      }
    }
    return kinds;
  }

  /// All tiles in the hand (closed + melds).
  List<Tile> get allTiles {
    final tiles = <Tile>[...closedHandTiles];
    for (final meld in melds) {
      tiles.addAll(meld.tiles);
    }
    return tiles;
  }

  /// Count of red dora tiles in the complete hand.
  int get redDoraCount => allTiles.where((t) => t.isRedDora).length;
}
