import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

class GalagaGameScreen extends StatefulWidget {
  final Stream<List<double>> bluetoothDataStream;

  const GalagaGameScreen({super.key, required this.bluetoothDataStream});

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

        // 좌우 이동 (pitch) - 기체가 화면 밖으로 나가지 않도록 처리
        playerX = (pitch / 14000) * (screenWidth / 2 - 25);
        playerX = playerX.clamp(-screenWidth / 2 + 25, screenWidth / 2 - 25);

        // 상하 이동 (roll), 방향 반대로 설정 및 경계 처리
        playerY = (-roll / 14000) * (screenHeight / 2 - 50);
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
    // 화면 크기 설정을 didChangeDependencies에서 호출하여 MediaQuery에 접근
    screenWidth = MediaQuery.of(context).size.width;
    screenHeight = MediaQuery.of(context).size.height;

    _createEnemies(); // 화면 크기가 결정된 후 적을 생성
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
    bullets
        .add(Offset(playerX + screenWidth / 2, playerY + screenHeight - 100));
    lastBulletFired = DateTime.now(); // 발사 시점 기록
  }

  void _moveBullets() {
    bullets = bullets.map((bullet) {
      return Offset(bullet.dx, bullet.dy - 5); // 총알 위로 이동
    }).toList();
    bullets.removeWhere((bullet) => bullet.dy < 0); // 화면 위를 벗어나면 삭제
  }

  void _moveEnemies() {
    enemies = enemies.map((enemy) {
      return Offset(enemy.dx, enemy.dy + 2); // 적 기체 아래로 이동
    }).toList();
    enemies.removeWhere((enemy) => enemy.dy > screenHeight); // 화면을 벗어나면 삭제

    // 적이 모두 사라지면 새 적 생성
    if (enemies.isEmpty) {
      _createEnemies();
    }
  }

  void _createEnemies() {
    final random = Random();
    enemies.clear();

    // 적 기체 5개 생성 (좌우 경계에서 일정 간격 유지)
    for (int i = 0; i < 5; i++) {
      double x = random.nextDouble() * (screenWidth - 80) + 40; // 좌우 간격 추가
      double y = -random.nextInt(300).toDouble(); // 화면 위쪽에서 등장
      enemies.add(Offset(x, y));
    }
  }

  void _checkCollisions() {
    for (int i = bullets.length - 1; i >= 0; i--) {
      Rect bulletRect = Rect.fromLTWH(bullets[i].dx, bullets[i].dy, 5, 15);

      for (int j = enemies.length - 1; j >= 0; j--) {
        Rect enemyRect = Rect.fromLTWH(enemies[j].dx, enemies[j].dy, 40, 40);

        // 적과 총알이 겹치는지 충돌 감지
        if (bulletRect.overlaps(enemyRect)) {
          bullets.removeAt(i); // 총알 삭제
          enemies.removeAt(j); // 적 삭제
          enemiesDestroyed++;
          break;
        }
      }
    }

    // 적과 플레이어 기체의 충돌을 감지
    for (var enemy in enemies) {
      Rect enemyRect = Rect.fromLTWH(
        enemy.dx, enemy.dy, 40, 40, // 적 기체 크기
      );

      Rect playerRect = Rect.fromLTWH(
        playerX + screenWidth / 2 - 25,
        playerY + screenHeight - 100,
        50, 50, // 플레이어 기체 크기
      );

      if (enemyRect.overlaps(playerRect)) {
        // 충돌이 감지된 경우에만 게임 종료
        _gameOver();
        break;
      }
    }
  }

  void _gameOver() {
    _timer?.cancel(); // 타이머를 취소하여 움직임을 멈춤
    gameStopwatch.stop();

    showDialog(
      context: context,
      barrierDismissible: false, // 대화 상자가 닫히기 전까지 화면 클릭 불가
      builder: (context) => AlertDialog(
        title: const Text("게임 종료"),
        content: Text(
            "총 $enemiesDestroyed명의 적을 잡았습니다.\n경과 시간: ${gameStopwatch.elapsed.inSeconds}초"),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context); // 다이얼로그 닫기
              Navigator.pop(context); // 이전 화면(설정 페이지)으로 돌아가기
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
      appBar: AppBar(
        title: const Text('갤러그 게임'),
      ),
      body: Stack(
        children: [
          // 배경 이미지 표시
          Positioned.fill(
            child: Image.asset(
              'assets/background-1024x1024.png',
              fit: BoxFit.cover,
            ),
          ),
          // 내 기체 표시
          Positioned(
            left: playerX + screenWidth / 2 - 25,
            top: playerY + screenHeight - 100,
            child: Image.asset(
              'assets/my_plane.png',
              width: 30,
              height: 30,
            ),
          ),

          // 총알 표시
          for (var bullet in bullets)
            Positioned(
                left: bullet.dx,
                top: bullet.dy,
                child: Image.asset(
                  'assets/bullet.png',
                  width: 15,
                  height: 20,
                )),

          // 적 기체 표시
          for (var enemy in enemies)
            Positioned(
              left: enemy.dx,
              top: enemy.dy,
              child: Image.asset(
                'assets/enemy_plane.png',
                width: 50,
                height: 50,
              ),
            ),
        ],
      ),
    );
  }
}
