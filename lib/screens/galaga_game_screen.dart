import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

class GalagaGameScreen extends StatefulWidget {
  final Stream<List<double>> bluetoothDataStream;
  final int enemyCount; // 난이도에 따른 적의 수
  final double playerSpeed; // 기체 속도 조절

  const GalagaGameScreen({
    super.key,
    required this.bluetoothDataStream,
    required this.enemyCount,
    required this.playerSpeed,
  });

  @override
  _GalagaGameScreenState createState() => _GalagaGameScreenState();
}

class _GalagaGameScreenState extends State<GalagaGameScreen> {
  double playerX = 0.0;
  double playerY = 0.0;
  List<Offset> bullets = [];
  List<Offset> enemies = [];
  int enemiesDestroyed = 0;
  Stopwatch gameStopwatch = Stopwatch();
  Timer? _timer;
  late StreamSubscription<List<double>> _bluetoothSubscription;

  // 화면 비율을 기준으로 기체 크기를 설정
  late double playerWidth;
  late double playerHeight;

  double screenWidth = 0;
  double screenHeight = 0;
  DateTime lastBulletFired = DateTime.now(); // 마지막 총알 발사 시간

  @override
  void initState() {
    super.initState();
    gameStopwatch.start();

    // 블루투스 데이터 구독 및 기체 조정
    _bluetoothSubscription = widget.bluetoothDataStream.listen((data) {
      if (!mounted) return;
      setState(() {
        double roll = data[0]; // 세로축 회전 (위, 아래 이동)
        double pitch = data[1]; // 가로축 회전 (좌우 이동)
        double pressure1 = data[6]; // 총알 발사
        double pressure2 = data[7]; // 총알 발사

        // 좌우 이동 (pitch) - 기체 속도 조절 반영
        playerX +=
            (pitch / 14000) * (screenWidth / 2 - 150) * widget.playerSpeed;
        playerX = playerX.clamp(-screenWidth / 2 + 25, screenWidth / 2 - 25);

        // 상하 이동 (roll) - 기체 속도 조절 반영
        playerY +=
            (-roll / 14000) * (screenHeight / 2 - 300) * widget.playerSpeed;
        playerY = playerY.clamp(-screenHeight / 2 + 20, screenHeight / 2 - 500);

        if ((pressure1 > 0 || pressure2 > 0) &&
            DateTime.now().difference(lastBulletFired).inMilliseconds >= 500) {
          _shootBullet();
        }
      });
    });

    // 게임 루프 시작
    _startGame();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    screenWidth = MediaQuery.of(context).size.width;
    screenHeight = MediaQuery.of(context).size.height;

    // 화면 크기에 따른 기체 크기 설정
    playerWidth = screenWidth * 0.1; // 기체 너비를 화면 너비의 10%로 설정
    playerHeight = playerWidth * 1.2; // 기체 높이를 너비의 120%로 설정하여 비율 유지

    _createEnemies(widget.enemyCount); // 난이도에 따른 적 생성
  }

  void _startGame() {
    _timer = Timer.periodic(const Duration(milliseconds: 16), (timer) {
      if (!mounted) return;
      setState(() {
        _moveBullets();
        _moveEnemies();
        _checkCollisions();
      });
    });
  }

  void _shootBullet() {
    // 총알이 기체의 정확한 중앙 상단에서 발사
    bullets.add(Offset(
        playerX + screenWidth / 2 - playerWidth / 2 + playerWidth / 2,
        playerY + screenHeight - playerHeight - 20));
    lastBulletFired = DateTime.now();
  }

  void _moveBullets() {
    bullets = bullets.map((bullet) {
      return Offset(bullet.dx, bullet.dy - 5); // 총알 위로 이동
    }).toList();
    bullets.removeWhere((bullet) => bullet.dy < 0);
  }

  void _moveEnemies() {
    enemies = enemies.map((enemy) {
      return Offset(enemy.dx, enemy.dy + 2);
    }).toList();
    enemies.removeWhere((enemy) => enemy.dy > screenHeight);

    if (enemies.isEmpty) {
      _createEnemies(widget.enemyCount);
    }
  }

  void _createEnemies(int count) {
    final random = Random();
    enemies.clear();

    for (int i = 0; i < count; i++) {
      double x = random.nextDouble() * (screenWidth - 80) + 40;
      double y = -random.nextInt(300).toDouble();
      enemies.add(Offset(x, y));
    }
  }

  void _checkCollisions() {
    for (int i = bullets.length - 1; i >= 0; i--) {
      Rect bulletRect = Rect.fromLTWH(
        bullets[i].dx,
        bullets[i].dy,
        playerWidth * 0.4, // 총알 너비를 기체 너비에 비례하게 설정
        playerHeight * 0.7, // 총알 높이 설정
      );

      for (int j = enemies.length - 1; j >= 0; j--) {
        Rect enemyRect = Rect.fromCenter(
          center: Offset(enemies[j].dx + playerWidth * 0.7,
              enemies[j].dy + playerHeight * 0.7),
          width: playerWidth * 0.6, // 적 기체의 충돌 범위를 축소하여 이미지와 일치
          height: playerHeight * 0.6,
        );

        if (bulletRect.overlaps(enemyRect)) {
          bullets.removeAt(i);
          enemies.removeAt(j);
          enemiesDestroyed++;
          break;
        }
      }
    }

    for (var enemy in enemies) {
      Rect enemyRect = Rect.fromCenter(
        center:
            Offset(enemy.dx + playerWidth * 0.7, enemy.dy + playerHeight * 0.7),
        width: playerWidth * 0.9,
        height: playerHeight * 0.9,
      );

      Rect playerRect = Rect.fromCenter(
        center: Offset(
          playerX + screenWidth / 2,
          playerY + screenHeight - playerHeight / 2,
        ),
        width: playerWidth * 0.7, // 기체의 충돌 범위 축소
        height: playerHeight * 0.8,
      );

      if (enemyRect.overlaps(playerRect)) {
        _gameOver();
        break;
      }
    }
  }

  void _gameOver() {
    _timer?.cancel();
    gameStopwatch.stop();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text("게임 종료"),
        content: Text(
            "총 $enemiesDestroyed개의 적을 잡았습니다.\n경과 시간: ${gameStopwatch.elapsed.inSeconds}초"),
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
    _bluetoothSubscription.cancel();
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/background-1024x1024.png',
              fit: BoxFit.cover,
            ),
          ),
          Positioned(
            left: playerX + screenWidth / 2 - playerWidth / 2,
            top: playerY + screenHeight - playerHeight - 20,
            child: Image.asset(
              'assets/my_plane.png',
              width: playerWidth,
              height: playerHeight,
              alignment: Alignment.center,
            ),
          ),
          for (var bullet in bullets)
            Positioned(
              left: bullet.dx,
              top: bullet.dy,
              child: Image.asset(
                'assets/bullet.png',
                width: playerWidth * 0.4,
                height: playerHeight * 0.7,
                alignment: Alignment.center,
              ),
            ),
          for (var enemy in enemies)
            Positioned(
              left: enemy.dx,
              top: enemy.dy,
              child: Image.asset(
                'assets/enemy_plane.png',
                width: playerWidth * 1.4,
                height: playerHeight * 1.4,
                alignment: Alignment.center,
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
                  "잡은 적: $enemiesDestroyed",
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
