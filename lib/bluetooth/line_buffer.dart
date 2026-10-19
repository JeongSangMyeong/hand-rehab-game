/// 블루투스 시리얼(SPP)로 받은 바이트 덩어리를 모았다가, 줄 끝을 만난
/// 완성된 줄만 내보낸다.
///
/// 시리얼은 기기가 보낸 한 줄을 여러 덩어리로 나눠 주기도 하고, 여러 줄을
/// 한 덩어리로 묶어 주기도 한다. 그래서 덩어리마다 바로 파싱하지 않고
/// 줄 끝(`\n`, `\r\n`, `\r`)까지 모은 뒤에 자른다.
///
/// 기기가 줄 끝을 보내는지는 실기기로 확인하지 못했다. 줄 끝을 한 번도 받지
/// 못한 채 상한을 넘으면 줄 끝을 안 보내는 기기로 보고, 예전 코드처럼 받은
/// 덩어리를 그대로 한 줄로 본다(덩어리 모드). 줄 끝이 오기 시작하면 다시
/// 줄 단위로 모은다.
class SerialLineBuffer {
  SerialLineBuffer({
    this.maxLineLength = defaultMaxLineLength,
    this.onOverflow,
    this.onChunkMode,
  });

  /// 센서 값 8개가 담긴 한 줄은 수십 바이트라 넉넉하게 잡은 상한.
  static const int defaultMaxLineLength = 1024;

  static const int _lineFeed = 0x0A; // \n
  static const int _carriageReturn = 0x0D; // \r

  /// 줄 끝 없이 이 길이(바이트)를 넘으면 쓰레기로 보고 버린다.
  final int maxLineLength;

  /// 상한을 넘어 줄을 버릴 때 한 번 불린다(로그용).
  final void Function()? onOverflow;

  /// 줄 끝을 안 보내는 기기로 보고 덩어리 모드로 바꿀 때 불린다(로그용).
  final void Function()? onChunkMode;

  final List<int> _pending = <int>[];

  /// 상한을 넘긴 줄의 나머지를 다음 줄 끝까지 버리는 중인지.
  bool _discardingUntilLineEnd = false;

  /// 이번 연결에서 줄 끝을 한 번이라도 받았는지.
  bool _sawLineEnd = false;

  /// 받은 덩어리를 그대로 한 줄로 보는 중인지(줄 끝을 안 보내는 기기).
  bool _chunkMode = false;

  /// 아직 줄 끝을 만나지 못해 모아 둔 바이트 수.
  int get pendingLength => _pending.length;

  /// 덩어리 하나를 받아 이번에 완성된 줄을 받은 순서대로 돌려준다.
  ///
  /// 줄 끝 문자는 빼고 돌려주며 빈 줄은 건너뛴다. 줄 끝이 아직 오지 않은
  /// 반쪽 줄은 다음 덩어리를 기다린다.
  List<String> add(List<int> chunk) {
    if (_chunkMode) {
      if (!chunk.any(_isLineEnd)) {
        return chunk.isEmpty ? const <String>[] : [String.fromCharCodes(chunk)];
      }
      // 줄 끝이 오기 시작했다. 처음 만난 줄 끝 앞은 반쪽일 수 있어 버리고
      // (_discardingUntilLineEnd), 그 뒤부터 줄 단위로 모은다.
      _chunkMode = false;
    }
    final lines = <String>[];
    for (final byte in chunk) {
      if (_isLineEnd(byte)) {
        _sawLineEnd = true;
        if (_pending.isNotEmpty) {
          lines.add(String.fromCharCodes(_pending));
        }
        _resetLine();
      } else if (_discardingUntilLineEnd) {
        continue;
      } else if (_pending.length >= maxLineLength) {
        // 상한을 넘긴 줄은 꼬리까지 버린다. 꼬리만 남겨 두면 엉뚱한 값으로
        // 읽힐 수 있다.
        _pending.clear();
        _discardingUntilLineEnd = true;
        onOverflow?.call();
        if (!_sawLineEnd) {
          // 줄 끝을 한 번도 못 받았다면 줄 끝을 안 보내는 기기일 수 있다.
          // 이 덩어리의 나머지는 버리고, 다음 덩어리부터 예전처럼 읽는다.
          _chunkMode = true;
          onChunkMode?.call();
          break;
        }
      } else {
        _pending.add(byte);
      }
    }
    return lines;
  }

  /// 모아 둔 반쪽 줄을 버리고 처음 상태로 돌아간다. 연결이 끊기거나 새로
  /// 붙을 때 부른다(다른 기기일 수 있어 덩어리 모드도 푼다).
  void clear() {
    _resetLine();
    _sawLineEnd = false;
    _chunkMode = false;
  }

  static bool _isLineEnd(int byte) =>
      byte == _lineFeed || byte == _carriageReturn;

  void _resetLine() {
    _pending.clear();
    _discardingUntilLineEnd = false;
  }
}
