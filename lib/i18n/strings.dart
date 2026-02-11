enum Lang { zh, en, ja }

/// Get a localized string by key.
String tr(String key, Lang lang) {
  return _strings[key]?[lang] ?? _strings[key]?[Lang.zh] ?? key;
}

const Map<String, Map<Lang, String>> _strings = {
  // Title screen
  'appTitle': {Lang.zh: '麻雀', Lang.en: 'Mahjong', Lang.ja: '麻雀'},
  'appSubtitle': {
    Lang.zh: '虚拟麻将桌',
    Lang.en: 'Virtual Mahjong Table',
    Lang.ja: 'バーチャル麻雀卓',
  },
  'createRoom': {
    Lang.zh: '创建房间',
    Lang.en: 'Create Room',
    Lang.ja: '部屋作成',
  },
  'joinRoom': {
    Lang.zh: '加入房间',
    Lang.en: 'Join Room',
    Lang.ja: '入室',
  },
  'enterNickname': {
    Lang.zh: '输入昵称',
    Lang.en: 'Enter nickname',
    Lang.ja: 'ニックネーム入力',
  },
  'enterRoomCode': {
    Lang.zh: '输入房间号',
    Lang.en: 'Enter room code',
    Lang.ja: 'ルーム番号入力',
  },

  // Lobby
  'waitingForPlayers': {
    Lang.zh: '等待玩家加入...',
    Lang.en: 'Waiting for players...',
    Lang.ja: 'プレイヤー待ち...',
  },
  'roomCode': {Lang.zh: '房间号', Lang.en: 'Room Code', Lang.ja: 'ルーム番号'},
  'startGame': {Lang.zh: '开始', Lang.en: 'Start', Lang.ja: '開始'},
  'seat': {Lang.zh: '座位', Lang.en: 'Seat', Lang.ja: '席'},
  'empty': {Lang.zh: '空位', Lang.en: 'Empty', Lang.ja: '空席'},
  'host': {Lang.zh: '房主', Lang.en: 'Host', Lang.ja: 'ホスト'},
  'leave': {Lang.zh: '离开', Lang.en: 'Leave', Lang.ja: '退室'},

  // Game actions
  'draw': {Lang.zh: '摸牌', Lang.en: 'Draw', Lang.ja: 'ツモ'},
  'drawDeadWall': {Lang.zh: '杠摸', Lang.en: 'Kan Draw', Lang.ja: '嶺上'},
  'discard': {Lang.zh: '打牌', Lang.en: 'Discard', Lang.ja: '打牌'},
  'chi': {Lang.zh: '吃', Lang.en: 'Chi', Lang.ja: 'チー'},
  'pon': {Lang.zh: '碰', Lang.en: 'Pon', Lang.ja: 'ポン'},
  'kan': {Lang.zh: '杠', Lang.en: 'Kan', Lang.ja: 'カン'},
  'openKan': {Lang.zh: '明杠', Lang.en: 'Open Kan', Lang.ja: '大明槓'},
  'closedKan': {Lang.zh: '暗杠', Lang.en: 'Closed Kan', Lang.ja: '暗槓'},
  'addedKan': {Lang.zh: '加杠', Lang.en: 'Added Kan', Lang.ja: '加槓'},
  'riichi': {Lang.zh: '立直', Lang.en: 'Riichi', Lang.ja: 'リーチ'},
  'win': {Lang.zh: '和', Lang.en: 'Win', Lang.ja: '和了'},
  'tsumo': {Lang.zh: '自摸', Lang.en: 'Tsumo', Lang.ja: 'ツモ'},
  'ron': {Lang.zh: '荣和', Lang.en: 'Ron', Lang.ja: 'ロン'},

  // Management actions
  'revealDora': {Lang.zh: '翻宝牌', Lang.en: 'Flip Dora', Lang.ja: 'ドラ'},
  'sortHand': {Lang.zh: '理牌', Lang.en: 'Sort', Lang.ja: '理牌'},
  'showHand': {Lang.zh: '亮牌', Lang.en: 'Reveal', Lang.ja: '手牌公開'},
  'hideHand': {Lang.zh: '盖牌', Lang.en: 'Hide', Lang.ja: '手牌非公開'},
  'undoDiscard': {Lang.zh: '退牌', Lang.en: 'Undo', Lang.ja: '取消'},
  'newRound': {Lang.zh: '新局', Lang.en: 'New Round', Lang.ja: '次局'},
  'keepDealer': {Lang.zh: '连庄', Lang.en: 'Keep Dealer', Lang.ja: '連荘'},
  'rotateDealer': {Lang.zh: '轮庄', Lang.en: 'Rotate Dealer', Lang.ja: '親交代'},

  // Social
  'objection': {Lang.zh: '异议', Lang.en: 'Objection', Lang.ja: '異議'},
  'exchange': {Lang.zh: '转账', Lang.en: 'Transfer', Lang.ja: '送点'},
  'confirm': {Lang.zh: '确认', Lang.en: 'Confirm', Lang.ja: '確認'},
  'reject': {Lang.zh: '拒绝', Lang.en: 'Reject', Lang.ja: '拒否'},
  'cancel': {Lang.zh: '取消', Lang.en: 'Cancel', Lang.ja: 'キャンセル'},
  'adjustScore': {Lang.zh: '调分', Lang.en: 'Adjust', Lang.ja: '得点調整'},

  // Win declaration
  'declareWin': {Lang.zh: '宣布和牌', Lang.en: 'Declare Win', Lang.ja: '和了宣言'},
  'han': {Lang.zh: '番', Lang.en: 'Han', Lang.ja: '翻'},
  'fu': {Lang.zh: '符', Lang.en: 'Fu', Lang.ja: '符'},
  'points': {Lang.zh: '点', Lang.en: 'pts', Lang.ja: '点'},
  'mangan': {Lang.zh: '满贯', Lang.en: 'Mangan', Lang.ja: '満貫'},
  'haneman': {Lang.zh: '跳满', Lang.en: 'Haneman', Lang.ja: '跳満'},
  'baiman': {Lang.zh: '倍满', Lang.en: 'Baiman', Lang.ja: '倍満'},
  'sanbaiman': {Lang.zh: '三倍满', Lang.en: 'Sanbaiman', Lang.ja: '三倍満'},
  'yakuman': {Lang.zh: '役满', Lang.en: 'Yakuman', Lang.ja: '役満'},

  // Compass / info
  'east': {Lang.zh: '东', Lang.en: 'E', Lang.ja: '東'},
  'south': {Lang.zh: '南', Lang.en: 'S', Lang.ja: '南'},
  'west': {Lang.zh: '西', Lang.en: 'W', Lang.ja: '西'},
  'north': {Lang.zh: '北', Lang.en: 'N', Lang.ja: '北'},
  'remaining': {Lang.zh: '残', Lang.en: 'Left', Lang.ja: '残'},
  'honba': {Lang.zh: '本场', Lang.en: 'Honba', Lang.ja: '本場'},

  // Objection dialog
  'objectionPlaceholder': {
    Lang.zh: '说明异议内容...',
    Lang.en: 'Describe the issue...',
    Lang.ja: '異議の内容...',
  },
  'objectionRaised': {
    Lang.zh: '提出异议',
    Lang.en: 'raised an objection',
    Lang.ja: '異議を申し立て',
  },

  // Exchange dialog
  'proposeExchange': {
    Lang.zh: '提议转账',
    Lang.en: 'Propose Transfer',
    Lang.ja: '送点提案',
  },
  'exchangeAmount': {
    Lang.zh: '转账金额',
    Lang.en: 'Transfer Amount',
    Lang.ja: '送点額',
  },
  'exchangeTarget': {
    Lang.zh: '转给',
    Lang.en: 'Transfer to',
    Lang.ja: '送点先',
  },
  'pendingExchange': {
    Lang.zh: '待确认转账',
    Lang.en: 'Pending Transfer',
    Lang.ja: '送点確認待ち',
  },

  // Toggles
  'autoDraw': {Lang.zh: '自动摸牌', Lang.en: 'Auto Draw', Lang.ja: '自動ツモ'},
  'autoDiscard': {
    Lang.zh: '自动打牌',
    Lang.en: 'Auto Discard',
    Lang.ja: '自動打牌',
  },

  // Game config
  'tileCount': {Lang.zh: '牌数', Lang.en: 'Tiles', Lang.ja: '牌数'},
  'variant': {Lang.zh: '玩法', Lang.en: 'Variant', Lang.ja: 'ルール'},
  'startingPts': {Lang.zh: '起始分', Lang.en: 'Start Pts', Lang.ja: '持ち点'},
  'sichuan': {Lang.zh: '四川麻将', Lang.en: 'Sichuan', Lang.ja: '四川麻雀'},
  'riichiVariant': {
    Lang.zh: '日本立直',
    Lang.en: 'Riichi',
    Lang.ja: 'リーチ麻雀',
  },
  'guobiao': {Lang.zh: '国标麻将', Lang.en: 'Guobiao', Lang.ja: '国標麻雀'},
  'guobiaoFlowers': {
    Lang.zh: '国标(花牌)',
    Lang.en: 'Guobiao+Flowers',
    Lang.ja: '国標(花牌)',
  },
  'shanghai': {
    Lang.zh: '上海麻将',
    Lang.en: 'Shanghai',
    Lang.ja: '上海麻雀',
  },
  'sichuanDesc': {
    Lang.zh: '仅数牌(108张), 缺一门, 无吃',
    Lang.en: 'Numbers only (108), no chi',
    Lang.ja: '数牌のみ(108枚), チーなし',
  },
  'riichiDesc': {
    Lang.zh: '标准136张, 翻宝牌',
    Lang.en: 'Standard 136, dora flip',
    Lang.ja: '標準136枚, ドラあり',
  },
  'guobiaoDesc': {
    Lang.zh: '标准136张, 无宝牌',
    Lang.en: 'Standard 136, no dora',
    Lang.ja: '標準136枚, ドラなし',
  },
  'guobiaoFlowersDesc': {
    Lang.zh: '144张(含春夏秋冬梅兰竹菊)',
    Lang.en: '144 tiles (with flowers)',
    Lang.ja: '144枚(花牌あり)',
  },
  'shanghaiDesc': {
    Lang.zh: '144张, 百搭(翻百搭定财神)',
    Lang.en: '144 tiles, wild card (百搭)',
    Lang.ja: '144枚, 百搭(ワイルドカード)',
  },
  'drawFlower': {Lang.zh: '补花', Lang.en: 'Flower', Lang.ja: '補花'},
  'baida': {Lang.zh: '百搭', Lang.en: 'Wild', Lang.ja: '百搭'},
  'autoFlower': {Lang.zh: '自动补花', Lang.en: 'Auto Flower', Lang.ja: '自動補花'},
  'suzhou': {
    Lang.zh: '苏州麻将',
    Lang.en: 'Suzhou',
    Lang.ja: '蘇州麻雀',
  },
  'suzhouDesc': {
    Lang.zh: '152张, 百搭, 无吃, 只碰杠',
    Lang.en: '152 tiles, joker, no chi',
    Lang.ja: '152枚, 百搭, チーなし',
  },
  'flowers': {Lang.zh: '花', Lang.en: 'Flowers', Lang.ja: '花'},
  'gameConfig': {
    Lang.zh: '游戏设置',
    Lang.en: 'Game Settings',
    Lang.ja: 'ゲーム設定',
  },

  // Sichuan 缺一门
  'chooseMissingSuit': {
    Lang.zh: '选缺',
    Lang.en: 'Choose Missing Suit',
    Lang.ja: '不要スーツ選択',
  },
  'waitingForSuitChoice': {
    Lang.zh: '等待选缺...',
    Lang.en: 'Waiting for suit choice...',
    Lang.ja: '不要スーツ選択待ち...',
  },
  'suitMan': {Lang.zh: '万', Lang.en: 'Wan', Lang.ja: '万'},
  'suitPin': {Lang.zh: '筒', Lang.en: 'Pin', Lang.ja: '筒'},
  'suitSou': {Lang.zh: '索', Lang.en: 'Sou', Lang.ja: '索'},
  'missingSuitPrefix': {Lang.zh: '缺', Lang.en: '~', Lang.ja: '缺'},

  // Misc
  'connecting': {
    Lang.zh: '连接中...',
    Lang.en: 'Connecting...',
    Lang.ja: '接続中...',
  },
  'disconnected': {
    Lang.zh: '已断开连接',
    Lang.en: 'Disconnected',
    Lang.ja: '切断されました',
  },
  'error': {Lang.zh: '错误', Lang.en: 'Error', Lang.ja: 'エラー'},
  'language': {Lang.zh: '语言', Lang.en: 'Lang', Lang.ja: '言語'},
};
