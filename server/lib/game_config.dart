/// Game configuration for different mahjong variants (server copy).
///
/// Tile counts and their corresponding variants:
/// - 108: Sichuan mahjong (number tiles only, no chi, 缺一门)
/// - 136: Riichi (with dora) or Guobiao (no dora)
/// - 144: Guobiao with flowers, or Shanghai (with 百搭)
/// - 152: Suzhou mahjong (16 flowers)
class GameConfig {
  final int tileCount;
  final bool isRiichi;
  final bool hasBaida; // Shanghai 百搭 wild card
  final int startingPoints;

  // Riichi sub-mode: 'free' | 'auto' | 'custom'
  final String riichiMode;

  // Custom mode toggles (only relevant when riichiMode == 'custom')
  final bool noKanDora;
  final bool noAkaDora;
  final bool noUraDora;
  final bool noIppatsu;

  // AI player seats (index 0 = host, always false)
  final List<bool> aiSeats;

  const GameConfig({
    this.tileCount = 136,
    this.isRiichi = true,
    this.hasBaida = false,
    this.startingPoints = 25000,
    this.riichiMode = 'free',
    this.noKanDora = false,
    this.noAkaDora = false,
    this.noUraDora = false,
    this.noIppatsu = false,
    this.aiSeats = const [false, false, false, false],
  });

  /// Whether this is Sichuan mahjong (108 tiles, 缺一门, no chi).
  bool get isSichuan => tileCount == 108;

  /// Whether this is Shanghai mahjong (144 tiles + 百搭).
  bool get isShanghai => tileCount == 144 && hasBaida;

  /// Whether this variant includes flower tiles (144).
  bool get hasFlowers => tileCount >= 144;

  /// Whether dora mechanics are enabled (Riichi 136 only).
  bool get hasDora => isRiichi && tileCount == 136;

  /// Whether a dead wall is used (Riichi only).
  bool get hasDeadWall => hasDora;

  /// Number of dead wall tiles.
  int get deadWallSize => hasDeadWall ? 14 : 0;

  /// Generate the list of all tile IDs for this variant.
  List<int> generateTileIds() {
    switch (tileCount) {
      case 108:
        return List.generate(108, (i) => i);
      case 136:
        return List.generate(136, (i) => i);
      case 144:
        return List.generate(144, (i) => i);
      case 152:
        return List.generate(152, (i) => i);
      default:
        return List.generate(136, (i) => i);
    }
  }

  /// Whether this is Suzhou mahjong (152 tiles, no chi, 百搭).
  bool get isSuzhou => tileCount == 152;

  /// Whether Riichi auto mode is active.
  bool get isAutoMode => isRiichi && riichiMode == 'auto';

  /// Whether Riichi custom mode is active.
  bool get isCustomMode => isRiichi && riichiMode == 'custom';

  /// Whether any AI players are configured.
  bool get hasAiPlayers => aiSeats.any((a) => a);

  /// Check if a tile ID represents a flower in this config.
  /// In Suzhou, 百搭 tiles (144-147) stay in hand as wild cards.
  bool isFlowerTile(int tileId) {
    if (tileCount == 152) {
      return (tileId >= 136 && tileId < 144) || tileId >= 148;
    }
    return tileId >= 136;
  }

  /// Default starting points for each variant.
  static int defaultPoints(int tileCount, bool isRiichi) {
    if (tileCount == 136 && isRiichi) return 25000;
    return 0;
  }

  Map<String, dynamic> toJson() => {
        'tileCount': tileCount,
        'isRiichi': isRiichi,
        'hasBaida': hasBaida,
        'startingPoints': startingPoints,
        'riichiMode': riichiMode,
        'noKanDora': noKanDora,
        'noAkaDora': noAkaDora,
        'noUraDora': noUraDora,
        'noIppatsu': noIppatsu,
        'aiSeats': aiSeats,
      };

  factory GameConfig.fromJson(Map<String, dynamic> json) {
    return GameConfig(
      tileCount: json['tileCount'] as int? ?? 136,
      isRiichi: json['isRiichi'] as bool? ?? true,
      hasBaida: json['hasBaida'] as bool? ?? false,
      startingPoints: json['startingPoints'] as int? ?? 25000,
      riichiMode: json['riichiMode'] as String? ?? 'free',
      noKanDora: json['noKanDora'] as bool? ?? false,
      noAkaDora: json['noAkaDora'] as bool? ?? false,
      noUraDora: json['noUraDora'] as bool? ?? false,
      noIppatsu: json['noIppatsu'] as bool? ?? false,
      aiSeats: (json['aiSeats'] as List<dynamic>?)
              ?.map((e) => e as bool)
              .toList() ??
          const [false, false, false, false],
    );
  }
}
