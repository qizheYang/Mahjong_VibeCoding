import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../i18n/strings.dart';

/// Dialog for declaring a win: select tsumo/ron, enter han + fu.
/// Used for Riichi variant.
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

/// Sichuan win dialog: tsumo/ron toggle + han 1-5 selector with 2^han preview.
class SichuanWinDialog extends StatefulWidget {
  final Lang lang;
  final void Function(bool isTsumo, int han) onDeclare;

  const SichuanWinDialog({
    super.key,
    required this.lang,
    required this.onDeclare,
  });

  @override
  State<SichuanWinDialog> createState() => _SichuanWinDialogState();
}

class _SichuanWinDialogState extends State<SichuanWinDialog> {
  bool _isTsumo = true;
  int _han = 1;

  int get _perPlayer => 1 << _han; // 2^han

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

            // Han selector 1-5
            Text('${tr("han", lang)} (1-5):',
                style: const TextStyle(color: Colors.white70)),
            const SizedBox(height: 4),
            Row(
              children: List.generate(5, (i) {
                final h = i + 1;
                return Padding(
                  padding: const EdgeInsets.only(right: 6),
                  child: _numBtn(h.toString(), _han == h, () {
                    setState(() => _han = h);
                  }),
                );
              }),
            ),
            const SizedBox(height: 16),

            // Score preview
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0x20FFFFFF),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Text(
                    _isTsumo
                        ? '${tr("tsumo", lang)}: ${tr("perPlayer", lang)} $_perPlayer${tr("points", lang)}'
                        : '${tr("ron", lang)}: $_perPlayer${tr("points", lang)}',
                    style: const TextStyle(color: Colors.amber, fontSize: 16),
                  ),
                  if (_isTsumo)
                    Text(
                      '(${_perPlayer * 3}${tr("points", lang)} ${tr("confirm", lang)})',
                      style: const TextStyle(color: Colors.white38, fontSize: 12),
                    ),
                ],
              ),
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
          onPressed: () => widget.onDeclare(_isTsumo, _han),
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
        width: 40,
        height: 36,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? Colors.amber : const Color(0x30FFFFFF),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.black : Colors.white60,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}

/// Direct point entry win dialog (Guobiao, Shanghai, Suzhou, etc.).
/// Winner enters how much each losing player pays.
class DirectWinDialog extends StatefulWidget {
  final Lang lang;
  final void Function(bool isTsumo, int perPlayer) onDeclare;

  const DirectWinDialog({
    super.key,
    required this.lang,
    required this.onDeclare,
  });

  @override
  State<DirectWinDialog> createState() => _DirectWinDialogState();
}

class _DirectWinDialogState extends State<DirectWinDialog> {
  bool _isTsumo = true;
  final TextEditingController _controller = TextEditingController(text: '8');

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

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

            // Per-player amount
            Text('${tr("perPlayer", lang)}:',
                style: const TextStyle(color: Colors.white70)),
            const SizedBox(height: 8),
            TextField(
              controller: _controller,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: const TextStyle(color: Colors.white, fontSize: 18),
              decoration: InputDecoration(
                suffixText: tr('points', lang),
                suffixStyle: const TextStyle(color: Colors.white38),
                enabledBorder: const UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.amber),
                ),
                focusedBorder: const UnderlineInputBorder(
                  borderSide: BorderSide(color: Colors.amber, width: 2),
                ),
              ),
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
          onPressed: () {
            final amount = int.tryParse(_controller.text) ?? 0;
            if (amount > 0) {
              widget.onDeclare(_isTsumo, amount);
            }
          },
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
}
