import 'dart:async';

import 'package:flutter/material.dart';

import 'galaga_game_screen.dart';

class GalagaGameSettingScreen extends StatefulWidget {
  final double initialRoll;
  final double initialPitch;
  final double initialYaw;
  final double initialAccx;
  final double initialAccy;
  final double initialAccz;
  final double initialPressure1;
  final double initialPressure2;
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
  _GalagaGameSettingScreenState createState() =>
      _GalagaGameSettingScreenState();
}

class _GalagaGameSettingScreenState extends State<GalagaGameSettingScreen> {
  // 초기 값 할당
  double roll = 0.0, pitch = 0.0, yaw = 0.0;
  double accx = 0.0, accy = 0.0, accz = 0.0;
  double pressure1 = 0.0, pressure2 = 0.0;

  // 설정 값
  double enemyCountFactor = 5.0; // 적 수 설정 (상, 중, 하)
  double playerSpeedFactor = 0.5; // 기체 속도 설정

  StreamSubscription<List<double>>? _bluetoothSubscription;

  @override
  void initState() {
    super.initState();

    roll = widget.initialRoll;
    pitch = widget.initialPitch;
    yaw = widget.initialYaw;
    accx = widget.initialAccx;
    accy = widget.initialAccy;
    accz = widget.initialAccz;
    pressure1 = widget.initialPressure1;
    pressure2 = widget.initialPressure2;

    // Bluetooth 데이터 구독하여 실시간 업데이트
    _bluetoothSubscription = widget.bluetoothDataStream.listen((data) {
      setState(() {
        roll = data[0];
        pitch = data[1];
        yaw = data[2];
        accx = data[3];
        accy = data[4];
        accz = data[5];
        pressure1 = data[6];
        pressure2 = data[7];
      });
    });
  }

  @override
  void dispose() {
    _bluetoothSubscription?.cancel(); // 구독 해제
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("비행기 게임 설정")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 게임 설명
            const Text(
              "게임 설명:\n"
              "기체를 움직이며 적을 피하고, 총알을 발사해 적을 처치하세요.\n\n"
              "조작 방법:\n"
              "- 상, 하, 좌, 우로 기체를 움직일 수 있습니다.\n"
              "- 악력을 주면 총알이 발사됩니다.\n\n"
              "목표:\n"
              "- 총알로 적 기체를 파괴하면 점수를 얻습니다.\n"
              "- 적 기체와 부딪히면 게임이 종료됩니다.\n\n"
              "난이도와 기체 속도를 조절할 수 있습니다.",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            // 난이도 설정
            Text("난이도 (적 수): ${enemyCountFactor.toInt()}"),
            Slider(
              value: enemyCountFactor,
              min: 5,
              max: 15,
              divisions: 10,
              label: "${enemyCountFactor.toInt()}개",
              onChanged: (value) {
                setState(() {
                  enemyCountFactor = value;
                });
              },
            ),

            // 기체 속도 설정
            Text("기체 속도: ${(playerSpeedFactor * 100).toStringAsFixed(0)}%"),
            Slider(
              value: playerSpeedFactor,
              min: 0.2,
              max: 1.0,
              label: "${playerSpeedFactor.toStringAsFixed(0)}%",
              onChanged: (value) {
                setState(() {
                  playerSpeedFactor = value;
                });
              },
            ),

            const SizedBox(height: 20),

            // 게임 시작 버튼
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => GalagaGameScreen(
                      bluetoothDataStream: widget.bluetoothDataStream,
                      enemyCount: enemyCountFactor.toInt(),
                      playerSpeed: playerSpeedFactor,
                    ),
                  ),
                );
              },
              child: const Text("게임 시작"),
            ),
          ],
        ),
      ),
    );
  }
}
