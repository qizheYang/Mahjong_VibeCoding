import '../tile/tile.dart';
import '../tile/tile_sort.dart';
import 'meld.dart';

class PlayerState {
  final int seatIndex;
  final List<Tile> hand; // closed hand (13 tiles, or 14 after drawing)
  final List<Meld> melds;
  final List<Tile> discards;
  final bool isRiichi;
  final bool isDoubleRiichi;
  final int? riichiDiscardIndex; // index in discards where riichi was declared
  final bool isIppatsuEligible;
  final Tile? justDrew; // the 14th tile just drawn (null if not this player's turn)
  final int seatWind; // 0=East, 1=South, 2=West, 3=North
  final bool hasDeclinedRon; // for temporary furiten tracking

  const PlayerState({
    required this.seatIndex,
    this.hand = const [],
    this.melds = const [],
    this.discards = const [],
    this.isRiichi = false,
    this.isDoubleRiichi = false,
    this.riichiDiscardIndex,
    this.isIppatsuEligible = false,
    this.justDrew,
    required this.seatWind,
    this.hasDeclinedRon = false,
  });

  /// Whether this player has no open melds (closed kan is okay).
  bool get isMenzen => melds.every((m) => !m.isOpen);

  /// Total number of tiles accounted for (hand + melds).
  int get totalTiles => hand.length + melds.fold(0, (s, m) => s + m.tileCount);

  /// Sorted hand for display.
  List<Tile> get sortedHand => TileSort.sort(hand);

  /// Build a 34-element array of kind counts from the closed hand.
  List<int> get kindCounts {
    final counts = List<int>.filled(34, 0);
    for (final tile in hand) {
      counts[tile.kind]++;
    }
    return counts;
  }

  PlayerState copyWith({
    int? seatIndex,
    List<Tile>? hand,
    List<Meld>? melds,
    List<Tile>? discards,
    bool? isRiichi,
    bool? isDoubleRiichi,
    int? Function()? riichiDiscardIndex,
    bool? isIppatsuEligible,
    Tile? Function()? justDrew,
    int? seatWind,
    bool? hasDeclinedRon,
  }) {
    return PlayerState(
      seatIndex: seatIndex ?? this.seatIndex,
      hand: hand ?? this.hand,
      melds: melds ?? this.melds,
      discards: discards ?? this.discards,
      isRiichi: isRiichi ?? this.isRiichi,
      isDoubleRiichi: isDoubleRiichi ?? this.isDoubleRiichi,
      riichiDiscardIndex: riichiDiscardIndex != null
          ? riichiDiscardIndex()
          : this.riichiDiscardIndex,
      isIppatsuEligible: isIppatsuEligible ?? this.isIppatsuEligible,
      justDrew: justDrew != null ? justDrew() : this.justDrew,
      seatWind: seatWind ?? this.seatWind,
      hasDeclinedRon: hasDeclinedRon ?? this.hasDeclinedRon,
    );
  }
}
