import '../state/action.dart';

/// Resolves priority when multiple players can call on a discard.
/// Priority: Ron > Pon/Kan > Chi.
class CallResolver {
  CallResolver._();

  /// Given pending actions from multiple players, determine which takes priority.
  /// Returns null if everyone skipped.
  static PlayerAction? resolve(Map<int, PlayerAction> responses) {
    // Check for ron first (can have multiple ron — sanchahou)
    final ronActions = responses.entries
        .where((e) => e.value is RonAction)
        .map((e) => e.value)
        .toList();

    if (ronActions.length >= 3) {
      // Triple ron = abortive draw (sanchahou)
      return AbortAction(0, AbortReason.sanchaHou);
    }
    if (ronActions.isNotEmpty) {
      return ronActions.first; // ron takes priority
    }

    // Pon/Kan over Chi
    for (final entry in responses.entries) {
      if (entry.value is PonAction || entry.value is OpenKanAction) {
        return entry.value;
      }
    }

    // Chi
    for (final entry in responses.entries) {
      if (entry.value is ChiAction) {
        return entry.value;
      }
    }

    return null; // all skipped
  }
}
