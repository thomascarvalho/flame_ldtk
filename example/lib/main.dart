import 'package:flutter/material.dart';
import 'package:flame/game.dart';
import 'game/simplified_game.dart';
import 'game/json_game.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool useJsonFormat = true;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flame LDtk Example',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: Scaffold(
        body: GameWidget(
          key: ValueKey(useJsonFormat),
          game: useJsonFormat ? JsonGame() : SimplifiedGame(),
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () {
            setState(() {
              useJsonFormat = !useJsonFormat;
            });
          },
          label: Text(useJsonFormat ? 'JSON Format' : 'Simplified Format'),
          icon: const Icon(Icons.swap_horiz),
        ),
      ),
    );
  }
}
