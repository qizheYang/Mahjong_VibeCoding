import 'win_detector.dart';

/// Determines tenpai status and waiting tiles.
class TenpaiDetector {
  TenpaiDetector._();

  /// Returns the set of tile kinds that would complete the hand.
  /// Empty set means the hand is not tenpai.
  ///
  /// [kindCounts]: 34-element array of closed hand tile counts.
  /// [meldCount]: number of declared melds.
  static Set<int> findWaits(List<int> kindCounts, int meldCount) {
    final waits = <int>{};
    for (int k = 0; k < 34; k++) {
      if (kindCounts[k] >= 4) continue; // can't add a 5th tile
      kindCounts[k]++;
      if (WinDetector.isWinning(kindCounts, meldCount)) {
        waits.add(k);
      }
      kindCounts[k]--;
    }
    return waits;
  }

  /// Check if a hand is tenpai (has at least one waiting tile).
  static bool isTenpai(List<int> kindCounts, int meldCount) {
    return findWaits(kindCounts, meldCount).isNotEmpty;
  }
}
