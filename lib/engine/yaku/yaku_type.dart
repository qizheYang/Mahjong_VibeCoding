/// All recognized yaku in Riichi Mahjong.
enum YakuType {
  // === 1 han (closed only) ===
  riichi(hanClosed: 1, hanOpen: 0, name: 'Riichi', nameJp: '立直'),
  ippatsu(hanClosed: 1, hanOpen: 0, name: 'Ippatsu', nameJp: '一発'),
  menzenTsumo(hanClosed: 1, hanOpen: 0, name: 'Menzen Tsumo', nameJp: '門前清自摸和'),
  pinfu(hanClosed: 1, hanOpen: 0, name: 'Pinfu', nameJp: '平和'),
  iipeiko(hanClosed: 1, hanOpen: 0, name: 'Iipeiko', nameJp: '一盃口'),

  // === 1 han ===
  tanyao(hanClosed: 1, hanOpen: 1, name: 'Tanyao', nameJp: '断么九'),
  yakuhaiHaku(hanClosed: 1, hanOpen: 1, name: 'Yakuhai Haku', nameJp: '役牌 白'),
  yakuhaiHatsu(hanClosed: 1, hanOpen: 1, name: 'Yakuhai Hatsu', nameJp: '役牌 發'),
  yakuhaiChun(hanClosed: 1, hanOpen: 1, name: 'Yakuhai Chun', nameJp: '役牌 中'),
  yakuhaiSeatWind(hanClosed: 1, hanOpen: 1, name: 'Seat Wind', nameJp: '自風'),
  yakuhaiRoundWind(hanClosed: 1, hanOpen: 1, name: 'Round Wind', nameJp: '場風'),

  // === 1 han (special) ===
  haitei(hanClosed: 1, hanOpen: 1, name: 'Haitei Raoyue', nameJp: '海底摸月'),
  houtei(hanClosed: 1, hanOpen: 1, name: 'Houtei Raoyui', nameJp: '河底撈魚'),
  rinshan(hanClosed: 1, hanOpen: 1, name: 'Rinshan Kaihou', nameJp: '嶺上開花'),
  chankan(hanClosed: 1, hanOpen: 1, name: 'Chankan', nameJp: '槍槓'),

  // === 2 han ===
  doubleRiichi(hanClosed: 2, hanOpen: 0, name: 'Double Riichi', nameJp: 'ダブル立直'),
  chanta(hanClosed: 2, hanOpen: 1, name: 'Chanta', nameJp: '混全帯么九'),
  sanshokuDoujun(hanClosed: 2, hanOpen: 1, name: 'Sanshoku Doujun', nameJp: '三色同順'),
  ittsu(hanClosed: 2, hanOpen: 1, name: 'Ittsu', nameJp: '一気通貫'),
  toitoi(hanClosed: 2, hanOpen: 2, name: 'Toitoi', nameJp: '対々和'),
  sanAnkou(hanClosed: 2, hanOpen: 2, name: 'San Ankou', nameJp: '三暗刻'),
  sanshokuDoukou(hanClosed: 2, hanOpen: 2, name: 'Sanshoku Doukou', nameJp: '三色同刻'),
  sankantsu(hanClosed: 2, hanOpen: 2, name: 'Sankantsu', nameJp: '三槓子'),
  honroutou(hanClosed: 2, hanOpen: 2, name: 'Honroutou', nameJp: '混老頭'),
  shousangen(hanClosed: 2, hanOpen: 2, name: 'Shousangen', nameJp: '小三元'),
  chiitoitsu(hanClosed: 2, hanOpen: 0, name: 'Chiitoitsu', nameJp: '七対子'),

  // === 3 han ===
  honitsu(hanClosed: 3, hanOpen: 2, name: 'Honitsu', nameJp: '混一色'),
  junchan(hanClosed: 3, hanOpen: 2, name: 'Junchan', nameJp: '純全帯么九'),
  ryanpeikou(hanClosed: 3, hanOpen: 0, name: 'Ryanpeikou', nameJp: '二盃口'),

  // === 6 han ===
  chinitsu(hanClosed: 6, hanOpen: 5, name: 'Chinitsu', nameJp: '清一色'),

  // === Yakuman ===
  kokushiMusou(hanClosed: 13, hanOpen: 0, name: 'Kokushi Musou', nameJp: '国士無双', isYakuman: true),
  suuankou(hanClosed: 13, hanOpen: 0, name: 'Suuankou', nameJp: '四暗刻', isYakuman: true),
  daisangen(hanClosed: 13, hanOpen: 13, name: 'Daisangen', nameJp: '大三元', isYakuman: true),
  shousuushii(hanClosed: 13, hanOpen: 13, name: 'Shousuushii', nameJp: '小四喜', isYakuman: true),
  daisuushii(hanClosed: 13, hanOpen: 13, name: 'Daisuushii', nameJp: '大四喜', isYakuman: true),
  tsuuiisou(hanClosed: 13, hanOpen: 13, name: 'Tsuuiisou', nameJp: '字一色', isYakuman: true),
  chinroutou(hanClosed: 13, hanOpen: 13, name: 'Chinroutou', nameJp: '清老頭', isYakuman: true),
  ryuuiisou(hanClosed: 13, hanOpen: 13, name: 'Ryuuiisou', nameJp: '緑一色', isYakuman: true),
  chuurenPoutou(hanClosed: 13, hanOpen: 0, name: 'Chuuren Poutou', nameJp: '九蓮宝燈', isYakuman: true),
  suukantsu(hanClosed: 13, hanOpen: 13, name: 'Suukantsu', nameJp: '四槓子', isYakuman: true),
  tenhou(hanClosed: 13, hanOpen: 0, name: 'Tenhou', nameJp: '天和', isYakuman: true),
  chiihou(hanClosed: 13, hanOpen: 0, name: 'Chiihou', nameJp: '地和', isYakuman: true);

  final int hanClosed;
  final int hanOpen;
  final String name;
  final String nameJp;
  final bool isYakuman;

  const YakuType({
    required this.hanClosed,
    required this.hanOpen,
    required this.name,
    required this.nameJp,
    this.isYakuman = false,
  });

  int han(bool isMenzen) => isMenzen ? hanClosed : hanOpen;
}
