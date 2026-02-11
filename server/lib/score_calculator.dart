/// Simple score calculator for win declarations.
/// Computes payments from han + fu, following standard riichi mahjong rules.
class ScoreCalculator {
  ScoreCalculator._();

  static int basePoints(int han, int fu) {
    if (han >= 13) return 8000; // yakuman
    if (han >= 11) return 6000; // sanbaiman
    if (han >= 8) return 4000; // baiman
    if (han >= 6) return 3000; // haneman
    if (han >= 5) return 2000; // mangan
    final base = fu * (1 << (han + 2));
    if (base >= 2000) return 2000; // kiriage mangan
    return base;
  }

  static String tierName(int han, int fu) {
    if (han >= 13) return '役满';
    if (han >= 11) return '三倍满';
    if (han >= 8) return '倍满';
    if (han >= 6) return '跳满';
    if (han >= 5) return '满贯';
    final base = fu * (1 << (han + 2));
    if (base >= 2000) return '满贯';
    return '$han番$fu符';
  }

  /// Calculate payment amounts for each seat.
  /// Returns a map of seat index to point delta. Positive = gains, negative = pays.
  static Map<int, int> calculatePayments({
    required int han,
    required int fu,
    required int winnerSeat,
    required int dealerSeat,
    required bool isTsumo,
    required int? loserSeat,
    required int honbaCount,
    required int riichiSticks,
  }) {
    final base = basePoints(han, fu);
    final isDealer = winnerSeat == dealerSeat;
    final payments = <int, int>{};

    if (isTsumo) {
      if (isDealer) {
        // Dealer tsumo: each other pays ceil(base*2/100)*100
        final each = _roundUp100(base * 2);
        for (int i = 0; i < 4; i++) {
          if (i == winnerSeat) {
            payments[i] =
                each * 3 + honbaCount * 300 + riichiSticks * 1000;
          } else {
            payments[i] = -(each + honbaCount * 100);
          }
        }
      } else {
        // Non-dealer tsumo
        final dealerPays = _roundUp100(base * 2);
        final otherPays = _roundUp100(base);
        for (int i = 0; i < 4; i++) {
          if (i == winnerSeat) {
            payments[i] = dealerPays +
                otherPays * 2 +
                honbaCount * 300 +
                riichiSticks * 1000;
          } else if (i == dealerSeat) {
            payments[i] = -(dealerPays + honbaCount * 100);
          } else {
            payments[i] = -(otherPays + honbaCount * 100);
          }
        }
      }
    } else {
      // Ron
      final total =
          isDealer ? _roundUp100(base * 6) : _roundUp100(base * 4);
      for (int i = 0; i < 4; i++) {
        if (i == winnerSeat) {
          payments[i] = total + honbaCount * 300 + riichiSticks * 1000;
        } else if (i == loserSeat) {
          payments[i] = -(total + honbaCount * 300);
        } else {
          payments[i] = 0;
        }
      }
    }

    return payments;
  }

  static int _roundUp100(int n) => ((n + 99) ~/ 100) * 100;

  /// Sichuan scoring: 2^han per player.
  /// Tsumo: each of the 3 other players pays 2^han to winner.
  /// Ron: loser pays 2^han to winner.
  static Map<int, int> sichuanPayments({
    required int han,
    required bool isTsumo,
    required int winnerSeat,
    required int? loserSeat,
  }) {
    final perPlayer = 1 << han; // 2^han
    final payments = <int, int>{};

    if (isTsumo) {
      for (int i = 0; i < 4; i++) {
        if (i == winnerSeat) {
          payments[i] = perPlayer * 3;
        } else {
          payments[i] = -perPlayer;
        }
      }
    } else {
      for (int i = 0; i < 4; i++) {
        if (i == winnerSeat) {
          payments[i] = perPlayer;
        } else if (i == loserSeat) {
          payments[i] = -perPlayer;
        } else {
          payments[i] = 0;
        }
      }
    }
    return payments;
  }

  /// Direct point entry (Guobiao, Shanghai, Suzhou, etc.).
  /// Tsumo: each of the 3 other players pays perPlayer to winner.
  /// Ron: loser pays perPlayer to winner.
  static Map<int, int> directPayments({
    required int perPlayer,
    required bool isTsumo,
    required int winnerSeat,
    required int? loserSeat,
  }) {
    final payments = <int, int>{};

    if (isTsumo) {
      for (int i = 0; i < 4; i++) {
        if (i == winnerSeat) {
          payments[i] = perPlayer * 3;
        } else {
          payments[i] = -perPlayer;
        }
      }
    } else {
      for (int i = 0; i < 4; i++) {
        if (i == winnerSeat) {
          payments[i] = perPlayer;
        } else if (i == loserSeat) {
          payments[i] = -perPlayer;
        } else {
          payments[i] = 0;
        }
      }
    }
    return payments;
  }
}
