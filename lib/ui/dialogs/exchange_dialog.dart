import 'package:flutter/material.dart';

import '../../i18n/strings.dart';

/// Dialog for proposing a point transfer to another player.
class ExchangeDialog extends StatefulWidget {
  final Lang lang;
  final List<String> nicknames;
  final int mySeat;
  final void Function(int targetSeat, int amount) onPropose;

  const ExchangeDialog({
    super.key,
    required this.lang,
    required this.nicknames,
    required this.mySeat,
    required this.onPropose,
  });

  @override
  State<ExchangeDialog> createState() => _ExchangeDialogState();
}

class _ExchangeDialogState extends State<ExchangeDialog> {
  int? _targetSeat;
  final _amountController = TextEditingController(text: '1000');

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lang = widget.lang;

    return AlertDialog(
      backgroundColor: const Color(0xFF1A3A1A),
      title: Text(
        tr('proposeExchange', lang),
        style: const TextStyle(color: Colors.greenAccent),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(tr('exchangeTarget', lang),
              style: const TextStyle(color: Colors.white70)),
          const SizedBox(height: 8),
          ...List.generate(4, (i) {
            if (i == widget.mySeat) return const SizedBox.shrink();
            final name = widget.nicknames[i].isEmpty
                ? '${tr("seat", lang)} ${i + 1}'
                : widget.nicknames[i];
            return Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: GestureDetector(
                onTap: () => setState(() => _targetSeat = i),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: _targetSeat == i
                        ? Colors.greenAccent.withValues(alpha: 0.3)
                        : const Color(0x20FFFFFF),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: _targetSeat == i
                          ? Colors.greenAccent
                          : Colors.white24,
                    ),
                  ),
                  child: Text(
                    name,
                    style: TextStyle(
                      color: _targetSeat == i
                          ? Colors.greenAccent
                          : Colors.white70,
                    ),
                  ),
                ),
              ),
            );
          }),
          const SizedBox(height: 12),
          Text(tr('exchangeAmount', lang),
              style: const TextStyle(color: Colors.white70)),
          const SizedBox(height: 4),
          TextField(
            controller: _amountController,
            keyboardType: TextInputType.number,
            style: const TextStyle(color: Colors.white, fontSize: 20),
            decoration: InputDecoration(
              suffixText: tr('points', lang),
              suffixStyle: const TextStyle(color: Colors.white38),
              enabledBorder: const UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.white24),
              ),
              focusedBorder: const UnderlineInputBorder(
                borderSide: BorderSide(color: Colors.greenAccent),
              ),
            ),
          ),
          const SizedBox(height: 8),
          // Quick amount buttons
          Wrap(
            spacing: 4,
            children: [1000, 2000, 4000, 8000, 12000].map((amt) {
              return ActionChip(
                label: Text('$amt'),
                onPressed: () => _amountController.text = '$amt',
                backgroundColor: const Color(0x30FFFFFF),
                labelStyle:
                    const TextStyle(color: Colors.white70, fontSize: 11),
              );
            }).toList(),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(tr('cancel', lang),
              style: const TextStyle(color: Colors.white38)),
        ),
        ElevatedButton(
          onPressed: _targetSeat != null
              ? () {
                  final amount =
                      int.tryParse(_amountController.text) ?? 0;
                  if (amount > 0) {
                    widget.onPropose(_targetSeat!, amount);
                  }
                }
              : null,
          style:
              ElevatedButton.styleFrom(backgroundColor: Colors.greenAccent),
          child: Text(tr('confirm', lang),
              style: const TextStyle(color: Colors.black)),
        ),
      ],
    );
  }
}
