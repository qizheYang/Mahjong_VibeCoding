/// Game configuration for different mahjong variants.
///
/// Tile counts and their corresponding variants:
/// - 108: Sichuan mahjong (number tiles only, no dora)
/// - 136: Riichi (with dora) or Guobiao (no dora)
/// - 144: Guobiao with flowers (春夏秋冬梅兰竹菊)
/// - 152: Suzhou/Shanghai (flowers + extra flowers, 中发白 are flowers)
class GameConfig {
  final int tileCount;
  final bool isRiichi;
  final int startingPoints;

  const GameConfig({
    this.tileCount = 136,
    this.isRiichi = true,
    this.startingPoints = 25000,
  });

  /// Whether this is Sichuan mahjong (108 tiles, 缺一门).
  bool get isSichuan => tileCount == 108;

  /// Whether this variant includes flower tiles (144, 152).
  bool get hasFlowers => tileCount >= 144;

  /// Whether dora mechanics are enabled (Riichi 136 only).
  bool get hasDora => isRiichi && tileCount == 136;

  /// Whether 中发白 are treated as flowers (152 mode).
  bool get dragonsAreFlowers => tileCount == 152;

  /// Whether a dead wall is used.
  bool get hasDeadWall => tileCount >= 136;

  /// Number of dead wall tiles.
  int get deadWallSize => hasDeadWall ? 14 : 0;

  /// Variant display name key for i18n.
  String get variantKey {
    switch (tileCount) {
      case 108:
        return 'sichuan';
      case 136:
        return isRiichi ? 'riichi' : 'guobiao';
      case 144:
        return 'guobiaoFlowers';
      case 152:
        return 'suzhouShanghai';
      default:
        return 'riichi';
    }
  }

  /// Default starting points for each variant.
  static int defaultPoints(int tileCount, bool isRiichi) {
    if (tileCount == 136 && isRiichi) return 25000;
    return 0;
  }

  /// Generate the list of all tile IDs for this variant.
  List<int> generateTileIds() {
    switch (tileCount) {
      case 108:
        // Sichuan: only man (0-35), pin (36-71), sou (72-107)
        return List.generate(108, (i) => i);
      case 136:
        return List.generate(136, (i) => i);
      case 144:
        // Standard 136 + 8 flowers (136-143)
        return List.generate(144, (i) => i);
      case 152:
        // Standard 136 + 16 flowers (136-151)
        return List.generate(152, (i) => i);
      default:
        return List.generate(136, (i) => i);
    }
  }

  /// Check if a tile ID represents a flower in this config.
  bool isFlowerTile(int tileId) {
    if (tileId >= 136) return true;
    // In 152 mode, 中发白 (kinds 31-33, IDs 124-135) are also flowers
    if (dragonsAreFlowers && tileId >= 124) return true;
    return false;
  }

  Map<String, dynamic> toJson() => {
        'tileCount': tileCount,
        'isRiichi': isRiichi,
        'startingPoints': startingPoints,
      };

  factory GameConfig.fromJson(Map<String, dynamic> json) {
    return GameConfig(
      tileCount: json['tileCount'] as int? ?? 136,
      isRiichi: json['isRiichi'] as bool? ?? true,
      startingPoints: json['startingPoints'] as int? ?? 25000,
    );
  }
}
