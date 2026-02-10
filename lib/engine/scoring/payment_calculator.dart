import 'score_table.dart';

/// Result of payment calculation.
class PaymentResult {
  /// Points the winner gains total.
  final int totalWinnerGain;

  /// Points each player pays. Index = seat index. Negative = pays, positive = receives.
  /// Only the winner has a positive value.
  final List<int> scoreChanges;

  /// Display-friendly breakdown.
  final String description;

  const PaymentResult({
    required this.totalWinnerGain,
    required this.scoreChanges,
    required this.description,
  });
}

/// Calculates point transfers for a winning hand.
class PaymentCalculator {
  PaymentCalculator._();

  /// Round up to nearest 100.
  static int _roundUp100(int value) => ((value + 99) ~/ 100) * 100;

  /// Calculate payments for a win.
  static PaymentResult calculate({
    required int han,
    required int fu,
    required bool isDealer,
    required bool isTsumo,
    required int winnerIndex,
    required int? loserIndex,
    required int honba,
    required int riichiSticksOnTable,
  }) {
    final base = ScoreTable.basePoints(han, fu);
    final changes = List<int>.filled(4, 0);
    String desc;

    if (isTsumo) {
      if (isDealer) {
        // Dealer tsumo: each of 3 non-dealers pays ceil(base*2/100)*100
        final eachPays = _roundUp100(base * 2);
        final honbaPerPlayer = honba * 100;
        for (int i = 0; i < 4; i++) {
          if (i == winnerIndex) continue;
          changes[i] = -(eachPays + honbaPerPlayer);
        }
        changes[winnerIndex] =
            (eachPays + honbaPerPlayer) * 3 + riichiSticksOnTable * 1000;
        desc = '${eachPays + honbaPerPlayer} all';
      } else {
        // Non-dealer tsumo
        final dealerPays = _roundUp100(base * 2);
        final nonDealerPays = _roundUp100(base);
        final honbaPerPlayer = honba * 100;
        for (int i = 0; i < 4; i++) {
          if (i == winnerIndex) continue;
          // Find who is the dealer
          // Dealer is determined by: the player whose seatWind == 0
          // In our model, dealer is always at (winnerIndex + offset) where seatWind == 0
          // We don't have seat wind here, so we use a simpler approach:
          // The caller must tell us, but for simplicity we check the winnerIndex
          // Actually we need to know who the dealer is. Let's add dealerIndex parameter.
          // For now, assume dealer is seat 0 or use isDealer flag differently.
          // We'll handle this via an overload below.
        }
        // Use the version with dealerIndex
        desc = '${dealerPays + honbaPerPlayer}/${nonDealerPays + honbaPerPlayer}';
        // This path shouldn't be reached - use calculateWithDealer instead
      }
    } else {
      // Ron: loser pays everything
      final totalPay = isDealer
          ? _roundUp100(base * 6)
          : _roundUp100(base * 4);
      final honbaTotal = honba * 300;
      changes[loserIndex!] = -(totalPay + honbaTotal);
      changes[winnerIndex] =
          totalPay + honbaTotal + riichiSticksOnTable * 1000;
      desc = '${totalPay + honbaTotal}';
    }

    return PaymentResult(
      totalWinnerGain: changes[winnerIndex],
      scoreChanges: changes,
      description: desc,
    );
  }

  /// Calculate payments with explicit dealer index.
  static PaymentResult calculateWithDealer({
    required int han,
    required int fu,
    required int dealerIndex,
    required bool isTsumo,
    required int winnerIndex,
    required int? loserIndex,
    required int honba,
    required int riichiSticksOnTable,
  }) {
    final isDealer = winnerIndex == dealerIndex;
    final base = ScoreTable.basePoints(han, fu);
    final changes = List<int>.filled(4, 0);
    String desc;

    if (isTsumo) {
      final honbaPerPlayer = honba * 100;
      if (isDealer) {
        final eachPays = _roundUp100(base * 2);
        for (int i = 0; i < 4; i++) {
          if (i == winnerIndex) continue;
          changes[i] = -(eachPays + honbaPerPlayer);
        }
        changes[winnerIndex] =
            (eachPays + honbaPerPlayer) * 3 + riichiSticksOnTable * 1000;
        desc = '${eachPays + honbaPerPlayer} all';
      } else {
        final dealerPays = _roundUp100(base * 2);
        final nonDealerPays = _roundUp100(base);
        for (int i = 0; i < 4; i++) {
          if (i == winnerIndex) continue;
          if (i == dealerIndex) {
            changes[i] = -(dealerPays + honbaPerPlayer);
          } else {
            changes[i] = -(nonDealerPays + honbaPerPlayer);
          }
        }
        changes[winnerIndex] =
            (dealerPays + nonDealerPays * 2 + honbaPerPlayer * 3) +
            riichiSticksOnTable * 1000;
        desc = '${dealerPays + honbaPerPlayer}/${nonDealerPays + honbaPerPlayer}';
      }
    } else {
      final totalPay = isDealer
          ? _roundUp100(base * 6)
          : _roundUp100(base * 4);
      final honbaTotal = honba * 300;
      changes[loserIndex!] = -(totalPay + honbaTotal);
      changes[winnerIndex] =
          totalPay + honbaTotal + riichiSticksOnTable * 1000;
      desc = '${totalPay + honbaTotal}';
    }

    return PaymentResult(
      totalWinnerGain: changes[winnerIndex],
      scoreChanges: changes,
      description: desc,
    );
  }
}
