import 'package:logging/logging.dart';
import 'package:flutter/foundation.dart';

void setupLogging() {
  Logger.root.level = Level.ALL; // 모든 로그 레벨 출력
  Logger.root.onRecord.listen((LogRecord rec) {
    debugPrint('${rec.level.name}: ${rec.time}: ${rec.message}');
  });
}

final log = Logger('AppLogger'); // 로거 생성
