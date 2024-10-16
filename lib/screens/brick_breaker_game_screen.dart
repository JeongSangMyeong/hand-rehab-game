import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

class BrickBreakerGameScreen extends StatefulWidget {
  final double ballSize;
  final double ballSpeed;
  final double barWidth;
  final Stream<List<double>> bluetoothDataStream;

  const BrickBreakerGameScreen({
    super.key,
    required this.ballSize,
    required this.ballSpeed,
    required this.barWidth,
    required this.bluetoothDataStream,
  });

  @override
  _GameScreenState createState() => _GameScreenState();
}

class _GameScreenState extends State<BrickBreakerGameScreen> {
  double ballX = 0.0;
  double ballY = 0.0;
  double ballSpeedX = 0.0;
  double ballSpeedY = 0.0;
  double barX = 0.0;
  Timer? _timer;
  late StreamSubscription<List<double>> _bluetoothSubscription;

  List<Rect> blocks = [];
  int totalBlocksDestroyed = 0;
  Stopwatch gameStopwatch = Stopwatch();

  @override
  void initState() {
    super.initState();
    _startGame();
    gameStopwatch.start(); // 게임 시간 시작

    // 블루투스 스트림 구독
    _bluetoothSubscription = widget.bluetoothDataStream.listen((data) {
      if (!mounted) return; // 위젯이 트리에 존재하는지 확인
      setState(() {
        double pitch = data[1]; // pitch 값 가져오기

        // pitch 값 범위에 맞춰 바 위치 조정 (예시로 -14000 ~ 14000 기준)
        double screenWidth = MediaQuery.of(context).size.width;

        // pitch 값 범위를 조정해 양 끝의 민감도를 맞춤
        double normalizedPitch =
            (pitch + 14000) / 28000; // pitch 범위를 0 ~ 1로 정규화
        barX = normalizedPitch *
            (screenWidth - widget.barWidth); // 정규화된 pitch에 따라 바 위치 조정

        // barX 위치 제한
        if (barX < 0) {
          barX = 0;
        } else if (barX > screenWidth - widget.barWidth) {
          barX = screenWidth - widget.barWidth;
        }
      });
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _resetBall(); // MediaQuery에 의존하는 로직을 여기서 호출
    _createBlocks(); // 블록 생성도 didChangeDependencies에서 호출
  }

  void _resetBall() {
    ballX = barX + widget.barWidth / 2 - widget.ballSize / 2;
    ballY = MediaQuery.of(context).size.height - 100 - widget.ballSize;
    ballSpeedX = widget.ballSpeed;
    ballSpeedY = -widget.ballSpeed;
  }

  void _startGame() {
    _timer = Timer.periodic(const Duration(milliseconds: 16), (timer) {
      if (!mounted) return; // 위젯이 트리에 존재하는지 확인
      setState(() {
        _moveBall();
        _checkCollisions();
      });
    });
  }

  void _moveBall() {
    ballX += ballSpeedX;
    ballY += ballSpeedY;

    if (ballX <= 0 ||
        ballX >= MediaQuery.of(context).size.width - widget.ballSize) {
      ballSpeedX = -ballSpeedX;
    }
    if (ballY <= 0) {
      ballSpeedY = -ballSpeedY;
    }
    if (ballY >= MediaQuery.of(context).size.height - widget.ballSize) {
      _gameOver();
    }
  }

  void _checkCollisions() {
    // 블록 충돌 처리
    for (int i = blocks.length - 1; i >= 0; i--) {
      Rect block = blocks[i];
      Rect ballRect =
          Rect.fromLTWH(ballX, ballY, widget.ballSize, widget.ballSize);

      if (ballRect.overlaps(block)) {
        ballSpeedY = -ballSpeedY;
        setState(() {
          blocks.removeAt(i);
          totalBlocksDestroyed++;
        });

        // 모든 블록을 깨면 새로운 블록 생성
        if (blocks.isEmpty) {
          _createBlocks();
        }
        break;
      }
    }

    // 바와 충돌 처리
    if (ballY >= MediaQuery.of(context).size.height - 60 &&
        ballX >= barX &&
        ballX <= barX + widget.barWidth) {
      ballSpeedY = -ballSpeedY;
    }
  }

  void _createBlocks() {
    Random random = Random();
    int blockCount = random.nextInt(16) + 15; // 15~30개 블록 생성
    double screenWidth = MediaQuery.of(context).size.width;
    double blockGap = 10; // 블록 간 간격
    double sideMargin = 20; // 양쪽 마진
    double totalBlockWidth = screenWidth - (sideMargin * 2); // 사용 가능한 너비

    // 각 블록의 너비는 간격을 고려하여 5개씩 배치될 수 있도록 계산
    double blockWidth = (totalBlockWidth - (blockGap * 4)) / 5;
    double blockHeight = 20;
    blocks = [];

    double startY = 50; // 블록이 시작하는 y 좌표
    double currentY = startY;

    // 블록 배치를 무작위로 생성
    while (blockCount > 0) {
      int blocksInRow = random.nextInt(5) + 1; // 한 줄에 1~5개 블록을 랜덤으로 배치
      double rowGap = blockHeight + blockGap; // 줄 사이 간격

      for (int i = 0; i < blocksInRow && blockCount > 0; i++) {
        double x = sideMargin + i * (blockWidth + blockGap);
        blocks
            .add(Rect.fromLTWH(x, currentY, blockWidth, blockHeight)); // 블록 생성
        blockCount--;
      }

      currentY += rowGap; // 다음 줄로 이동
    }
  }

  void _gameOver() {
    _timer?.cancel();
    gameStopwatch.stop();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("게임 종료"),
        content: Text(
            "총 $totalBlocksDestroyed개의 블록을 깼습니다.\n경과 시간: ${gameStopwatch.elapsed.inSeconds}초"),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context); // 설정 페이지로 돌아감
            },
            child: const Text("확인"),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _bluetoothSubscription.cancel(); // 스트림 구독 취소
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // 공 표시
          Positioned(
            left: ballX,
            top: ballY,
            child: Container(
              width: widget.ballSize, // 공 크기 설정
              height: widget.ballSize,
              decoration: const BoxDecoration(
                color: Colors.blue,
                shape: BoxShape.circle,
              ),
            ),
          ),
          // 바 표시
          Positioned(
            bottom: 30,
            left: barX,
            child: GestureDetector(
              onPanUpdate: (details) {
                setState(() {
                  barX = details.localPosition.dx - widget.barWidth / 2;
                  if (barX < 0) {
                    barX = 0;
                  } else if (barX >
                      MediaQuery.of(context).size.width - widget.barWidth) {
                    barX = MediaQuery.of(context).size.width - widget.barWidth;
                  }
                });
              },
              child: Container(
                width: widget.barWidth, // 바 크기 설정
                height: 20,
                color: Colors.red,
              ),
            ),
          ),
          // 블록 표시
          for (Rect block in blocks)
            Positioned(
              left: block.left,
              top: block.top,
              child: Container(
                width: block.width,
                height: block.height,
                color: Colors.green,
              ),
            ),
        ],
      ),
    );
  }
}
