import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../i18n/strings.dart';
import '../../providers/multiplayer_provider.dart';
import 'table_screen.dart';

class LobbyScreen extends ConsumerWidget {
  const LobbyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final conn = ref.watch(multiplayerProvider);
    final lobby = ref.watch(lobbyProvider);
    final lang = ref.watch(langProvider);

    // Navigate to table when game starts
    ref.listen(tableStateProvider, (prev, next) {
      if (prev == null && next != null && next.gameStarted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const TableScreen()),
        );
      }
    });

    final windLabels = [
      tr('east', lang),
      tr('south', lang),
      tr('west', lang),
      tr('north', lang),
    ];

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0D3B0D), Color(0xFF1B5E20)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Room code display
                if (conn.roomCode != null) ...[
                  Text(
                    tr('roomCode', lang),
                    style: const TextStyle(
                        color: Colors.white60, fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  GestureDetector(
                    onTap: () {
                      Clipboard.setData(
                          ClipboardData(text: conn.roomCode!));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text('Copied!'),
                            duration: Duration(seconds: 1)),
                      );
                    },
                    child: Text(
                      conn.roomCode!,
                      style: const TextStyle(
                        color: Colors.amber,
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 12,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${tr('seat', lang)} ${(conn.mySeat ?? 0) + 1} (${windLabels[conn.mySeat ?? 0]})',
                    style: const TextStyle(
                        color: Colors.white70, fontSize: 16),
                  ),
                  const SizedBox(height: 32),
                ],

                // Seat grid
                ...List.generate(4, (i) {
                  final seat = lobby.seats.length > i ? lobby.seats[i] : null;
                  final isMe = i == conn.mySeat;
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Container(
                      width: 280,
                      padding: const EdgeInsets.symmetric(
                          vertical: 12, horizontal: 16),
                      decoration: BoxDecoration(
                        color: isMe
                            ? const Color(0x40FFD54F)
                            : const Color(0x20FFFFFF),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isMe ? Colors.amber : Colors.white24,
                        ),
                      ),
                      child: Row(
                        children: [
                          Text(
                            '${windLabels[i]}  ',
                            style: const TextStyle(
                                color: Colors.white70, fontSize: 16),
                          ),
                          Expanded(
                            child: Text(
                              seat?.nickname ?? tr('empty', lang),
                              style: TextStyle(
                                color: seat != null
                                    ? Colors.white
                                    : Colors.white30,
                                fontSize: 16,
                              ),
                            ),
                          ),
                          if (seat?.isHost == true)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.amber,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                tr('host', lang),
                                style: const TextStyle(
                                  color: Colors.black,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  );
                }),

                const SizedBox(height: 24),

                // Waiting text
                Text(
                  tr('waitingForPlayers', lang),
                  style: const TextStyle(
                      color: Colors.white60, fontSize: 14),
                ),

                const SizedBox(height: 16),

                // Start button (host only)
                if (_isHost(conn, lobby))
                  SizedBox(
                    width: 200,
                    child: ElevatedButton(
                      onPressed: () {
                        ref.read(multiplayerProvider.notifier).startGame();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF2E7D32),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: const BorderSide(color: Colors.white24),
                        ),
                      ),
                      child: Text(
                        tr('startGame', lang),
                        style: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),

                const SizedBox(height: 12),

                // Leave button
                TextButton(
                  onPressed: () {
                    ref.read(multiplayerProvider.notifier).disconnect();
                    Navigator.of(context).pop();
                  },
                  child: Text(
                    tr('leave', lang),
                    style: const TextStyle(color: Colors.white38),
                  ),
                ),

                // Error display
                if (conn.error != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Text(
                      conn.error!,
                      style: const TextStyle(
                          color: Colors.redAccent, fontSize: 12),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  bool _isHost(RoomConnection conn, LobbyState lobby) {
    if (conn.mySeat == null) return false;
    final seat = lobby.seats.length > conn.mySeat!
        ? lobby.seats[conn.mySeat!]
        : null;
    return seat?.isHost == true;
  }
}
