import 'package:flutter/material.dart';

import '../../i18n/strings.dart';

/// Dialog for declaring a win: select tsumo/ron, enter han + fu.
class WinDeclarationDialog extends StatefulWidget {
  final Lang lang;
  final void Function(bool isTsumo, int han, int fu) onDeclare;

  const WinDeclarationDialog({
    super.key,
    required this.lang,
    required this.onDeclare,
  });

  @override
  State<WinDeclarationDialog> createState() => _WinDeclarationDialogState();
}

class _WinDeclarationDialogState extends State<WinDeclarationDialog> {
  bool _isTsumo = true;
  int _han = 1;
  int _fu = 30;

  @override
  Widget build(BuildContext context) {
    final lang = widget.lang;

    return AlertDialog(
      backgroundColor: const Color(0xFF1A1A3A),
      title: Text(
        tr('declareWin', lang),
        style: const TextStyle(color: Colors.amber, fontWeight: FontWeight.bold),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Tsumo / Ron toggle
            Row(
              children: [
                _toggleBtn(tr('tsumo', lang), _isTsumo, () {
                  setState(() => _isTsumo = true);
                }),
                const SizedBox(width: 8),
                _toggleBtn(tr('ron', lang), !_isTsumo, () {
                  setState(() => _isTsumo = false);
                }),
              ],
            ),
            const SizedBox(height: 16),

            // Han selector
            Text('${tr("han", lang)}:', style: const TextStyle(color: Colors.white70)),
            const SizedBox(height: 4),
            Wrap(
              spacing: 4,
              runSpacing: 4,
              children: List.generate(13, (i) {
                final h = i + 1;
                return _numBtn(h.toString(), _han == h, () {
                  setState(() => _han = h);
                });
              }),
            ),
            const SizedBox(height: 16),

            // Fu selector
            Text('${tr("fu", lang)}:', style: const TextStyle(color: Colors.white70)),
            const SizedBox(height: 4),
            Wrap(
              spacing: 4,
              runSpacing: 4,
              children: [20, 25, 30, 40, 50, 60, 70, 80, 90, 100, 110].map((f) {
                return _numBtn(f.toString(), _fu == f, () {
                  setState(() => _fu = f);
                });
              }).toList(),
            ),
            const SizedBox(height: 16),

            // Quick presets
            Text('快捷 / Presets:',
                style: const TextStyle(color: Colors.white70)),
            const SizedBox(height: 4),
            Wrap(
              spacing: 4,
              runSpacing: 4,
              children: [
                _presetBtn(tr('mangan', lang), 5, 30),
                _presetBtn(tr('haneman', lang), 6, 30),
                _presetBtn(tr('baiman', lang), 8, 30),
                _presetBtn(tr('sanbaiman', lang), 11, 30),
                _presetBtn(tr('yakuman', lang), 13, 30),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(tr('cancel', lang),
              style: const TextStyle(color: Colors.white38)),
        ),
        ElevatedButton(
          onPressed: () => widget.onDeclare(_isTsumo, _han, _fu),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.amber),
          child: Text(tr('confirm', lang),
              style: const TextStyle(color: Colors.black)),
        ),
      ],
    );
  }

  Widget _toggleBtn(String label, bool selected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? Colors.amber : const Color(0x40FFFFFF),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.black : Colors.white60,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _numBtn(String label, bool selected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 32,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? Colors.amber : const Color(0x30FFFFFF),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.black : Colors.white60,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  Widget _presetBtn(String label, int han, int fu) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _han = han;
          _fu = fu;
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0x30FFD54F),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: Colors.amber.withValues(alpha: 0.3)),
        ),
        child: Text(
          label,
          style: const TextStyle(color: Colors.amber, fontSize: 12),
        ),
      ),
    );
  }
}
