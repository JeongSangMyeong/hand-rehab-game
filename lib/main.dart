import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:math';

void main() => runApp(const BrickBreakerGame());

class BrickBreakerGame extends StatelessWidget {
  const BrickBreakerGame({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: GameSettingsScreen(),
    );
  }
}

// 설정 화면
class GameSettingsScreen extends StatefulWidget {
  const GameSettingsScreen({super.key});

  @override
  _GameSettingsScreenState createState() => _GameSettingsScreenState();
}

class _GameSettingsScreenState extends State<GameSettingsScreen> {
  double ballSizeFactor = 0.05; // 화면 너비의 5%로 설정
  double ballSpeedFactor = 0.01; // 화면 높이의 1%로 설정
  double barWidthFactor = 0.2; // 화면 너비의 20%로 설정

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
            Text("공 속도: ${(ballSpeedFactor * 100).toStringAsFixed(1)}"),
            Slider(
              value: ballSpeedFactor,
              min: 0.005,
              max: 0.02,
              onChanged: (value) {
                setState(() {
                  ballSpeedFactor = value;
                });
              },
            ),
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
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => GameScreen(
                      ballSize: screenWidth * ballSizeFactor,
                      ballSpeed: screenHeight * ballSpeedFactor,
                      barWidth: screenWidth * barWidthFactor,
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

// 게임 화면
class GameScreen extends StatefulWidget {
  final double ballSize;
  final double ballSpeed;
  final double barWidth;

  const GameScreen({
    super.key,
    required this.ballSize,
    required this.ballSpeed,
    required this.barWidth,
  });

  @override
  _GameScreenState createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  double ballX = 0.0;
  double ballY = 0.0;
  double ballSpeedX = 0.0;
  double ballSpeedY = 0.0;
  double barX = 0.0;
  Timer? _timer;
  List<Brick> bricks = [];
  int brokenBricks = 0;
  int remainingBricks = 0;
  final Stopwatch _stopwatch = Stopwatch();
  bool isGameStarted = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initBricks();
      _resetBall();
    });
  }

  // 벽돌 겹침 방지 및 반응형 배치 (15~30개 랜덤)
  void _initBricks() {
    Random random = Random();
    bricks = [];
    double screenWidth = MediaQuery.of(context).size.width;
    double brickWidth = screenWidth * 0.12; // 화면 너비의 12%
    double brickHeight = brickWidth * 0.4; // 벽돌의 높이는 너비의 40%
    int rows = 5;
    int columns = 7;
    int numberOfBricks = random.nextInt(16) + 15; // 15~30개의 벽돌

    for (int i = 0; i < rows; i++) {
      for (int j = 0; j < columns; j++) {
        if (numberOfBricks <= 0) break;
        double brickX = j * (brickWidth + 10);
        double brickY = i * (brickHeight + 10) + 50;

        if (random.nextDouble() > 0.7) {
          continue; // 빈 자리를 만듦
        }

        bricks.add(Brick(
            x: brickX, y: brickY, width: brickWidth, height: brickHeight));
        numberOfBricks--;
      }
    }

    setState(() {
      remainingBricks = bricks.length;
    });
  }

  // 공을 초기화하고 바 위에 위치시키는 함수
  void _resetBall() {
    setState(() {
      ballX = barX + widget.barWidth / 2 - widget.ballSize / 2;
      ballY = MediaQuery.of(context).size.height - 100 - widget.ballSize;
      ballSpeedX = 0;
      ballSpeedY = 0;
      isGameStarted = false;
    });
  }

  // 게임을 시작하는 함수
  void _startGame() {
    setState(() {
      ballSpeedX = widget.ballSpeed;
      ballSpeedY = -widget.ballSpeed;
      isGameStarted = true;
    });
    _stopwatch.start();
    _timer = Timer.periodic(const Duration(milliseconds: 16), (timer) {
      setState(() {
        _moveBall();
        _checkCollisions();
      });
    });
  }

  void _moveBall() {
    ballX += ballSpeedX;
    ballY += ballSpeedY;

    // 벽에 부딪히면 반사
    if (ballX <= 0 ||
        ballX >= MediaQuery.of(context).size.width - widget.ballSize) {
      ballSpeedX = -ballSpeedX;
    }

    if (ballY <= 0) {
      ballSpeedY = -ballSpeedY;
    }

    if (ballY >= MediaQuery.of(context).size.height - widget.ballSize) {
      _gameOver(); // 바닥에 닿으면 게임 종료
    }
  }

  void _checkCollisions() {
    // 바와 충돌 감지
    if (ballY >= MediaQuery.of(context).size.height - 60 &&
        (ballX >= barX && ballX <= barX + widget.barWidth)) {
      ballSpeedY = -ballSpeedY; // 바와 충돌 시 수직 반사
    }

    // 벽돌과 충돌 감지
    for (int i = 0; i < bricks.length; i++) {
      if (bricks[i].isVisible &&
          ballX >= bricks[i].x &&
          ballX <= bricks[i].x + bricks[i].width &&
          ballY >= bricks[i].y &&
          ballY <= bricks[i].y + bricks[i].height) {
        ballSpeedY = -ballSpeedY;
        setState(() {
          bricks[i].isVisible = false; // 벽돌이 사라짐
          brokenBricks++;
          remainingBricks--;
        });
        if (remainingBricks == 0) {
          _initBricks(); // 모든 벽돌이 사라지면 다시 리셋
        }
      }
    }
  }

  void _gameOver() {
    _timer?.cancel();
    _stopwatch.stop();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("게임 종료"),
        content: Text(
            "소요 시간: ${_stopwatch.elapsed.inSeconds}초\n부순 벽돌 수: $brokenBricks"),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context); // 설정 페이지로 돌아감
            },
            child: const Text("다시 시작"),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GestureDetector(
        onPanUpdate: (details) {
          setState(() {
            barX = details.localPosition.dx - widget.barWidth / 2;
            // 바가 양쪽 끝을 넘지 않도록 제한
            if (barX < 0) {
              barX = 0;
            } else if (barX >
                MediaQuery.of(context).size.width - widget.barWidth) {
              barX = MediaQuery.of(context).size.width - widget.barWidth;
            }
            if (!isGameStarted) {
              _resetBall(); // 바가 움직이면 공 위치도 같이 변경
            }
          });
        },
        onTap: () {
          if (!isGameStarted) {
            _startGame(); // 터치 시 게임 시작
          }
        },
        child: Stack(
          children: [
            // 공
            Positioned(
              left: ballX,
              top: ballY,
              child: Container(
                width: widget.ballSize,
                height: widget.ballSize,
                decoration: const BoxDecoration(
                  color: Colors.blue,
                  shape: BoxShape.circle,
                ),
              ),
            ),
            // 바
            Positioned(
              bottom: 30,
              left: barX,
              child: Container(
                width: widget.barWidth,
                height: 20,
                color: Colors.red,
              ),
            ),
            // 벽돌들
            ...bricks.where((brick) => brick.isVisible).map(
                  (brick) => Positioned(
                    left: brick.x,
                    top: brick.y,
                    child: Container(
                      width: brick.width,
                      height: brick.height,
                      color: Colors.green,
                    ),
                  ),
                ),
            // 남은 벽돌 수 표시
            Positioned(
              top: 30,
              left: 20,
              child: Text(
                "남은 벽돌: $remainingBricks",
                style: const TextStyle(fontSize: 20),
              ),
            ),
            // 소요 시간 표시
            Positioned(
              top: 60,
              left: 20,
              child: Text(
                "소요 시간: ${_stopwatch.elapsed.inSeconds}초",
                style: const TextStyle(fontSize: 20),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class Brick {
  final double x;
  final double y;
  final double width;
  final double height;
  bool isVisible;

  Brick({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    this.isVisible = true,
  });
}
