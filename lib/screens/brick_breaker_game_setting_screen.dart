import 'package:flutter/material.dart';
import 'dart:async';

import 'brick_breaker_game_screen.dart';

class GameSettingsScreen extends StatefulWidget {
  final double initialRoll;
  final double initialPitch;
  final double initialYaw;
  final double initialAccx;
  final double initialAccy;
  final double initialAccz;
  final double initialPressure1;
  final double initialPressure2;
  final Stream<List<double>> bluetoothDataStream;

  const GameSettingsScreen({
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

class _GameSettingsScreenState extends State<GameSettingsScreen> {
  // 초기 값 할당
  double roll = 0.0, pitch = 0.0, yaw = 0.0;
  double accx = 0.0, accy = 0.0, accz = 0.0;
  double pressure1 = 0.0, pressure2 = 0.0;

  // 설정 값
  double ballSizeFactor = 0.05; // 공 크기 설정 값
  double ballSpeedFactor = 0.005; // 공 속도 설정 값
  double barWidthFactor = 0.2; // 바 크기 설정 값

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
      appBar: AppBar(title: const Text("게임 설정")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 공 크기 설정
            Text("공 크기: ${(ballSizeFactor * 100).toStringAsFixed(0)}"),
            Slider(
              value: ballSizeFactor,
              min: 0.03,
              max: 0.1,
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
              onChanged: (value) {
                setState(() {
                  ballSpeedFactor = value;
                });
              },
            ),

            // 바 크기 설정
            Text("바 크기: ${(barWidthFactor * 100).toStringAsFixed(0)}"),
            Slider(
              value: barWidthFactor,
              min: 0.1,
              max: 0.4,
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
