import '../tile/tile_constants.dart';

/// Calculates the shanten number for a hand.
///
/// Shanten = minimum number of tiles needed to reach tenpai.
///   -1 = complete (winning) hand
///    0 = tenpai (one tile away from winning)
///    1 = iishanten (two tiles away)
///   etc.
class ShantenCalculator {
  ShantenCalculator._();

  /// Calculate the shanten number for a hand.
  ///
  /// [kindCounts]: 34-element array of tile counts in the closed hand.
  /// [meldCount]: number of declared melds.
  static int calculate(List<int> kindCounts, int meldCount) {
    final standard = _standardShanten(List.from(kindCounts), meldCount);
    int best = standard;

    if (meldCount == 0) {
      final chiitoi = _chiitoitsuShanten(kindCounts);
      if (chiitoi < best) best = chiitoi;

      final kokushi = _kokushiShanten(kindCounts);
      if (kokushi < best) best = kokushi;
    }

    return best;
  }

  /// Standard form shanten using recursive mentsu decomposition.
  static int _standardShanten(List<int> counts, int meldCount) {
    final targetSets = 4 - meldCount;
    // Start with worst case: need all sets and pair
    // shanten = targetSets * 2 - (mentsu + partial + hasPair)
    // where max shanten = 8 (for 0 melds)
    int bestShanten = targetSets * 2; // worst case (no pair)
    _scanStandard(counts, targetSets, 0, 0, 0, false, bestShanten, (s) {
      if (s < bestShanten) bestShanten = s;
    });
    return bestShanten;
  }

  static void _scanStandard(
    List<int> counts,
    int targetSets,
    int mentsuCount,
    int partialCount,
    int startKind,
    bool hasPair,
    int currentBest,
    void Function(int) onResult,
  ) {
    // Calculate shanten for current state
    final shanten =
        (targetSets - mentsuCount) * 2 - partialCount - (hasPair ? 1 : 0);
    if (shanten < currentBest) {
      onResult(shanten);
      currentBest = shanten;
    }

    // Pruning: can't possibly improve
    final maxGainable = (targetSets - mentsuCount) * 2 + (hasPair ? 0 : 1);
    if (shanten - maxGainable >= currentBest) return;

    for (int k = startKind; k < 34; k++) {
      if (counts[k] == 0) continue;

      // Try pair (as the jantai)
      if (!hasPair && counts[k] >= 2) {
        counts[k] -= 2;
        _scanStandard(
          counts, targetSets, mentsuCount, partialCount, k,
          true, currentBest, onResult,
        );
        counts[k] += 2;
      }

      // Complete mentsu
      if (mentsuCount < targetSets) {
        // Koutsu (triplet)
        if (counts[k] >= 3) {
          counts[k] -= 3;
          _scanStandard(
            counts, targetSets, mentsuCount + 1, partialCount, k,
            hasPair, currentBest, onResult,
          );
          counts[k] += 3;
        }

        // Shuntsu (sequence)
        if (TileConstants.isSuited(k) && TileConstants.numberOf(k) <= 7) {
          final k2 = k + 1;
          final k3 = k + 2;
          if (TileConstants.suitOf(k) == TileConstants.suitOf(k3) &&
              counts[k2] >= 1 && counts[k3] >= 1) {
            counts[k]--;
            counts[k2]--;
            counts[k3]--;
            _scanStandard(
              counts, targetSets, mentsuCount + 1, partialCount, k,
              hasPair, currentBest, onResult,
            );
            counts[k]++;
            counts[k2]++;
            counts[k3]++;
          }
        }
      }

      // Partial mentsu (for shanten counting)
      if (mentsuCount + partialCount < targetSets) {
        // Pair as partial koutsu
        if (counts[k] >= 2) {
          counts[k] -= 2;
          _scanStandard(
            counts, targetSets, mentsuCount, partialCount + 1, k,
            hasPair, currentBest, onResult,
          );
          counts[k] += 2;
        }

        // Adjacent pair for partial shuntsu
        if (TileConstants.isSuited(k) && TileConstants.numberOf(k) <= 8) {
          final k2 = k + 1;
          if (TileConstants.suitOf(k) == TileConstants.suitOf(k2) &&
              counts[k2] >= 1) {
            counts[k]--;
            counts[k2]--;
            _scanStandard(
              counts, targetSets, mentsuCount, partialCount + 1, k,
              hasPair, currentBest, onResult,
            );
            counts[k]++;
            counts[k2]++;
          }
        }

        // Gap pair for partial shuntsu (e.g., 1-3)
        if (TileConstants.isSuited(k) && TileConstants.numberOf(k) <= 7) {
          final k3 = k + 2;
          if (TileConstants.suitOf(k) == TileConstants.suitOf(k3) &&
              counts[k3] >= 1) {
            counts[k]--;
            counts[k3]--;
            _scanStandard(
              counts, targetSets, mentsuCount, partialCount + 1, k,
              hasPair, currentBest, onResult,
            );
            counts[k]++;
            counts[k3]++;
          }
        }
      }
    }
  }

  /// Chiitoitsu shanten: 6 - (number of pairs).
  static int _chiitoitsuShanten(List<int> kindCounts) {
    int pairs = 0;
    for (int k = 0; k < 34; k++) {
      if (kindCounts[k] >= 2) pairs++;
    }
    return 6 - pairs;
  }

  /// Kokushi shanten: 13 - (unique terminal/honors present) - (has duplicate ? 1 : 0).
  static int _kokushiShanten(List<int> kindCounts) {
    int unique = 0;
    bool hasPair = false;
    for (final k in TileConstants.kokushiKinds) {
      if (kindCounts[k] >= 1) {
        unique++;
        if (kindCounts[k] >= 2) hasPair = true;
      }
    }
    return 13 - unique - (hasPair ? 1 : 0);
  }
}
