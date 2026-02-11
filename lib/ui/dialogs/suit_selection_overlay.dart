import 'package:flutter/material.dart';

import '../../i18n/strings.dart';

/// Full-screen overlay for Sichuan 缺一门 suit selection.
///
/// Shows three large suit buttons (万/筒/索) and a status row
/// showing which players have/haven't chosen yet.
class SuitSelectionOverlay extends StatelessWidget {
  final Lang lang;
  final List<int?> allMissingSuits; // 4 elements, one per seat
  final List<String> nicknames;
  final int mySeat;
  final bool alreadyChosen; // true if I already chose
  final ValueChanged<int> onChoose;

  const SuitSelectionOverlay({
    super.key,
    required this.lang,
    required this.allMissingSuits,
    required this.nicknames,
    required this.mySeat,
    required this.alreadyChosen,
    required this.onChoose,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {}, // consume taps to block interaction below
      child: Container(
        color: const Color(0xCC000000),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                tr('chooseMissingSuit', lang),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              if (!alreadyChosen) ...[
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _suitButton(0, tr('suitMan', lang), Colors.red.shade700),
                    _suitButton(1, tr('suitPin', lang), Colors.blue.shade700),
                    _suitButton(2, tr('suitSou', lang), Colors.green.shade700),
                  ],
                ),
              ] else ...[
                const Icon(Icons.check_circle, color: Colors.green, size: 48),
                const SizedBox(height: 8),
              ],
              const SizedBox(height: 24),
              _statusRow(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _suitButton(int suit, String label, Color color) {
    return GestureDetector(
      onTap: () => onChoose(suit),
      child: Container(
        width: 80,
        height: 100,
        margin: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white54, width: 2),
        ),
        child: Center(
          child: Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 36,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  Widget _statusRow() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(4, (i) {
        final chosen = allMissingSuits[i] != null;
        final name = nicknames[i].isNotEmpty ? nicknames[i] : '${tr("seat", lang)} ${i + 1}';
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                chosen ? Icons.check_circle : Icons.hourglass_empty,
                color: chosen ? Colors.green : Colors.white38,
                size: 20,
              ),
              const SizedBox(height: 2),
              Text(
                name,
                style: TextStyle(
                  color: i == mySeat ? Colors.amber : Colors.white60,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
}
