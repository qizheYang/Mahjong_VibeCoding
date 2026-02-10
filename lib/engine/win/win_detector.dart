import '../tile/tile_constants.dart';

/// Determines if a set of tiles forms a complete (winning) hand.
class WinDetector {
  WinDetector._();

  /// Check if the given kind counts form a winning hand.
  ///
  /// [kindCounts]: 34-element array of tile counts in the closed hand.
  /// [meldCount]: number of already-declared melds.
  ///
  /// Returns true if the hand can be decomposed into (4 - meldCount) mentsu + 1 pair,
  /// or is chiitoitsu (7 pairs) or kokushi musou (13 orphans).
  static bool isWinning(List<int> kindCounts, int meldCount) {
    final targetSets = 4 - meldCount;
    final totalTiles = kindCounts.fold(0, (a, b) => a + b);

    // Should have exactly (targetSets * 3 + 2) tiles in closed hand
    if (totalTiles != targetSets * 3 + 2) return false;

    // Check standard form
    if (_isStandardWin(kindCounts, targetSets)) return true;

    // Check chiitoitsu (only if no melds declared)
    if (meldCount == 0 && _isChiitoitsu(kindCounts)) return true;

    // Check kokushi musou (only if no melds declared)
    if (meldCount == 0 && _isKokushi(kindCounts)) return true;

    return false;
  }

  /// Check standard form: targetSets mentsu + 1 pair.
  static bool _isStandardWin(List<int> kindCounts, int targetSets) {
    return _backtrackCheck(List.from(kindCounts), targetSets, false);
  }

  /// Fast backtracking check (just returns bool, doesn't enumerate all partitions).
  static bool _backtrackCheck(List<int> counts, int setsNeeded, bool hasPair) {
    if (setsNeeded == 0 && hasPair) {
      return counts.every((c) => c == 0);
    }

    int firstKind = -1;
    for (int k = 0; k < 34; k++) {
      if (counts[k] > 0) {
        firstKind = k;
        break;
      }
    }
    if (firstKind == -1) return false;

    // Try pair
    if (!hasPair && counts[firstKind] >= 2) {
      counts[firstKind] -= 2;
      if (_backtrackCheck(counts, setsNeeded, true)) {
        counts[firstKind] += 2;
        return true;
      }
      counts[firstKind] += 2;
    }

    // Try koutsu
    if (setsNeeded > 0 && counts[firstKind] >= 3) {
      counts[firstKind] -= 3;
      if (_backtrackCheck(counts, setsNeeded - 1, hasPair)) {
        counts[firstKind] += 3;
        return true;
      }
      counts[firstKind] += 3;
    }

    // Try shuntsu
    if (setsNeeded > 0 &&
        TileConstants.isSuited(firstKind) &&
        TileConstants.numberOf(firstKind) <= 7) {
      final k2 = firstKind + 1;
      final k3 = firstKind + 2;
      if (TileConstants.suitOf(firstKind) == TileConstants.suitOf(k3) &&
          counts[firstKind] >= 1 &&
          counts[k2] >= 1 &&
          counts[k3] >= 1) {
        counts[firstKind]--;
        counts[k2]--;
        counts[k3]--;
        if (_backtrackCheck(counts, setsNeeded - 1, hasPair)) {
          counts[firstKind]++;
          counts[k2]++;
          counts[k3]++;
          return true;
        }
        counts[firstKind]++;
        counts[k2]++;
        counts[k3]++;
      }
    }

    return false;
  }

  /// Chiitoitsu: exactly 7 distinct pairs (no quads count as two pairs).
  static bool _isChiitoitsu(List<int> kindCounts) {
    int pairs = 0;
    for (int k = 0; k < 34; k++) {
      if (kindCounts[k] == 2) {
        pairs++;
      } else if (kindCounts[k] != 0) {
        return false;
      }
    }
    return pairs == 7;
  }

  /// Kokushi musou: one of each 13 terminal/honor + one duplicate.
  static bool _isKokushi(List<int> kindCounts) {
    bool hasDuplicate = false;
    for (final k in TileConstants.kokushiKinds) {
      if (kindCounts[k] == 0) return false;
      if (kindCounts[k] == 2) {
        if (hasDuplicate) return false;
        hasDuplicate = true;
      } else if (kindCounts[k] != 1) {
        return false;
      }
    }
    // Verify no other tiles
    for (int k = 0; k < 34; k++) {
      if (!TileConstants.kokushiKinds.contains(k) && kindCounts[k] != 0) {
        return false;
      }
    }
    return hasDuplicate;
  }

  /// Check if the hand is chiitoitsu.
  static bool isChiitoitsu(List<int> kindCounts) => _isChiitoitsu(kindCounts);

  /// Check if the hand is kokushi musou.
  static bool isKokushi(List<int> kindCounts) => _isKokushi(kindCounts);
}
