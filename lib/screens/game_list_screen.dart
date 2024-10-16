import 'dart:async';
import 'package:flutter/material.dart';

import 'brick_breaker_game_setting_screen.dart';

class GameListScreen extends StatefulWidget {
  final Stream<List<double>> bluetoothDataStream;

  const GameListScreen(
      {super.key,
      required this.bluetoothDataStream,
      required double initialRoll,
      required double initialPitch,
      required double initialYaw,
      required double initialAccx,
      required double initialAccy,
      required double initialAccz,
      required double initialPressure1,
      required double initialPressure2});

  @override
  _GameListScreenState createState() => _GameListScreenState();
}

class _GameListScreenState extends State<GameListScreen> {
  late StreamSubscription<List<double>> _bluetoothSubscription;

  // 블루투스 데이터 변수들
  double roll = 0.0, pitch = 0.0, yaw = 0.0;
  double accx = 0.0, accy = 0.0, accz = 0.0;
  double pressure1 = 0.0, pressure2 = 0.0;

  @override
  void initState() {
    super.initState();

    // 블루투스 스트림 구독
    _bluetoothSubscription = widget.bluetoothDataStream.listen((data) {
      if (!mounted) return;
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
    _bluetoothSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('게임 목록'),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 실시간 블루투스 데이터 표시
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('실시간 데이터',
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold)),
                    // 실시간 데이터 표시
                    Text("Roll(세로축 회전 각도): ${roll.toStringAsFixed(2)}"),
                    Text("Pitch(가로축 회전 각도): ${pitch.toStringAsFixed(2)}"),
                    Text("Yaw(수직축 회전 각도): ${yaw.toStringAsFixed(2)}"),
                    Text("AccX(X축 가속도 값 - 좌,우): ${accx.toStringAsFixed(2)}"),
                    Text("AccY(Y축 가속도 값 - 앞,뒤): ${accy.toStringAsFixed(2)}"),
                    Text("AccZ(Z축 가속도 값 - 위,아래): ${accz.toStringAsFixed(2)}"),
                    Text("Pressure1(안쪽 압력): ${pressure1.toStringAsFixed(2)}"),
                    Text("Pressure2(바깥쪽 압력): ${pressure2.toStringAsFixed(2)}"),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // 게임 리스트 표시
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _buildGameCard(context, "1. 벽돌 깨기 게임"),
                // 다른 게임을 추가할 수 있는 공간
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGameCard(BuildContext context, String gameTitle) {
    return GestureDetector(
      onTap: () {
        // 게임을 선택하면 해당 게임의 설정 화면으로 이동
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => GameSettingsScreen(
              initialRoll: roll,
              initialPitch: pitch,
              initialYaw: yaw,
              initialAccx: accx,
              initialAccy: accy,
              initialAccz: accz,
              initialPressure1: pressure1,
              initialPressure2: pressure2,
              bluetoothDataStream: widget.bluetoothDataStream,
            ),
          ),
        );
      },
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              const Icon(Icons.gamepad, size: 40, color: Colors.blue),
              const SizedBox(width: 16),
              Text(
                gameTitle,
                style:
                    const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
