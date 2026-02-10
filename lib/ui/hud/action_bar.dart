import 'package:flutter/material.dart';
import '../../engine/state/action.dart';

/// Tenhou-style action bar.
/// Compact semi-transparent bar with clean outlined buttons.
class ActionBar extends StatelessWidget {
  final List<PlayerAction> availableActions;
  final ValueChanged<PlayerAction> onAction;

  const ActionBar({
    super.key,
    required this.availableActions,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    if (availableActions.isEmpty) return const SizedBox.shrink();

    final buttons = <Widget>[];

    // Win actions first (most important)
    if (availableActions.any((a) => a is TsumoAction)) {
      buttons.add(_actionButton(
        'ツモ',
        const Color(0xFFFFD54F),
        availableActions.whereType<TsumoAction>().first,
      ));
    }
    if (availableActions.any((a) => a is RonAction)) {
      buttons.add(_actionButton(
        'ロン',
        const Color(0xFFEF5350),
        availableActions.whereType<RonAction>().first,
      ));
    }

    // Riichi
    if (availableActions.any((a) => a is DiscardAction && a.declareRiichi)) {
      buttons.add(_actionButton(
        'リーチ',
        const Color(0xFF7E57C2),
        availableActions.whereType<DiscardAction>().firstWhere((a) => a.declareRiichi),
      ));
    }

    // Calls
    final kans = [
      ...availableActions.whereType<ClosedKanAction>(),
      ...availableActions.whereType<AddedKanAction>(),
      ...availableActions.whereType<OpenKanAction>(),
    ];
    if (kans.isNotEmpty) {
      buttons.add(_actionButton('カン', const Color(0xFF26A69A), kans.first));
    }
    if (availableActions.any((a) => a is PonAction)) {
      buttons.add(_actionButton(
        'ポン',
        const Color(0xFF42A5F5),
        availableActions.whereType<PonAction>().first,
      ));
    }
    if (availableActions.any((a) => a is ChiAction)) {
      buttons.add(_actionButton(
        'チー',
        const Color(0xFF66BB6A),
        availableActions.whereType<ChiAction>().first,
      ));
    }

    // Skip (always last)
    if (availableActions.any((a) => a is SkipAction)) {
      buttons.add(_skipButton(availableActions.whereType<SkipAction>().first));
    }

    // Abort
    if (availableActions.any((a) => a is AbortAction)) {
      buttons.add(_actionButton(
        '九種九牌',
        const Color(0xFFFFA726),
        availableActions.whereType<AbortAction>().first,
      ));
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xCC000000), Color(0xEE000000)],
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: buttons
              .map((b) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: b,
                  ))
              .toList(),
        ),
      ),
    );
  }

  Widget _actionButton(String label, Color color, PlayerAction action) {
    return OutlinedButton(
      onPressed: () => onAction(action),
      style: OutlinedButton.styleFrom(
        foregroundColor: color,
        side: BorderSide(color: color.withValues(alpha: 0.7), width: 1.5),
        backgroundColor: color.withValues(alpha: 0.15),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        minimumSize: const Size(56, 36),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _skipButton(PlayerAction action) {
    return TextButton(
      onPressed: () => onAction(action),
      style: TextButton.styleFrom(
        foregroundColor: Colors.white38,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        minimumSize: const Size(56, 36),
      ),
      child: const Text(
        'パス',
        style: TextStyle(fontSize: 14),
      ),
    );
  }
}
