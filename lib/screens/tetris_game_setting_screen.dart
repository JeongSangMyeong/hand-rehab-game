import 'package:flutter/material.dart';

import 'tetris_game_screen.dart'; // TetrisGameScreen을 import 합니다.

class TetrisGameSettingScreen extends StatefulWidget {
  final double initialRoll;
  final double initialPitch;
  final double initialYaw;
  final double initialAccx;
  final double initialAccy;
  final double initialAccz;
  final double initialPressure1;
  final double initialPressure2;
  final Stream<List<double>> bluetoothDataStream;

  const TetrisGameSettingScreen({
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
  _TetrisGameSettingScreenState createState() =>
      _TetrisGameSettingScreenState();
}

class _TetrisGameSettingScreenState extends State<TetrisGameSettingScreen> {
  // 블록 속도 설정 초기값
  double blockFallSpeed = 500; // 블록이 내려오는 기본 속도(밀리초 단위)
  double lateralMoveSpeed = 500; // 블록 좌우 이동 기본 속도 (밀리초 단위)

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("테트리스 게임 설정")),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 게임 설명
            const Text(
              "게임 설명:\n"
              "테트리스는 블록을 적절히 회전시키며 빈 공간 없이 줄을 채우는 게임입니다.\n\n"
              "조작 방법:\n"
              "- 블록을 좌우로 이동하려면 기기를 기울여주세요.\n"
              "- 블록을 시계방향으로 회전하려면 악력을 주세요.\n\n"
              "목표:\n"
              "- 블록으로 줄을 채워 제거하면 점수가 올라갑니다.\n"
              "- 블록이 화면 위로 넘치면 게임이 종료됩니다.\n\n"
              "블록이 내려오는 속도를 조절할 수 있습니다.",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),

            // 블록 속도 설정 슬라이더
            Text(
              "블록 속도: ${(blockFallSpeed / 1000).toStringAsFixed(1)}초",
            ),
            Slider(
              value: blockFallSpeed,
              min: 200,
              max: 1000,
              divisions: 8,
              label: "${(blockFallSpeed / 1000).toStringAsFixed(1)}초",
              onChanged: (value) {
                setState(() {
                  blockFallSpeed = value;
                });
              },
            ),

            // 좌우 이동 속도 설정 슬라이더
            Text(
              "좌우 이동 속도: ${(lateralMoveSpeed / 1000).toStringAsFixed(1)}초",
            ),
            Slider(
              value: lateralMoveSpeed,
              min: 200,
              max: 1000,
              divisions: 8,
              label: "${(lateralMoveSpeed / 1000).toStringAsFixed(1)}초",
              onChanged: (value) {
                setState(() {
                  lateralMoveSpeed = value;
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
                    builder: (context) => TetrisGameScreen(
                      bluetoothDataStream: widget.bluetoothDataStream,
                      fallSpeed: blockFallSpeed.toInt(),
                      lateralMoveSpeed: lateralMoveSpeed.toInt(),
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
