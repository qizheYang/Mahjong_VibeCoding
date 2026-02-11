import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../i18n/strings.dart';
import '../../models/game_config.dart';
import '../../providers/multiplayer_provider.dart';
import 'table_screen.dart';

class LobbyScreen extends ConsumerWidget {
  const LobbyScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final conn = ref.watch(multiplayerProvider);
    final lobby = ref.watch(lobbyProvider);
    final lang = ref.watch(langProvider);
    final config = ref.watch(gameConfigProvider);
    final isHost = _isHost(conn, lobby);

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
            child: SingleChildScrollView(
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
                    const SizedBox(height: 24),
                  ],

                  // Seat grid
                  ...List.generate(4, (i) {
                    final seat =
                        lobby.seats.length > i ? lobby.seats[i] : null;
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

                  const SizedBox(height: 20),

                  // ─── Game Config (host only) ─────────────────
                  if (isHost) ...[
                    Text(
                      tr('gameConfig', lang),
                      style: const TextStyle(
                        color: Colors.amber,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _GameConfigPanel(lang: lang),
                    const SizedBox(height: 16),
                  ],

                  // Waiting text
                  if (!isHost)
                    Text(
                      tr('waitingForPlayers', lang),
                      style: const TextStyle(
                          color: Colors.white60, fontSize: 14),
                    ),

                  const SizedBox(height: 16),

                  // Start button (host only)
                  if (isHost)
                    SizedBox(
                      width: 200,
                      child: ElevatedButton(
                        onPressed: () {
                          ref
                              .read(multiplayerProvider.notifier)
                              .startGame(config: config);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF2E7D32),
                          foregroundColor: Colors.white,
                          padding:
                              const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side:
                                const BorderSide(color: Colors.white24),
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
                      ref
                          .read(multiplayerProvider.notifier)
                          .disconnect();
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

// ─── Variant option data ──────────────────────────────────

class _VariantOption {
  final int tileCount;
  final bool isRiichi;
  final String nameKey;
  final String descKey;
  const _VariantOption(
      this.tileCount, this.isRiichi, this.nameKey, this.descKey);
}

const _variants = [
  _VariantOption(108, false, 'sichuan', 'sichuanDesc'),
  _VariantOption(136, true, 'riichiVariant', 'riichiDesc'),
  _VariantOption(136, false, 'guobiao', 'guobiaoDesc'),
  _VariantOption(144, false, 'guobiaoFlowers', 'guobiaoFlowersDesc'),
  _VariantOption(152, false, 'suzhouShanghai', 'suzhouShanghaiDesc'),
];

// ─── Game Config Panel ────────────────────────────────────

class _GameConfigPanel extends ConsumerStatefulWidget {
  final Lang lang;
  const _GameConfigPanel({required this.lang});

  @override
  ConsumerState<_GameConfigPanel> createState() => _GameConfigPanelState();
}

class _GameConfigPanelState extends ConsumerState<_GameConfigPanel> {
  final _pointsController = TextEditingController();
  bool _customPoints = false;

  @override
  void initState() {
    super.initState();
    final config = ref.read(gameConfigProvider);
    _pointsController.text = config.startingPoints.toString();
  }

  @override
  void dispose() {
    _pointsController.dispose();
    super.dispose();
  }

  int _selectedIndex() {
    final config = ref.read(gameConfigProvider);
    for (int i = 0; i < _variants.length; i++) {
      if (_variants[i].tileCount == config.tileCount &&
          _variants[i].isRiichi == config.isRiichi) {
        return i;
      }
    }
    return 1; // default Riichi
  }

  void _selectVariant(int idx) {
    final v = _variants[idx];
    final defaultPts = GameConfig.defaultPoints(v.tileCount, v.isRiichi);
    ref.read(gameConfigProvider.notifier).state = GameConfig(
      tileCount: v.tileCount,
      isRiichi: v.isRiichi,
      startingPoints: _customPoints
          ? (int.tryParse(_pointsController.text) ?? defaultPts)
          : defaultPts,
    );
    if (!_customPoints) {
      _pointsController.text = defaultPts.toString();
    }
  }

  void _updatePoints(String value) {
    final pts = int.tryParse(value);
    if (pts == null) return;
    final config = ref.read(gameConfigProvider);
    ref.read(gameConfigProvider.notifier).state = GameConfig(
      tileCount: config.tileCount,
      isRiichi: config.isRiichi,
      startingPoints: pts,
    );
  }

  @override
  Widget build(BuildContext context) {
    final lang = widget.lang;
    final selected = _selectedIndex();

    return SizedBox(
      width: 300,
      child: Column(
        children: [
          // Variant selector
          ...List.generate(_variants.length, (i) {
            final v = _variants[i];
            final isActive = i == selected;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: GestureDetector(
                onTap: () => _selectVariant(i),
                child: Container(
                  width: 300,
                  padding: const EdgeInsets.symmetric(
                      vertical: 8, horizontal: 12),
                  decoration: BoxDecoration(
                    color: isActive
                        ? const Color(0x40FFD54F)
                        : const Color(0x15FFFFFF),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color:
                          isActive ? Colors.amber : Colors.white12,
                      width: isActive ? 1.5 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isActive
                                ? Colors.amber
                                : Colors.white38,
                            width: 2,
                          ),
                          color: isActive
                              ? Colors.amber
                              : Colors.transparent,
                        ),
                        child: isActive
                            ? const Icon(Icons.check,
                                size: 14, color: Colors.black)
                            : null,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${tr(v.nameKey, lang)}  (${v.tileCount})',
                              style: TextStyle(
                                color: isActive
                                    ? Colors.amber
                                    : Colors.white,
                                fontSize: 14,
                                fontWeight: isActive
                                    ? FontWeight.bold
                                    : FontWeight.normal,
                              ),
                            ),
                            Text(
                              tr(v.descKey, lang),
                              style: const TextStyle(
                                color: Colors.white38,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),

          const SizedBox(height: 12),

          // Starting points
          Row(
            children: [
              Text(
                tr('startingPts', lang),
                style: const TextStyle(
                    color: Colors.white70, fontSize: 14),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 100,
                height: 36,
                child: TextField(
                  controller: _pointsController,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      color: Colors.white, fontSize: 14),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                        RegExp(r'[-\d]')),
                  ],
                  onChanged: (v) {
                    _customPoints = true;
                    _updatePoints(v);
                  },
                  decoration: InputDecoration(
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 8),
                    filled: true,
                    fillColor: const Color(0x20FFFFFF),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide:
                          const BorderSide(color: Colors.white24),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide:
                          const BorderSide(color: Colors.white24),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Text(
                tr('points', lang),
                style: const TextStyle(
                    color: Colors.white54, fontSize: 13),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
