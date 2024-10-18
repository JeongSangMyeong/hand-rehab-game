import 'package:flutter/material.dart';
import 'galaga_game_screen.dart'; // 갤러그 게임 화면 가져오기

class GalagaGameSettingScreen extends StatelessWidget {
  final double initialRoll, initialPitch, initialYaw;
  final double initialAccx, initialAccy, initialAccz;
  final double initialPressure1, initialPressure2;
  final Stream<List<double>> bluetoothDataStream;

  const GalagaGameSettingScreen({
    super.key,
    required this.initialRoll,
    required this.initialPitch,
    required this.initialYaw,
    required this.initialAccx,
    required this.initialAccy,
    required this.initialAccz,
    required this.initialPressure1,
    required this.initialPressure2,
    required this.bluetoothDataStream,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("갤러그 게임 설정"),
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => GalagaGameScreen(
                  bluetoothDataStream: bluetoothDataStream,
                ),
              ),
            );
          },
          child: const Text("게임 시작"),
        ),
      ),
    );
  }
}
