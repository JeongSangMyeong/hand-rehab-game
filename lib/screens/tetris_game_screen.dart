import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

class TetrisGameScreen extends StatefulWidget {
  final Stream<List<double>> bluetoothDataStream;
  final int fallSpeed; // 블록이 내려오는 속도 설정
  final int lateralMoveSpeed; // 좌우 이동 속도 설정

  const TetrisGameScreen({
    super.key,
    required this.bluetoothDataStream,
    required this.fallSpeed,
    required this.lateralMoveSpeed,
  });

  @override
  _TetrisGameScreenState createState() => _TetrisGameScreenState();
}

class _TetrisGameScreenState extends State<TetrisGameScreen> {
  static const int rows = 20;
  static const int columns = 10;
  static const List<List<List<int>>> shapes = [
    [
      [1, 1, 1, 1]
    ], // I
    [
      [1, 1, 1],
      [0, 1, 0]
    ], // T
    [
      [1, 1],
      [1, 1]
    ], // O
    [
      [1, 1, 0],
      [0, 1, 1]
    ], // Z
    [
      [0, 1, 1],
      [1, 1, 0]
    ], // S
    [
      [1, 1, 1],
      [1, 0, 0]
    ], // L
    [
      [1, 1, 1],
      [0, 0, 1]
    ], // J
  ];

  static const List<Color> shapeColors = [
    Colors.cyan,
    Colors.purple,
    Colors.yellow,
    Colors.red,
    Colors.green,
    Colors.orange,
    Colors.blue
  ];

  List<List<int>> board =
      List.generate(rows, (index) => List.filled(columns, 0));
  List<List<int>> currentShape = [];
  Color currentColor = Colors.white;
  int currentX = 3;
  int currentY = 0;

  int score = 0;
  Stopwatch gameStopwatch = Stopwatch();
  Timer? _fallTimer;
  Timer? lateralMoveTimer;
  Timer? rotateTimer; // 회전 타이머 추가
  late StreamSubscription<List<double>> _bluetoothSubscription;
  bool gameOver = false;
  bool _isLateralMoveAllowed = true;
  bool _canRotate = true; // 회전 가능 상태

  @override
  void initState() {
    super.initState();
    _generateNewShape();
    _startFallTimer();
    gameStopwatch.start();

    // 블루투스 데이터 구독하여 움직임과 회전 조정
    _bluetoothSubscription = widget.bluetoothDataStream.listen((data) {
      double pitch = data[1];
      double pressure1 = data[6];
      double pressure2 = data[7];

      // 좌우 이동
      if (_isLateralMoveAllowed) {
        if (pitch < -4000) {
          _moveHorizontally(-1);
        } else if (pitch > 4000) {
          _moveHorizontally(1);
        }
        _isLateralMoveAllowed = false;
        lateralMoveTimer?.cancel();
        lateralMoveTimer = Timer(
          Duration(milliseconds: widget.lateralMoveSpeed),
          () => _isLateralMoveAllowed = true,
        );
      }

      // 블록 회전 - 0.8초마다 한 번씩만 회전
      if ((pressure1 > 0 || pressure2 > 0) && _canRotate) {
        _rotateShape();
        _canRotate = false;
        rotateTimer?.cancel();
        rotateTimer = Timer(const Duration(milliseconds: 800), () {
          _canRotate = true;
        });
      }
    });
  }

  void _startFallTimer() {
    _fallTimer =
        Timer.periodic(Duration(milliseconds: widget.fallSpeed), (timer) {
      setState(() {
        if (!_moveDown()) _lockShape();
      });
    });
  }

  void _moveHorizontally(int direction) {
    setState(() {
      if (_canMove(currentX + direction, currentY)) {
        currentX += direction;
      }
    });
  }

  void _rotateShape() {
    final rotatedShape = List.generate(
        currentShape[0].length,
        (i) => List.generate(currentShape.length,
            (j) => currentShape[currentShape.length - j - 1][i]));

    if (_canMove(currentX, currentY, rotatedShape)) {
      setState(() {
        currentShape = rotatedShape;
      });
    } else {
      // 회전 불가 시 위치 조정
      if (_canMove(currentX - 1, currentY, rotatedShape)) {
        setState(() {
          currentX -= 1;
          currentShape = rotatedShape;
        });
      } else if (_canMove(currentX + 1, currentY, rotatedShape)) {
        setState(() {
          currentX += 1;
          currentShape = rotatedShape;
        });
      } else if (_canMove(currentX - 2, currentY, rotatedShape)) {
        setState(() {
          currentX -= 2;
          currentShape = rotatedShape;
        });
      } else if (_canMove(currentX + 2, currentY, rotatedShape)) {
        setState(() {
          currentX += 2;
          currentShape = rotatedShape;
        });
      } else if (_canMove(currentX - 3, currentY, rotatedShape)) {
        setState(() {
          currentX -= 3;
          currentShape = rotatedShape;
        });
      } else if (_canMove(currentX + 3, currentY, rotatedShape)) {
        setState(() {
          currentX += 3;
          currentShape = rotatedShape;
        });
      }
    }
  }

  bool _moveDown() {
    if (_canMove(currentX, currentY + 1)) {
      currentY += 1;
      return true;
    }
    return false;
  }

  void _lockShape() {
    for (int i = 0; i < currentShape.length; i++) {
      for (int j = 0; j < currentShape[i].length; j++) {
        if (currentShape[i][j] == 1) {
          board[currentY + i][currentX + j] =
              shapeColors.indexOf(currentColor) + 1;
        }
      }
    }
    _clearFullRows();
    if (currentY <= 0) _endGame();
    _generateNewShape();
  }

  void _clearFullRows() {
    for (int row = 0; row < rows; row++) {
      if (board[row].every((cell) => cell != 0)) {
        board.removeAt(row);
        board.insert(0, List.filled(columns, 0));
        score += 1;
      }
    }
  }

  void _generateNewShape() {
    final shapeIndex = Random().nextInt(shapes.length);
    currentShape = shapes[shapeIndex];
    currentColor = shapeColors[shapeIndex];
    currentX = columns ~/ 2 - currentShape[0].length ~/ 2;
    currentY = 0;
  }

  bool _canMove(int x, int y, [List<List<int>>? shape]) {
    shape ??= currentShape;
    for (int i = 0; i < shape.length; i++) {
      for (int j = 0; j < shape[i].length; j++) {
        if (shape[i][j] == 1) {
          int newX = x + j;
          int newY = y + i;
          if (newX < 0 ||
              newX >= columns ||
              newY >= rows ||
              (newY >= 0 && board[newY][newX] != 0)) {
            return false;
          }
        }
      }
    }
    return true;
  }

  void _endGame() {
    setState(() {
      gameOver = true;
      gameStopwatch.stop();
      _fallTimer?.cancel();
      _bluetoothSubscription.cancel();
    });

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text("게임 종료"),
        content: Text("점수: $score\n경과 시간: ${gameStopwatch.elapsed.inSeconds}초"),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text("확인"),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _fallTimer?.cancel();
    rotateTimer?.cancel();
    _bluetoothSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            color: Colors.black, // 빈 공간을 검정색으로 채우기 위해 기본 배경색을 검정색으로 설정
            child: Center(
              child: AspectRatio(
                aspectRatio: columns / rows, // 테트리스 비율 설정 (10:20)
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final blockSize = constraints.maxWidth / columns;

                    return Container(
                      width: blockSize * columns,
                      height: blockSize * rows,
                      color: Colors.black, // 테트리스 보드 색상
                      child: CustomPaint(
                        painter: _TetrisPainter(
                          board,
                          currentShape,
                          currentColor,
                          currentX,
                          currentY,
                          blockSize,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 8, // 화면의 하단에 위치
            left: 8,
            right: 8,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "점수: $score",
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
                Text(
                  "경과 시간: ${gameStopwatch.elapsed.inSeconds}초",
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TetrisPainter extends CustomPainter {
  final List<List<int>> board;
  final List<List<int>> currentShape;
  final Color currentColor;
  final int currentX;
  final int currentY;
  final double blockSize;

  _TetrisPainter(this.board, this.currentShape, this.currentColor,
      this.currentX, this.currentY, this.blockSize);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();

    // 보드 블록 그리기
    for (int i = 0; i < board.length; i++) {
      for (int j = 0; j < board[i].length; j++) {
        if (board[i][j] != 0) {
          paint.color = _TetrisGameScreenState.shapeColors[board[i][j] - 1];
          canvas.drawRect(
              Rect.fromLTWH(j * blockSize, i * blockSize, blockSize, blockSize),
              paint);
        }
      }
    }

    // 현재 이동 중인 블록 그리기
    paint.color = currentColor;
    for (int i = 0; i < currentShape.length; i++) {
      for (int j = 0; j < currentShape[i].length; j++) {
        if (currentShape[i][j] == 1) {
          canvas.drawRect(
              Rect.fromLTWH((currentX + j) * blockSize,
                  (currentY + i) * blockSize, blockSize, blockSize),
              paint);
        }
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
}
