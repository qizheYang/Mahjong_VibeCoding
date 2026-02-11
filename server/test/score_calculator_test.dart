import 'package:test/test.dart';
import 'package:mahjong_server/score_calculator.dart';

void main() {
  group('ScoreCalculator.basePoints', () {
    test('yakuman (13+ han)', () {
      expect(ScoreCalculator.basePoints(13, 30), 8000);
      expect(ScoreCalculator.basePoints(26, 30), 8000);
    });

    test('sanbaiman (11-12 han)', () {
      expect(ScoreCalculator.basePoints(11, 30), 6000);
      expect(ScoreCalculator.basePoints(12, 30), 6000);
    });

    test('baiman (8-10 han)', () {
      expect(ScoreCalculator.basePoints(8, 30), 4000);
      expect(ScoreCalculator.basePoints(10, 30), 4000);
    });

    test('haneman (6-7 han)', () {
      expect(ScoreCalculator.basePoints(6, 30), 3000);
      expect(ScoreCalculator.basePoints(7, 30), 3000);
    });

    test('mangan (5 han)', () {
      expect(ScoreCalculator.basePoints(5, 30), 2000);
    });

    test('standard calculation (< 5 han)', () {
      // 1 han 30 fu = 30 * 2^3 = 240
      expect(ScoreCalculator.basePoints(1, 30), 240);
      // 2 han 30 fu = 30 * 2^4 = 480
      expect(ScoreCalculator.basePoints(2, 30), 480);
      // 3 han 30 fu = 30 * 2^5 = 960
      expect(ScoreCalculator.basePoints(3, 30), 960);
      // 4 han 30 fu = 30 * 2^6 = 1920
      expect(ScoreCalculator.basePoints(4, 30), 1920);
    });

    test('kiriage mangan (base >= 2000 rounds up)', () {
      // 4 han 40 fu = 40 * 2^6 = 2560 -> capped at 2000
      expect(ScoreCalculator.basePoints(4, 40), 2000);
      // 3 han 70 fu = 70 * 2^5 = 2240 -> capped at 2000
      expect(ScoreCalculator.basePoints(3, 70), 2000);
    });
  });

  group('ScoreCalculator.tierName', () {
    test('tiers', () {
      expect(ScoreCalculator.tierName(13, 30), '役满');
      expect(ScoreCalculator.tierName(11, 30), '三倍满');
      expect(ScoreCalculator.tierName(8, 30), '倍满');
      expect(ScoreCalculator.tierName(6, 30), '跳满');
      expect(ScoreCalculator.tierName(5, 30), '满贯');
      expect(ScoreCalculator.tierName(1, 30), '1番30符');
    });

    test('kiriage mangan shows 满贯', () {
      expect(ScoreCalculator.tierName(4, 40), '满贯');
    });
  });

  group('ScoreCalculator.calculatePayments', () {
    test('non-dealer ron: payments sum to zero', () {
      final payments = ScoreCalculator.calculatePayments(
        han: 3,
        fu: 30,
        winnerSeat: 1,
        dealerSeat: 0,
        isTsumo: false,
        loserSeat: 2,
        honbaCount: 0,
        riichiSticks: 0,
      );

      final sum = payments.values.fold<int>(0, (a, b) => a + b);
      expect(sum, 0, reason: 'Payments should sum to zero');
      expect(payments[1]! > 0, true, reason: 'Winner gains points');
      expect(payments[2]! < 0, true, reason: 'Loser pays');
      expect(payments[0], 0, reason: 'Uninvolved players pay nothing');
      expect(payments[3], 0);
    });

    test('dealer ron: higher payout', () {
      final payments = ScoreCalculator.calculatePayments(
        han: 3,
        fu: 30,
        winnerSeat: 0,
        dealerSeat: 0,
        isTsumo: false,
        loserSeat: 1,
        honbaCount: 0,
        riichiSticks: 0,
      );

      expect(payments[0]! > 0, true);
      expect(payments[1]! < 0, true);
      final sum = payments.values.fold<int>(0, (a, b) => a + b);
      expect(sum, 0);
    });

    test('dealer tsumo: each other pays equal', () {
      final payments = ScoreCalculator.calculatePayments(
        han: 3,
        fu: 30,
        winnerSeat: 0,
        dealerSeat: 0,
        isTsumo: true,
        loserSeat: null,
        honbaCount: 0,
        riichiSticks: 0,
      );

      // All non-dealers pay the same
      expect(payments[1], payments[2]);
      expect(payments[2], payments[3]);
      expect(payments[1]! < 0, true);
      final sum = payments.values.fold<int>(0, (a, b) => a + b);
      expect(sum, 0);
    });

    test('non-dealer tsumo: dealer pays more', () {
      final payments = ScoreCalculator.calculatePayments(
        han: 3,
        fu: 30,
        winnerSeat: 1,
        dealerSeat: 0,
        isTsumo: true,
        loserSeat: null,
        honbaCount: 0,
        riichiSticks: 0,
      );

      expect(payments[0]!.abs() > payments[2]!.abs(), true,
          reason: 'Dealer pays more than non-dealer');
      final sum = payments.values.fold<int>(0, (a, b) => a + b);
      expect(sum, 0);
    });

    test('honba adds 100 per player for tsumo', () {
      final paymentsNoHonba = ScoreCalculator.calculatePayments(
        han: 3,
        fu: 30,
        winnerSeat: 0,
        dealerSeat: 0,
        isTsumo: true,
        loserSeat: null,
        honbaCount: 0,
        riichiSticks: 0,
      );
      final paymentsWith1Honba = ScoreCalculator.calculatePayments(
        han: 3,
        fu: 30,
        winnerSeat: 0,
        dealerSeat: 0,
        isTsumo: true,
        loserSeat: null,
        honbaCount: 1,
        riichiSticks: 0,
      );

      // Each non-dealer pays 100 more per honba
      expect(paymentsWith1Honba[1]!, paymentsNoHonba[1]! - 100);
      // Winner gains 300 more total (100 * 3)
      expect(paymentsWith1Honba[0]!, paymentsNoHonba[0]! + 300);
    });

    test('riichi sticks go to winner', () {
      final payments = ScoreCalculator.calculatePayments(
        han: 3,
        fu: 30,
        winnerSeat: 0,
        dealerSeat: 0,
        isTsumo: true,
        loserSeat: null,
        honbaCount: 0,
        riichiSticks: 2,
      );

      final paymentsNoRiichi = ScoreCalculator.calculatePayments(
        han: 3,
        fu: 30,
        winnerSeat: 0,
        dealerSeat: 0,
        isTsumo: true,
        loserSeat: null,
        honbaCount: 0,
        riichiSticks: 0,
      );

      expect(payments[0]!, paymentsNoRiichi[0]! + 2000);
    });

    test('mangan dealer ron = 12000', () {
      final payments = ScoreCalculator.calculatePayments(
        han: 5,
        fu: 30,
        winnerSeat: 0,
        dealerSeat: 0,
        isTsumo: false,
        loserSeat: 1,
        honbaCount: 0,
        riichiSticks: 0,
      );

      expect(payments[0], 12000);
      expect(payments[1], -12000);
    });

    test('mangan non-dealer ron = 8000', () {
      final payments = ScoreCalculator.calculatePayments(
        han: 5,
        fu: 30,
        winnerSeat: 1,
        dealerSeat: 0,
        isTsumo: false,
        loserSeat: 2,
        honbaCount: 0,
        riichiSticks: 0,
      );

      expect(payments[1], 8000);
      expect(payments[2], -8000);
    });
  });
}
