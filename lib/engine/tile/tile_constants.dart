import 'tile_type.dart';

class TileConstants {
  TileConstants._();

  static const int totalTiles = 136;
  static const int uniqueKinds = 34;

  /// IDs of the three red dora tiles (copyIndex 0 of each 5-tile).
  static const Set<int> redDoraIds = {16, 52, 88}; // 5m, 5p, 5s

  /// Kind indices for the three 5-tiles that have red dora variants.
  static const Set<int> redDoraKinds = {4, 13, 22};

  // Kind ranges by type
  static const int manStart = 0; // kinds 0-8
  static const int pinStart = 9; // kinds 9-17
  static const int souStart = 18; // kinds 18-26
  static const int windStart = 27; // kinds 27-30
  static const int dragonStart = 31; // kinds 31-33

  /// The 13 terminal+honor kinds used for kokushi.
  static const List<int> kokushiKinds = [
    0, 8, // 1m, 9m
    9, 17, // 1p, 9p
    18, 26, // 1s, 9s
    27, 28, 29, 30, // E, S, W, N
    31, 32, 33, // Haku, Hatsu, Chun
  ];

  /// Green tiles for ryuuiisou: 2s, 3s, 4s, 6s, 8s, hatsu.
  static const List<int> greenKinds = [19, 20, 21, 23, 25, 32];

  static TileType typeOf(int kind) {
    if (kind < 9) return TileType.man;
    if (kind < 18) return TileType.pin;
    if (kind < 27) return TileType.sou;
    if (kind < 31) return TileType.wind;
    return TileType.dragon;
  }

  /// Face number: 1-9 for suited, 1-4 for winds, 1-3 for dragons.
  static int numberOf(int kind) {
    if (kind < 27) return (kind % 9) + 1;
    if (kind < 31) return kind - 26; // 1-4
    return kind - 30; // 1-3
  }

  static bool isTerminal(int kind) {
    if (kind >= 27) return false;
    final n = kind % 9;
    return n == 0 || n == 8;
  }

  static bool isHonor(int kind) => kind >= 27;

  static bool isTerminalOrHonor(int kind) => isTerminal(kind) || isHonor(kind);

  static bool isSuited(int kind) => kind < 27;

  /// Returns the suit index (0=man, 1=pin, 2=sou) for a suited tile kind.
  static int suitOf(int kind) {
    assert(kind < 27, 'suitOf called on honor tile');
    return kind ~/ 9;
  }

  /// Given a dora indicator kind, returns the actual dora kind.
  /// Suited: next number (9 wraps to 1 of same suit).
  /// Winds: E→S→W→N→E.
  /// Dragons: Haku→Hatsu→Chun→Haku.
  static int doraFromIndicator(int indicatorKind) {
    if (indicatorKind < 27) {
      // Suited tile
      final suit = indicatorKind ~/ 9;
      final num = indicatorKind % 9;
      return suit * 9 + (num + 1) % 9;
    } else if (indicatorKind < 31) {
      // Wind: 27-30
      return 27 + (indicatorKind - 27 + 1) % 4;
    } else {
      // Dragon: 31-33
      return 31 + (indicatorKind - 31 + 1) % 3;
    }
  }

  /// Wind name for seat/round wind index (0=East, 1=South, 2=West, 3=North).
  static String windName(int windIndex) {
    return const ['East', 'South', 'West', 'North'][windIndex];
  }

  /// Kind index for a wind by wind index (0=East → kind 27, etc.).
  static int windKind(int windIndex) => 27 + windIndex;

  /// Dragon kind by dragon index (0=Haku → kind 31, etc.).
  static int dragonKind(int dragonIndex) => 31 + dragonIndex;
}
