import 'package:flutter/material.dart';
import '../../engine/state/action.dart';

/// Overlay prompt shown when the human player can make a call.
class CallPrompt extends StatelessWidget {
  final List<PlayerAction> availableActions;
  final ValueChanged<PlayerAction> onAction;

  const CallPrompt({
    super.key,
    required this.availableActions,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final callActions = availableActions.where((a) => a is! DiscardAction).toList();
    if (callActions.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black87,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.amber, width: 2),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Call?',
            style: TextStyle(
              color: Colors.amber,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: callActions.map((action) {
              final label = _actionLabel(action);
              final color = _actionColor(action);
              return ElevatedButton(
                onPressed: () => onAction(action),
                style: ElevatedButton.styleFrom(
                  backgroundColor: color,
                  foregroundColor: Colors.white,
                ),
                child: Text(label),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  String _actionLabel(PlayerAction action) {
    return switch (action) {
      RonAction() => 'Ron',
      PonAction() => 'Pon',
      ChiAction() => 'Chi',
      OpenKanAction() => 'Kan',
      SkipAction() => 'Skip',
      _ => 'Action',
    };
  }

  Color _actionColor(PlayerAction action) {
    return switch (action) {
      RonAction() => Colors.red,
      PonAction() => Colors.blue,
      ChiAction() => Colors.green,
      OpenKanAction() => Colors.teal,
      SkipAction() => Colors.grey,
      _ => Colors.grey,
    };
  }
}
