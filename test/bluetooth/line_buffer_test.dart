import 'package:flutter_test/flutter_test.dart';
import 'package:hand_rehab_game/bluetooth/line_buffer.dart';
import 'package:hand_rehab_game/bluetooth/sensor_parser.dart';

List<int> bytes(String text) => text.codeUnits;

/// 화면 코드와 같은 순서로 덩어리 → 줄 → 센서 값을 거친 결과.
List<List<double>> readingsFrom(List<String> chunks) {
  final buffer = SerialLineBuffer();
  return chunks
      .expand((chunk) => buffer.add(bytes(chunk)))
      .map(parseSensorLine)
      .whereType<List<double>>()
      .toList();
}

void main() {
  group('SerialLineBuffer', () {
    test('한 줄이 두 덩어리로 나뉘어 오면 이어 붙여 한 줄로 내보낸다', () {
      final buffer = SerialLineBuffer();

      expect(buffer.add(bytes('10,-20,30,4')), isEmpty);
      expect(
        buffer.add(bytes('0,50,60,70,80\n')),
        ['10,-20,30,40,50,60,70,80'],
      );
    });

    test('줄 끝이 오기 전의 반쪽 줄은 내보내지 않고 다음 덩어리를 기다린다', () {
      final buffer = SerialLineBuffer();

      expect(buffer.add(bytes('1,2,3')), isEmpty);
      expect(buffer.pendingLength, 5);
      expect(buffer.add(bytes(',4')), isEmpty);
      expect(buffer.add(bytes('\n')), ['1,2,3,4']);
      expect(buffer.pendingLength, 0);
    });

    test('한 덩어리에 여러 줄이 오면 순서대로 모두 내보내고 남은 반쪽은 기다린다', () {
      final buffer = SerialLineBuffer();

      expect(
        buffer.add(bytes('1,1,1,1,1,1,1,1\n2,2,2,2,2,2,2,2\n3,3,3')),
        ['1,1,1,1,1,1,1,1', '2,2,2,2,2,2,2,2'],
      );
      expect(buffer.add(bytes(',3,3,3,3,3\n')), ['3,3,3,3,3,3,3,3']);
    });

    test(r'\r\n, \n, \r이 섞여 와도 줄을 자르고 빈 줄은 건너뛴다', () {
      final buffer = SerialLineBuffer();

      expect(
        buffer.add(bytes('a\r\nb\nc\rd\n\n\r\ne\r')),
        ['a', 'b', 'c', 'd', 'e'],
      );
    });

    test(r'\r\n이 두 덩어리로 갈라져 와도 빈 줄을 만들지 않는다', () {
      final buffer = SerialLineBuffer();

      expect(buffer.add(bytes('1,2,3\r')), ['1,2,3']);
      expect(buffer.add(bytes('\n4,5,6\r\n')), ['4,5,6']);
    });

    test('상한과 길이가 같은 줄은 그대로 내보낸다', () {
      final buffer = SerialLineBuffer(maxLineLength: 8);

      expect(buffer.add(bytes('12345678\n')), ['12345678']);
    });

    test('줄 끝 없이 상한을 넘으면 그 줄을 버리고, 다음 줄 끝 뒤부터 다시 모은다', () {
      var overflows = 0;
      final buffer =
          SerialLineBuffer(maxLineLength: 8, onOverflow: () => overflows++);

      expect(buffer.add(bytes('1234567890,1,2,3,4,5,6')), isEmpty);
      expect(buffer.pendingLength, 0);
      // 버린 줄의 꼬리(',1,2,3,4,5,6')는 줄로 내보내지 않는다.
      expect(buffer.add(bytes('\n7,8\n')), ['7,8']);
      expect(overflows, 1);
    });

    test('줄 끝이 끝내 오지 않아도 모아 두는 양은 상한을 넘지 않는다', () {
      final buffer = SerialLineBuffer(maxLineLength: 64);

      for (var i = 0; i < 1000; i++) {
        buffer.add(bytes('1234567890'));
        expect(buffer.pendingLength, lessThanOrEqualTo(64));
      }
    });

    test('줄 끝을 한 번도 받지 못한 채 상한을 넘으면, 줄 끝을 안 보내는 기기로 보고 예전처럼 덩어리마다 읽는다', () {
      var switched = 0;
      final buffer =
          SerialLineBuffer(maxLineLength: 16, onChunkMode: () => switched++);

      expect(buffer.add(bytes('1,2,3,4,5,6,7,8')), isEmpty);
      expect(
          buffer.add(bytes('1,2,3,4,5,6,7,8')), isEmpty); // 상한을 넘은 이 덩어리는 버린다
      expect(buffer.add(bytes('9,9,9,9,9,9,9,9')), ['9,9,9,9,9,9,9,9']);
      expect(buffer.add(bytes('1,1,1,1,1,1,1,1')), ['1,1,1,1,1,1,1,1']);
      expect(switched, 1);
      expect(buffer.pendingLength, 0);
    });

    test('줄 끝을 한 번이라도 받은 기기는 상한을 넘어도 덩어리마다 읽기로 바꾸지 않는다', () {
      var switched = 0;
      final buffer =
          SerialLineBuffer(maxLineLength: 16, onChunkMode: () => switched++);

      expect(buffer.add(bytes('1,2\n')), ['1,2']);
      expect(buffer.add(bytes('12345678901234567890')), isEmpty);
      expect(buffer.add(bytes('3,4')), isEmpty); // 버린 줄의 꼬리
      expect(buffer.add(bytes('\n5,6\n')), ['5,6']);
      expect(switched, 0);
    });

    test('덩어리마다 읽다가 줄 끝이 오기 시작하면 다시 줄 단위로 모은다', () {
      final buffer = SerialLineBuffer(maxLineLength: 16);
      buffer.add(bytes('12345678901234567890')); // 덩어리마다 읽기로 바뀐다

      // 처음 만난 줄 끝 앞은 반쪽일 수 있어 버리고, 그 뒤부터 줄 단위로 읽는다.
      expect(buffer.add(bytes('1,2\n3,')), isEmpty);
      expect(buffer.add(bytes('4\n')), ['3,4']);
      expect(buffer.add(bytes('5,')), isEmpty);
      expect(buffer.add(bytes('6\n')), ['5,6']);
    });

    test('clear()는 덩어리마다 읽던 상태도 풀어, 새 연결은 줄 단위로 시작한다', () {
      final buffer = SerialLineBuffer(maxLineLength: 16);
      buffer.add(bytes('12345678901234567890'));
      expect(buffer.add(bytes('7,7')), ['7,7']);

      buffer.clear();
      expect(buffer.add(bytes('7,')), isEmpty);
      expect(buffer.add(bytes('8\n')), ['7,8']);
    });

    test('기본 상한은 1024바이트다', () {
      expect(SerialLineBuffer().maxLineLength, 1024);
    });

    test('clear()는 모아 둔 반쪽 줄을 버린다(연결 끊김·재연결)', () {
      final buffer = SerialLineBuffer();

      buffer.add(bytes('10,20,3'));
      buffer.clear();

      expect(buffer.pendingLength, 0);
      expect(buffer.add(bytes('1,2,3,4,5,6\n')), ['1,2,3,4,5,6']);
    });

    test('clear()는 상한 초과로 버리던 상태도 풀어, 새 연결의 첫 줄을 받는다', () {
      final buffer = SerialLineBuffer(maxLineLength: 4);

      buffer.add(bytes('123456789'));
      buffer.clear();

      expect(buffer.add(bytes('1,2\n')), ['1,2']);
    });
  });

  group('덩어리 → 줄 → 센서 값', () {
    test('한 줄이 두 덩어리로 나뉘어도 값을 버리지 않는다', () {
      expect(readingsFrom(['10,-20,30,4', '0,50,60,70,80\r\n']), [
        [10, -20, 30, 40, 50, 60, 70, 80],
      ]);
    });

    test('나뉜 앞부분만 보고 엉뚱한 칸에 값을 넣지 않는다', () {
      // 앞 덩어리에 숫자가 6개 있어도 줄이 끝나지 않았으므로 기다린다.
      expect(readingsFrom(['1,2,3,4,5,6', '0,70,80\r\n']), [
        [1, 2, 3, 4, 5, 60, 70, 80],
      ]);
    });

    test('한 덩어리에 담긴 두 줄을 각각의 값으로 낸다', () {
      expect(readingsFrom(['1,2,3,4,5,6,7,8\r\n9,10,11,12,13,14,15,16\r\n']), [
        [1, 2, 3, 4, 5, 6, 7, 8],
        [9, 10, 11, 12, 13, 14, 15, 16],
      ]);
    });

    test(r'\r\n, \n, \r이 섞인 줄들을 모두 읽는다', () {
      expect(
        readingsFrom(
            ['1,1,1,1,1,1,1,1\r\n2,2,2,2,2,2,2,2\n3,3,3,3', ',3,3,3,3\r']),
        [
          [1, 1, 1, 1, 1, 1, 1, 1],
          [2, 2, 2, 2, 2, 2, 2, 2],
          [3, 3, 3, 3, 3, 3, 3, 3],
        ],
      );
    });

    test('잘못된 줄은 건너뛰고, 그 숫자가 다음 줄 값에 섞이지 않는다', () {
      expect(
        readingsFrom(
            ['1,2,3\r\nERROR\r\n1,2,3,4,5,6,7,8\r\n', '9,9,9,9,9,9,9,9\r\n']),
        [
          [1, 2, 3, 4, 5, 6, 7, 8],
          [9, 9, 9, 9, 9, 9, 9, 9],
        ],
      );
    });

    test('줄 끝을 안 보내는 기기여도, 상한을 넘긴 뒤부터는 예전처럼 덩어리마다 값을 읽는다', () {
      final chunks = List.filled(80, '1,2,3,4,5,6,7,8'); // 덩어리 하나에 한 묶음, 줄 끝 없음
      final readings = readingsFrom(chunks);

      expect(readings, isNotEmpty);
      expect(
          readings
              .every((r) => r.join(',') == '1.0,2.0,3.0,4.0,5.0,6.0,7.0,8.0'),
          isTrue);
    });

    test('줄 끝 없이 상한을 넘은 쓰레기는 값으로 바꾸지 않는다', () {
      final garbage = List.filled(1000, '7,').join(); // 2000바이트, 줄 끝 없음

      expect(readingsFrom([garbage, '\r\n1,2,3,4,5,6,7,8\r\n']), [
        [1, 2, 3, 4, 5, 6, 7, 8],
      ]);
    });
  });
}
