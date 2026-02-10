import '../yaku/yaku_type.dart';
import 'payment_calculator.dart';

/// Complete scoring result for a winning hand.
class ScoreResult {
  final List<YakuType> yakuList;
  final int han;
  final int fu;
  final int doraCount;
  final int uraDoraCount;
  final int redDoraCount;
  final String tierName;
  final PaymentResult payment;

  const ScoreResult({
    required this.yakuList,
    required this.han,
    required this.fu,
    this.doraCount = 0,
    this.uraDoraCount = 0,
    this.redDoraCount = 0,
    required this.tierName,
    required this.payment,
  });

  bool get isYakuman => yakuList.any((y) => y.isYakuman);

  @override
  String toString() =>
      '$tierName: $han han ${fu}fu — ${yakuList.map((y) => y.name).join(", ")}';
}
