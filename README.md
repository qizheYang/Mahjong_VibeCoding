# Riichi Mahjong

A complete Japanese Riichi Mahjong game built with Flutter. Play against 3 AI opponents with full rules, classic 2D top-down table view, and accurate scoring.

## Features

### Gameplay
- **Single-player vs 3 AI** — Play locally against computer opponents
- **Hanchan** (East + South) or **Tonpuusen** (East only) game modes
- **All calls** — Chi, Pon, open/closed/added Kan
- **Riichi declaration** with ippatsu tracking
- **Tsumo and Ron** wins with full yaku evaluation

### Rules Coverage
- **~25 standard yaku** — Riichi, Menzen Tsumo, Pinfu, Tanyao, Iipeiko, Yakuhai, Chanta, Sanshoku Doujun, Ittsu, Toitoi, San Ankou, Chiitoitsu, Honitsu, Chinitsu, Ryanpeikou, and more
- **~12 yakuman** — Kokushi Musou, Suuankou, Daisangen, Shousuushii, Daisuushii, Tsuuiisou, Chinroutou, Ryuuiisou, Chuuren Poutou, Suukantsu, Tenhou, Chiihou
- **Accurate scoring** — Han + Fu calculation with standard lookup tables (Mangan, Haneman, Baiman, Sanbaiman, Yakuman)
- **Dora** — Regular dora, ura-dora (on riichi win), red dora (one each of 5m, 5p, 5s)
- **Furiten** — Permanent, temporary, and riichi furiten
- **Exhaustive draw** with tenpai/noten payments
- **Abortive draws** — Kyuushu Kyuuhai, Suufon Renda, Suucha Riichi, Suukaikan, Sanchahou
- **Special wins** — Rinshan Kaihou, Chankan, Haitei, Houtei
- **Dealer rotation** with honba counting and riichi stick collection

### AI
- Shanten-reduction discard strategy
- Safety play against riichi declarers (genbutsu)
- Automatic riichi declaration when tenpai
- Call evaluation based on shanten improvement

## Architecture

```
lib/
├── engine/          Pure Dart game engine (no Flutter imports)
│   ├── tile/        Tile model (136 tiles, 34 kinds)
│   ├── state/       Immutable game/round/player state
│   ├── win/         Win detection, shanten, tenpai, furiten
│   ├── yaku/        All yaku checks and evaluation
│   ├── scoring/     Han/fu calculation, payment tables
│   ├── game/        Game controller, round flow, action validation
│   └── ai/          AI player implementation
├── ui/              Flutter widgets
│   ├── theme/       Colors and styling
│   ├── tiles/       Tile rendering widgets
│   ├── table/       Table layout and player areas
│   ├── hud/         Action bar, scores, round info
│   ├── screens/     Title, game, game over screens
│   └── dialogs/     Round result and game over dialogs
├── providers/       Riverpod state management
└── utils/           Shared extensions
```

The engine layer is pure Dart with zero Flutter dependencies, making it portable for server-side use or future multiplayer.

## Getting Started

```bash
flutter pub get
flutter run
```

## Tech Stack

- **Flutter** — Cross-platform UI
- **Riverpod** — State management
- **Dart** — Pure game engine logic

## Tile Encoding

136 physical tiles with unique IDs 0-135. Each group of 4 consecutive IDs shares a tile kind (0-33):

| Kinds | Tiles |
|-------|-------|
| 0-8 | 1m-9m (Man / Characters) |
| 9-17 | 1p-9p (Pin / Circles) |
| 18-26 | 1s-9s (Sou / Bamboo) |
| 27-30 | East, South, West, North |
| 31-33 | Haku, Hatsu, Chun |

Red dora: ID 16 (5m), 52 (5p), 88 (5s).
