/// 한 줄에서 읽는 센서 값 수.
/// 순서: roll, pitch, yaw, accx, accy, accz, pressure1, pressure2
const int _sensorValueCount = 8;

/// 압력 값(pressure1, pressure2)은 빠질 수 있어서 최소 6개면 읽는다.
const int _minSensorValueCount = 6;

final RegExp _numberPattern = RegExp(r'([-+]?\d*\.\d+|[-+]?\d+)');

/// 기기가 보낸 한 줄을 센서 값 8개로 바꾼다.
///
/// 줄에서 숫자를 앞에서부터 뽑아 roll, pitch, yaw, accx, accy, accz,
/// pressure1, pressure2 순서로 채운다. 구분자는 따지지 않는다.
/// - 압력 값이 빠진 줄(숫자 6~7개)은 빈 칸을 0.0으로 채운다.
/// - 8개를 넘는 숫자는 무시한다.
/// - 숫자가 6개보다 적거나 무한대처럼 계산에 쓸 수 없는 값이 섞인 줄은
///   null을 돌려준다. 이런 줄은 버린다.
List<double>? parseSensorLine(String line) {
  final values = _numberPattern
      .allMatches(line)
      .take(_sensorValueCount)
      .map((match) => double.tryParse(match.group(0)!) ?? double.nan)
      .toList();

  if (values.length < _minSensorValueCount ||
      values.any((value) => !value.isFinite)) {
    return null;
  }

  return List<double>.unmodifiable([
    ...values,
    ...List<double>.filled(_sensorValueCount - values.length, 0.0),
  ]);
}
