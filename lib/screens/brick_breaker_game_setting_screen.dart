import 'dart:async';

import 'package:flutter/material.dart';

import 'brick_breaker_game_screen.dart';

class BrickBreakerGameSettingScreen extends StatefulWidget {
  final double initialRoll;
  final double initialPitch;
  final double initialYaw;
  final double initialAccx;
  final double initialAccy;
  final double initialAccz;
  final double initialPressure1;
  final double initialPressure2;
  final Stream<List<double>> bluetoothDataStream;

  const BrickBreakerGameSettingScreen({
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
  _GameSettingsScreenState createState() => _GameSettingsScreenState();
}

class _GameSettingsScreenState extends State<BrickBreakerGameSettingScreen> {
  // 초기 값 할당
  double roll = 0.0, pitch = 0.0, yaw = 0.0;
  double accx = 0.0, accy = 0.0, accz = 0.0;
  double pressure1 = 0.0, pressure2 = 0.0;

  // 설정 값
  double ballSizeFactor = 0.05; // 공 크기 설정 값
  double ballSpeedFactor = 0.005; // 공 속도 설정 값
  double barWidthFactor = 0.2; // 막대 크기 설정 값

  StreamSubscription<List<double>>? _bluetoothSubscription;

  @override
  void initState() {
    super.initState();

    // 초기 값 할당
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
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      appBar: AppBar(title: const Text("벽돌 깨기 게임 설정")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 게임 설명
            const Text(
              "게임 설명:\n"
              "막대를 움직이고 공을 튕겨서 벽을 제거하세요.\n\n"
              "조작 방법:\n"
              "- 막대를 좌, 우로 움직일 수 있습니다.\n"
              "- 악력을 주면 공이 움직입니다.\n\n"
              "목표:\n"
              "- 공으로 벽을 제거하면 점수가 올라갑니다.\n"
              "- 공을 놓칠 시 게임이 종료됩니다.\n\n"
              "공 크기와 속도, 막대 크기를 설정할 수 있습니다.",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            // 공 크기 설정
            Text("공 크기: ${(ballSizeFactor * 100).toStringAsFixed(0)}"),
            Slider(
              value: ballSizeFactor,
              min: 0.03,
              max: 0.1,
              // divisions: 10,
              label: ballSizeFactor.toStringAsFixed(0),
              onChanged: (value) {
                setState(() {
                  ballSizeFactor = value;
                });
              },
            ),

            // 공 속도 설정
            Text("공 속도: ${(ballSpeedFactor * 100).toStringAsFixed(1)}"),
            Slider(
              value: ballSpeedFactor,
              min: 0.005,
              max: 0.01,
              // divisions: 10,
              label: ballSizeFactor.toStringAsFixed(1),
              onChanged: (value) {
                setState(() {
                  ballSpeedFactor = value;
                });
              },
            ),

            // 막대 크기 설정
            Text("막대 크기: ${(barWidthFactor * 100).toStringAsFixed(0)}"),
            Slider(
              value: barWidthFactor,
              min: 0.1,
              max: 0.4,
              // divisions: 10,
              label: barWidthFactor.toStringAsFixed(0),
              onChanged: (value) {
                setState(() {
                  barWidthFactor = value;
                });
              },
            ),

            // 게임 시작 버튼
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => BrickBreakerGameScreen(
                      ballSize: screenWidth * ballSizeFactor,
                      ballSpeed: screenHeight * ballSpeedFactor,
                      barWidth: screenWidth * barWidthFactor,
                      bluetoothDataStream: widget.bluetoothDataStream,
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
