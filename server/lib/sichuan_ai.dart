/// AI brain for Sichuan mahjong.
///
/// Sichuan rules: number tiles only (man/pin/sou, 108 tiles),
/// no chi, must choose a missing suit (缺一门), and discard tiles
/// of that suit first. Win = standard 4 groups + 1 pair with no
/// tiles from the missing suit.
class SichuanAi {
  SichuanAi._();

  /// Choose which suit to discard (缺一门).
  /// Picks the suit with the fewest tiles in hand.
  /// Returns 0=man, 1=pin, 2=sou.
  static int chooseMissingSuit(List<int> handTileIds) {
    final counts = [0, 0, 0]; // man, pin, sou
    for (final id in handTileIds) {
      final suit = _suitOf(id);
      if (suit >= 0 && suit < 3) {
        counts[suit]++;
      }
    }
    // Pick suit with fewest tiles
    int minSuit = 0;
    for (int i = 1; i < 3; i++) {
      if (counts[i] < counts[minSuit]) {
        minSuit = i;
      }
    }
    return minSuit;
  }

  /// Choose which tile to discard.
  /// Priority: missing suit tiles first, then isolated tiles, then least useful.
  static int chooseDiscard(List<int> handTileIds, int missingSuit) {
    // 1. Discard missing suit tiles first
    final missingSuitTiles = handTileIds
        .where((id) => _suitOf(id) == missingSuit)
        .toList();
    if (missingSuitTiles.isNotEmpty) {
      // Among missing suit tiles, discard the most isolated one
      return _mostIsolated(missingSuitTiles, handTileIds);
    }

    // 2. Discard most isolated tile from remaining hand
    final validTiles = handTileIds
        .where((id) => _suitOf(id) != missingSuit)
        .toList();
    return _mostIsolated(validTiles, handTileIds);
  }

  /// Whether the AI should pon (call a triplet) on a discarded tile.
  static bool shouldPon(
      List<int> handTileIds, int discardKind, int missingSuit) {
    // Don't pon tiles from the missing suit
    if (_suitOfKind(discardKind) == missingSuit) return false;

    // Count how many of this kind we have
    final count =
        handTileIds.where((id) => id ~/ 4 == discardKind).length;
    return count >= 2;
  }

  /// Check if the current hand is a winning hand.
  /// Standard form: 4 groups (triplet or sequence) + 1 pair.
  /// All tiles must not be in the missing suit.
  static bool isWinningHand(List<int> handTileIds, int missingSuit) {
    // Must have no missing-suit tiles
    if (handTileIds.any((id) => _suitOf(id) == missingSuit)) {
      return false;
    }

    // Build kind counts
    final counts = <int, int>{};
    for (final id in handTileIds) {
      final kind = id ~/ 4;
      counts[kind] = (counts[kind] ?? 0) + 1;
    }

    return _canWin(counts);
  }

  /// Count han for a Sichuan winning hand.
  /// Basic: 1 han base. Extra han for special patterns:
  /// +1 for all triplets (对对和)
  /// +1 for single suit (清一色)
  /// +1 for self-draw (handled externally)
  static int countHan(List<int> handTileIds, int missingSuit) {
    int han = 1;

    // Check all-triplets (no sequences)
    final counts = <int, int>{};
    for (final id in handTileIds) {
      final kind = id ~/ 4;
      counts[kind] = (counts[kind] ?? 0) + 1;
    }
    // All triplets: every count is 2 (pair) or 3 (triplet)
    final allTriplets = counts.values.every((c) => c == 2 || c == 3);
    if (allTriplets) han++;

    // Check single suit (清一色)
    final suits = handTileIds.map(_suitOf).toSet();
    if (suits.length == 1) han++;

    // Cap at 5
    if (han > 5) han = 5;
    return han;
  }

  // ─── Helpers ──────────────────────────────────────────────

  /// Get suit from tile ID: 0=man, 1=pin, 2=sou.
  static int _suitOf(int tileId) {
    final kind = tileId ~/ 4;
    if (kind < 9) return 0; // man
    if (kind < 18) return 1; // pin
    return 2; // sou
  }

  /// Get suit from kind index.
  static int _suitOfKind(int kind) {
    if (kind < 9) return 0;
    if (kind < 18) return 1;
    return 2;
  }

  /// Pick the most isolated tile (fewest neighbors of same suit).
  static int _mostIsolated(List<int> candidates, List<int> allHand) {
    final kindCounts = <int, int>{};
    for (final id in allHand) {
      final kind = id ~/ 4;
      kindCounts[kind] = (kindCounts[kind] ?? 0) + 1;
    }

    int bestTile = candidates.first;
    int bestScore = 999;

    for (final tile in candidates) {
      final kind = tile ~/ 4;
      int score = 0;
      // Count adjacent kinds (for sequences)
      if (kindCounts.containsKey(kind - 1) &&
          _suitOfKind(kind - 1) == _suitOfKind(kind)) {
        score += kindCounts[kind - 1]!;
      }
      if (kindCounts.containsKey(kind + 1) &&
          _suitOfKind(kind + 1) == _suitOfKind(kind)) {
        score += kindCounts[kind + 1]!;
      }
      // Count same kind (for triplets) — subtract 1 for self
      score += (kindCounts[kind] ?? 1) - 1;

      if (score < bestScore) {
        bestScore = score;
        bestTile = tile;
      }
    }
    return bestTile;
  }

  /// Backtracking win check using kind counts.
  static bool _canWin(Map<int, int> counts) {
    // Try each kind as the pair
    for (final kind in counts.keys.toList()) {
      if (counts[kind]! >= 2) {
        counts[kind] = counts[kind]! - 2;
        if (counts[kind] == 0) counts.remove(kind);
        if (_removeGroups(counts)) {
          // Restore
          counts[kind] = (counts[kind] ?? 0) + 2;
          return true;
        }
        counts[kind] = (counts[kind] ?? 0) + 2;
      }
    }
    return false;
  }

  /// Try to remove all remaining tiles as triplets or sequences.
  static bool _removeGroups(Map<int, int> counts) {
    if (counts.isEmpty) return true;

    // Find the smallest kind with remaining tiles
    final kind = counts.keys.reduce((a, b) => a < b ? a : b);

    // Try triplet
    if (counts[kind]! >= 3) {
      counts[kind] = counts[kind]! - 3;
      if (counts[kind] == 0) counts.remove(kind);
      if (_removeGroups(counts)) {
        counts[kind] = (counts[kind] ?? 0) + 3;
        return true;
      }
      counts[kind] = (counts[kind] ?? 0) + 3;
    }

    // Try sequence (only within same suit)
    if (_suitOfKind(kind) == _suitOfKind(kind + 1) &&
        _suitOfKind(kind) == _suitOfKind(kind + 2) &&
        (counts[kind + 1] ?? 0) >= 1 &&
        (counts[kind + 2] ?? 0) >= 1) {
      counts[kind] = counts[kind]! - 1;
      if (counts[kind] == 0) counts.remove(kind);
      counts[kind + 1] = counts[kind + 1]! - 1;
      if (counts[kind + 1] == 0) counts.remove(kind + 1);
      counts[kind + 2] = counts[kind + 2]! - 1;
      if (counts[kind + 2] == 0) counts.remove(kind + 2);

      if (_removeGroups(counts)) {
        counts[kind] = (counts[kind] ?? 0) + 1;
        counts[kind + 1] = (counts[kind + 1] ?? 0) + 1;
        counts[kind + 2] = (counts[kind + 2] ?? 0) + 1;
        return true;
      }

      counts[kind] = (counts[kind] ?? 0) + 1;
      counts[kind + 1] = (counts[kind + 1] ?? 0) + 1;
      counts[kind + 2] = (counts[kind + 2] ?? 0) + 1;
    }

    return false;
  }
}
