import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../engine/state/game_config.dart';
import '../../providers/game_controller_provider.dart';
import 'game_screen.dart';

class TitleScreen extends ConsumerWidget {
  const TitleScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF0D3B0D), Color(0xFF1B5E20)],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                '麻雀',
                style: TextStyle(
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
              const Text(
                'Riichi Mahjong',
                style: TextStyle(
                  fontSize: 24,
                  color: Colors.white70,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 60),
              // Hanchan (East + South)
              _MenuButton(
                label: 'Hanchan (East + South)',
                subtitle: 'Full game — 8+ rounds',
                onPressed: () => _startGame(context, ref, isHanchan: true),
              ),
              const SizedBox(height: 16),
              // Tonpuusen (East only)
              _MenuButton(
                label: 'Tonpuusen (East only)',
                subtitle: 'Quick game — 4+ rounds',
                onPressed: () => _startGame(context, ref, isHanchan: false),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _startGame(BuildContext context, WidgetRef ref, {required bool isHanchan}) {
    final config = GameConfig(isHanchan: isHanchan);
    ref.read(gameControllerProvider.notifier).startGame(config);
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const GameScreen()),
    );
  }
}

class _MenuButton extends StatelessWidget {
  final String label;
  final String subtitle;
  final VoidCallback onPressed;

  const _MenuButton({
    required this.label,
    required this.subtitle,
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
        child: Column(
          children: [
            Text(
              label,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(fontSize: 12, color: Colors.white60),
            ),
          ],
        ),
      ),
    );
  }
}
