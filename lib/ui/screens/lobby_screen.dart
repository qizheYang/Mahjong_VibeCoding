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
                            if (seat?.isAi == true)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                margin: const EdgeInsets.only(right: 4),
                                decoration: BoxDecoration(
                                  color: Colors.blueAccent,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  'AI',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
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
  final bool hasBaida;
  final String nameKey;
  final String descKey;
  const _VariantOption(
      this.tileCount, this.isRiichi, this.hasBaida, this.nameKey, this.descKey);
}

const _variants = [
  _VariantOption(108, false, false, 'sichuan', 'sichuanDesc'),
  _VariantOption(136, true, false, 'riichiVariant', 'riichiDesc'),
  _VariantOption(136, false, false, 'guobiao', 'guobiaoDesc'),
  _VariantOption(144, false, false, 'guobiaoFlowers', 'guobiaoFlowersDesc'),
  _VariantOption(144, false, true, 'shanghai', 'shanghaiDesc'),
  _VariantOption(152, false, false, 'suzhou', 'suzhouDesc'),
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
          _variants[i].isRiichi == config.isRiichi &&
          _variants[i].hasBaida == config.hasBaida) {
        return i;
      }
    }
    return 1; // default Riichi
  }

  void _selectVariant(int idx) {
    final v = _variants[idx];
    final old = ref.read(gameConfigProvider);
    final defaultPts = GameConfig.defaultPoints(v.tileCount, v.isRiichi);
    ref.read(gameConfigProvider.notifier).state = GameConfig(
      tileCount: v.tileCount,
      isRiichi: v.isRiichi,
      hasBaida: v.hasBaida,
      startingPoints: _customPoints
          ? (int.tryParse(_pointsController.text) ?? defaultPts)
          : defaultPts,
      riichiMode: v.isRiichi ? old.riichiMode : 'free',
      noKanDora: v.isRiichi ? old.noKanDora : false,
      noAkaDora: v.isRiichi ? old.noAkaDora : false,
      noUraDora: v.isRiichi ? old.noUraDora : false,
      noIppatsu: v.isRiichi ? old.noIppatsu : false,
      aiSeats: v.tileCount == 108 ? old.aiSeats : const [false, false, false, false],
    );
    if (!_customPoints) {
      _pointsController.text = defaultPts.toString();
    }
  }

  void _updateConfig({
    String? riichiMode,
    bool? noKanDora,
    bool? noAkaDora,
    bool? noUraDora,
    bool? noIppatsu,
    List<bool>? aiSeats,
  }) {
    final c = ref.read(gameConfigProvider);
    ref.read(gameConfigProvider.notifier).state = GameConfig(
      tileCount: c.tileCount,
      isRiichi: c.isRiichi,
      hasBaida: c.hasBaida,
      startingPoints: c.startingPoints,
      riichiMode: riichiMode ?? c.riichiMode,
      noKanDora: noKanDora ?? c.noKanDora,
      noAkaDora: noAkaDora ?? c.noAkaDora,
      noUraDora: noUraDora ?? c.noUraDora,
      noIppatsu: noIppatsu ?? c.noIppatsu,
      aiSeats: aiSeats ?? c.aiSeats,
    );
  }

  void _updatePoints(String value) {
    final pts = int.tryParse(value);
    if (pts == null) return;
    final config = ref.read(gameConfigProvider);
    ref.read(gameConfigProvider.notifier).state = GameConfig(
      tileCount: config.tileCount,
      isRiichi: config.isRiichi,
      hasBaida: config.hasBaida,
      startingPoints: pts,
      riichiMode: config.riichiMode,
      noKanDora: config.noKanDora,
      noAkaDora: config.noAkaDora,
      noUraDora: config.noUraDora,
      noIppatsu: config.noIppatsu,
      aiSeats: config.aiSeats,
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

          // Riichi sub-modes
          if (selected == 1) ...[
            const SizedBox(height: 8),
            _buildRiichiSubModes(lang),
          ],

          // Sichuan AI toggles
          if (selected == 0) ...[
            const SizedBox(height: 8),
            _buildAiToggles(lang),
          ],

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

  Widget _buildRiichiSubModes(Lang lang) {
    final config = ref.watch(gameConfigProvider);
    final mode = config.riichiMode;

    Widget modeRadio(String value, String nameKey, String descKey,
        {bool enabled = true}) {
      final isActive = mode == value;
      return GestureDetector(
        onTap: enabled ? () => _updateConfig(riichiMode: value) : null,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
          margin: const EdgeInsets.symmetric(vertical: 1),
          decoration: BoxDecoration(
            color: isActive
                ? const Color(0x30FFD54F)
                : const Color(0x10FFFFFF),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: isActive ? Colors.amber.withValues(alpha: 0.6) : Colors.white10,
            ),
          ),
          child: Row(
            children: [
              Icon(
                isActive ? Icons.radio_button_checked : Icons.radio_button_off,
                size: 16,
                color: enabled
                    ? (isActive ? Colors.amber : Colors.white38)
                    : Colors.white12,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      tr(nameKey, lang),
                      style: TextStyle(
                        color: enabled
                            ? (isActive ? Colors.amber : Colors.white70)
                            : Colors.white24,
                        fontSize: 12,
                        fontWeight:
                            isActive ? FontWeight.bold : FontWeight.normal,
                      ),
                    ),
                    Text(
                      tr(descKey, lang),
                      style: TextStyle(
                        color: enabled ? Colors.white30 : Colors.white12,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }

    Widget toggleRow(String labelKey, bool value, ValueChanged<bool> onChanged) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 1, horizontal: 10),
        child: Row(
          children: [
            Expanded(
              child: Text(
                tr(labelKey, lang),
                style: const TextStyle(color: Colors.white60, fontSize: 12),
              ),
            ),
            SizedBox(
              height: 28,
              child: Switch(
                value: value,
                onChanged: onChanged,
                activeThumbColor: Colors.amber,
                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      width: 300,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0x10FFFFFF),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          modeRadio('free', 'freeMode', 'freeModeDesc'),
          modeRadio('auto', 'autoMode', 'autoModeDesc', enabled: false),
          modeRadio('custom', 'customMode', 'customModeDesc'),
          if (mode == 'custom') ...[
            const SizedBox(height: 4),
            toggleRow('noKanDora', config.noKanDora,
                (v) => _updateConfig(noKanDora: v)),
            toggleRow('noAkaDora', config.noAkaDora,
                (v) => _updateConfig(noAkaDora: v)),
            toggleRow('noUraDora', config.noUraDora,
                (v) => _updateConfig(noUraDora: v)),
            toggleRow('noIppatsu', config.noIppatsu,
                (v) => _updateConfig(noIppatsu: v)),
          ],
        ],
      ),
    );
  }

  Widget _buildAiToggles(Lang lang) {
    final config = ref.watch(gameConfigProvider);
    final windLabels = [
      tr('east', lang),
      tr('south', lang),
      tr('west', lang),
      tr('north', lang),
    ];

    return Container(
      width: 300,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0x10FFFFFF),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            tr('aiPlayer', lang),
            style: const TextStyle(
              color: Colors.white60,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              for (int i = 1; i < 4; i++)
                GestureDetector(
                  onTap: () {
                    final seats = List<bool>.from(config.aiSeats);
                    seats[i] = !seats[i];
                    _updateConfig(aiSeats: seats);
                  },
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: config.aiSeats[i]
                          ? const Color(0x40FFD54F)
                          : const Color(0x10FFFFFF),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: config.aiSeats[i]
                            ? Colors.amber
                            : Colors.white24,
                      ),
                    ),
                    child: Text(
                      '${windLabels[i]} AI',
                      style: TextStyle(
                        color: config.aiSeats[i]
                            ? Colors.amber
                            : Colors.white54,
                        fontSize: 12,
                        fontWeight: config.aiSeats[i]
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
