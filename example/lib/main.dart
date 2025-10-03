import 'package:flutter/material.dart';
import 'package:flame/game.dart';
import 'game/platformer_game.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flame LDtk Example',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: GameWidget(game: PlatformerGame()),
    );
  }
}
