/// Lookup table for han + fu → base points.
class ScoreTable {
  ScoreTable._();

  /// Calculate base points from han and fu.
  ///
  /// Returns the base points before multiplying for dealer/non-dealer and tsumo/ron.
  static int basePoints(int han, int fu) {
    // Yakuman
    if (han >= 13) return 8000;
    // Sanbaiman
    if (han >= 11) return 6000;
    // Baiman
    if (han >= 8) return 4000;
    // Haneman
    if (han >= 6) return 3000;
    // Mangan (including kiriage mangan: 4han30fu, 3han60fu)
    if (han >= 5) return 2000;
    if (han == 4 && fu >= 30) return 2000;
    if (han == 3 && fu >= 60) return 2000;

    // Standard calculation: fu * 2^(han+2)
    final base = fu * (1 << (han + 2));
    // Cap at mangan
    if (base >= 2000) return 2000;
    return base;
  }

  /// Check if the hand is mangan or above.
  static bool isMangan(int han, int fu) {
    if (han >= 5) return true;
    if (han == 4 && fu >= 30) return true;
    if (han == 3 && fu >= 60) return true;
    return false;
  }

  /// Get the scoring tier name.
  static String tierName(int han, int fu) {
    if (han >= 13) return 'Yakuman';
    if (han >= 11) return 'Sanbaiman';
    if (han >= 8) return 'Baiman';
    if (han >= 6) return 'Haneman';
    if (han >= 5 || isMangan(han, fu)) return 'Mangan';
    return '$han Han $fu Fu';
  }
}
