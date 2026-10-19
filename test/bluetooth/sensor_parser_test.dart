import 'package:flutter_test/flutter_test.dart';
import 'package:hand_rehab_game/bluetooth/sensor_parser.dart';

void main() {
  group('parseSensorLine', () {
    test(
        '숫자 8개를 roll, pitch, yaw, accx, accy, accz, pressure1, pressure2 순서로 읽는다',
        () {
      expect(
        parseSensorLine('-1200,3400,56,-7,8,9,100,200'),
        [-1200, 3400, 56, -7, 8, 9, 100, 200],
      );
    });

    test('기존처럼 소수·부호를 읽고, 쉼표가 아닌 구분자나 이름표도 견딘다', () {
      expect(
        parseSensorLine('r:-12.5 p:+3.25 y:.5 ax:1 ay:2 az:3 pa:4 pb:5'),
        [-12.5, 3.25, 0.5, 1, 2, 3, 4, 5],
      );
    });

    test('압력 값이 빠진 줄(숫자 6~7개)은 기존처럼 0으로 채운다', () {
      expect(parseSensorLine('1,2,3,4,5,6'), [1, 2, 3, 4, 5, 6, 0, 0]);
      expect(parseSensorLine('1,2,3,4,5,6,7'), [1, 2, 3, 4, 5, 6, 7, 0]);
    });

    test('8개를 넘는 숫자는 기존처럼 무시한다', () {
      expect(
        parseSensorLine('1,2,3,4,5,6,7,8,9,10'),
        [1, 2, 3, 4, 5, 6, 7, 8],
      );
    });

    group('잘못된 줄은 null을 돌려준다', () {
      for (final line in [
        '',
        '   ',
        'OK',
        'ERROR,,,',
        '1,2,3,4,5',
        'BR14_2052 ready',
      ]) {
        test('"$line"', () {
          expect(parseSensorLine(line), isNull);
        });
      }

      test('계산에 쓸 수 없는 아주 큰 수(무한대)가 섞이면 버린다', () {
        expect(parseSensorLine('${'9' * 400},1,2,3,4,5'), isNull);
      });

      test('아무 바이트나 와도 예외 없이 null을 돌려준다', () {
        final allBytes = String.fromCharCodes(List.generate(256, (i) => i));

        expect(() => parseSensorLine(allBytes), returnsNormally);
        expect(parseSensorLine(allBytes), isNull);
      });
    });
  });
}
