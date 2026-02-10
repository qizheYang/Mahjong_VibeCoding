import 'package:flutter/material.dart';
import 'ui/theme/mahjong_theme.dart';
import 'ui/screens/title_screen.dart';

class MahjongApp extends StatelessWidget {
  const MahjongApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Riichi Mahjong',
      theme: MahjongTheme.theme,
      debugShowCheckedModeBanner: false,
      home: const TitleScreen(),
    );
  }
}
