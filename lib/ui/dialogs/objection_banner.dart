import 'package:flutter/material.dart';

import '../../i18n/strings.dart';
import '../../providers/multiplayer_provider.dart';

/// Banner shown when a player raises an objection.
class ObjectionBanner extends StatelessWidget {
  final ObjectionNotification notification;
  final Lang lang;
  final VoidCallback onDismiss;

  const ObjectionBanner({
    super.key,
    required this.notification,
    required this.lang,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        margin: const EdgeInsets.all(8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xEE990000),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.redAccent, width: 2),
        ),
        child: Row(
          children: [
            const Icon(Icons.warning_amber, color: Colors.amber, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${notification.nickname} ${tr("objectionRaised", lang)}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (notification.message.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      notification.message,
                      style: const TextStyle(
                          color: Colors.white70, fontSize: 12),
                    ),
                  ],
                ],
              ),
            ),
            IconButton(
              onPressed: onDismiss,
              icon: const Icon(Icons.close, color: Colors.white54, size: 20),
            ),
          ],
        ),
      ),
    );
  }
}
