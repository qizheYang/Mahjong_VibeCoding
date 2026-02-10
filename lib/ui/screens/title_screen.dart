import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../i18n/strings.dart';
import '../../providers/multiplayer_provider.dart';
import 'lobby_screen.dart';

/// Server URL — change for production deployment.
const _serverUrl = 'wss://rehydratedwater.com/mahjong-ws';

class TitleScreen extends ConsumerStatefulWidget {
  const TitleScreen({super.key});

  @override
  ConsumerState<TitleScreen> createState() => _TitleScreenState();
}

class _TitleScreenState extends ConsumerState<TitleScreen> {
  final _nicknameController = TextEditingController();
  final _codeController = TextEditingController();

  @override
  void dispose() {
    _nicknameController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final lang = ref.watch(langProvider);
    final conn = ref.watch(multiplayerProvider);

    // Navigate to lobby when joined
    ref.listen(multiplayerProvider, (prev, next) {
      if (prev?.roomCode == null && next.roomCode != null) {
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const LobbyScreen()),
        );
      }
    });

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
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Language toggle
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _langBtn('中', Lang.zh, lang),
                      _langBtn('EN', Lang.en, lang),
                      _langBtn('日', Lang.ja, lang),
                    ],
                  ),
                  const SizedBox(height: 24),

                  // Title
                  Text(
                    tr('appTitle', lang),
                    style: const TextStyle(
                      fontSize: 72,
                      fontWeight: FontWeight.bold,
                      color: Colors.amber,
                      shadows: [
                        Shadow(
                          color: Colors.black54,
                          blurRadius: 10,
                          offset: Offset(2, 2),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    tr('appSubtitle', lang),
                    style: const TextStyle(
                      fontSize: 18,
                      color: Colors.white70,
                      letterSpacing: 2,
                    ),
                  ),
                  const SizedBox(height: 48),

                  // Nickname field
                  SizedBox(
                    width: 280,
                    child: TextField(
                      controller: _nicknameController,
                      style: const TextStyle(color: Colors.white),
                      textAlign: TextAlign.center,
                      decoration: InputDecoration(
                        hintText: tr('enterNickname', lang),
                        hintStyle: const TextStyle(color: Colors.white38),
                        filled: true,
                        fillColor: const Color(0x20FFFFFF),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Colors.white24),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Colors.white24),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Create Room button
                  _MenuButton(
                    label: tr('createRoom', lang),
                    onPressed: () => _createRoom(),
                  ),
                  const SizedBox(height: 16),

                  // Join Room section
                  SizedBox(
                    width: 280,
                    child: TextField(
                      controller: _codeController,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        letterSpacing: 8,
                      ),
                      textAlign: TextAlign.center,
                      textCapitalization: TextCapitalization.characters,
                      maxLength: 4,
                      decoration: InputDecoration(
                        hintText: tr('enterRoomCode', lang),
                        hintStyle: const TextStyle(
                          color: Colors.white38,
                          fontSize: 16,
                          letterSpacing: 0,
                        ),
                        counterText: '',
                        filled: true,
                        fillColor: const Color(0x20FFFFFF),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Colors.white24),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: Colors.white24),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  _MenuButton(
                    label: tr('joinRoom', lang),
                    onPressed: () => _joinRoom(),
                  ),

                  // Error display
                  if (conn.error != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 24),
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
      ),
    );
  }

  Widget _langBtn(String label, Lang target, Lang current) {
    final isActive = target == current;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: GestureDetector(
        onTap: () => ref.read(langProvider.notifier).state = target,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: isActive ? Colors.amber : const Color(0x20FFFFFF),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            label,
            style: TextStyle(
              color: isActive ? Colors.black : Colors.white60,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }

  void _createRoom() {
    final nickname = _nicknameController.text.trim();
    if (nickname.isEmpty) return;
    final mp = ref.read(multiplayerProvider.notifier);
    mp.connect(_serverUrl);
    // Small delay to ensure connection is established
    Future.delayed(const Duration(milliseconds: 300), () {
      mp.createRoom(nickname);
    });
  }

  void _joinRoom() {
    final nickname = _nicknameController.text.trim();
    final code = _codeController.text.trim().toUpperCase();
    if (nickname.isEmpty || code.length != 4) return;
    final mp = ref.read(multiplayerProvider.notifier);
    mp.connect(_serverUrl);
    Future.delayed(const Duration(milliseconds: 300), () {
      mp.joinRoom(code, nickname);
    });
  }
}

class _MenuButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;

  const _MenuButton({
    required this.label,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 280,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF2E7D32),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: Colors.white24),
          ),
        ),
        child: Text(
          label,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
