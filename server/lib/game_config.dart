/// Game configuration for different mahjong variants (server copy).
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

  bool get hasFlowers => tileCount >= 144;
  bool get hasDora => isRiichi && tileCount == 136;
  bool get dragonsAreFlowers => tileCount == 152;
  bool get hasDeadWall => tileCount >= 136;
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

  /// Check if a tile ID represents a flower in this config.
  bool isFlowerTile(int tileId) {
    if (tileId >= 136) return true;
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
