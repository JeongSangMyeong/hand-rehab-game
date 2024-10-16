import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:hand_rehab_game/screens/game_list_screen.dart';
import 'package:permission_handler/permission_handler.dart';
import '../utils/logger.dart'; // 로깅 가져오기
import 'dart:async';

class BluetoothScreen extends StatefulWidget {
  const BluetoothScreen({super.key});

  @override
  _BluetoothScreenState createState() => _BluetoothScreenState();
}

class _BluetoothScreenState extends State<BluetoothScreen> {
  BluetoothState _bluetoothState = BluetoothState.UNKNOWN;
  BluetoothConnection? connection;
  List<BluetoothDevice> _devicesList = [];
  BluetoothDevice? _selectedDevice;
  bool _isConnecting = false; // 연결 중 상태 추가

  // 모든 변수
  double roll = 0.0, pitch = 0.0, yaw = 0.0;
  double accx = 0.0, accy = 0.0, accz = 0.0;
  double pressure1 = 0.0, pressure2 = 0.0;

  // broadcast()를 사용하여 여러 구독자가 가능하게 설정
  final StreamController<List<double>> _bluetoothDataController =
      StreamController<List<double>>.broadcast();

  @override
  void initState() {
    super.initState();
    _checkPermissions();
    FlutterBluetoothSerial.instance.state.then((state) {
      setState(() {
        _bluetoothState = state;
      });
    });
    _getPairedDevices();
  }

  Future<void> _checkPermissions() async {
    if (await Permission.bluetooth.isDenied ||
        await Permission.bluetoothConnect.isDenied ||
        await Permission.bluetoothScan.isDenied ||
        await Permission.location.isDenied) {
      await [
        Permission.bluetooth,
        Permission.bluetoothConnect,
        Permission.bluetoothScan,
        Permission.location
      ].request();
    }
  }

  Future<void> _getPairedDevices() async {
    try {
      List<BluetoothDevice> devices =
          await FlutterBluetoothSerial.instance.getBondedDevices();
      setState(() {
        _devicesList = devices;
      });
    } catch (e) {
      log.severe("Error getting paired devices: $e");
    }
  }

  Future<void> _connectToDevice(BluetoothDevice device) async {
    setState(() {
      _isConnecting = true; // 연결 시 로딩 상태로 변경
    });

    try {
      await BluetoothConnection.toAddress(device.address).then((connection) {
        log.info('Connected to the device');
        this.connection = connection;

        connection.input!.listen((Uint8List data) {
          String incomingData = String.fromCharCodes(data);
          log.info('Raw incoming data: $incomingData'); // 데이터 확인용

          // 데이터를 파싱
          List<String> parsedNumbers = _parseNumbers(incomingData);
          if (parsedNumbers.isNotEmpty && parsedNumbers.length >= 6) {
            roll = double.tryParse(parsedNumbers[0]) ?? 0.0;
            pitch = double.tryParse(parsedNumbers[1]) ?? 0.0;
            yaw = double.tryParse(parsedNumbers[2]) ?? 0.0;
            accx = double.tryParse(parsedNumbers[3]) ?? 0.0;
            accy = double.tryParse(parsedNumbers[4]) ?? 0.0;
            accz = double.tryParse(parsedNumbers[5]) ?? 0.0;

            // 압력 센서 값 처리
            if (parsedNumbers.length == 7) {
              pressure1 = 0.0;
              pressure2 = double.tryParse(parsedNumbers[6]) ?? 0.0;
            } else if (parsedNumbers.length >= 8) {
              pressure1 = double.tryParse(parsedNumbers[6]) ?? 0.0;
              pressure2 = double.tryParse(parsedNumbers[7]) ?? 0.0;
            }

            log.info('Parsed values - Roll: $roll, Pitch: $pitch, Yaw: $yaw, '
                'AccX: $accx, AccY: $accy, AccZ: $accz, '
                'Pressure1: $pressure1, Pressure2: $pressure2');

            // StreamController에 데이터 추가
            _bluetoothDataController.add(
                [roll, pitch, yaw, accx, accy, accz, pressure1, pressure2]);
          } else {
            log.warning(
                'Parsed numbers are less than expected: $parsedNumbers');
          }

          if (incomingData.contains('!')) {
            connection.finish(); // Closing connection
            log.info('Disconnecting by local host');
          }
        }).onDone(() {
          log.info('Disconnected by remote request');
        });

        // 연결 성공 시 팝업 띄우기
        _showSuccessDialog();
      });
    } catch (e) {
      log.severe('Error connecting to the device: $e');
      _showFailureDialog(); // 연결 실패 시 팝업 띄우기
    } finally {
      setState(() {
        _isConnecting = false; // 연결 시도가 끝난 후 로딩 상태 해제
      });
    }
  }

  List<String> _parseNumbers(String data) {
    // 부호가 포함된 숫자를 올바르게 파싱하기 위한 정규식
    final RegExp regex = RegExp(r'([-+]?\d*\.\d+|[-+]?\d+)');
    return regex.allMatches(data).map((m) => m.group(0)!).toList();
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("연결 성공"),
          content: const Text("블루투스 장치와의 연결에 성공했습니다."),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // 팝업 닫기
                // 게임 설정 화면으로 이동, 스트림과 초기값 전달
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => GameListScreen(
                      initialRoll: roll,
                      initialPitch: pitch,
                      initialYaw: yaw,
                      initialAccx: accx,
                      initialAccy: accy,
                      initialAccz: accz,
                      initialPressure1: pressure1,
                      initialPressure2: pressure2,
                      bluetoothDataStream: _bluetoothDataController.stream,
                    ),
                  ),
                );
              },
              child: const Text("확인"),
            ),
          ],
        );
      },
    );
  }

  void _showFailureDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("연결 실패"),
          content: const Text("연결에 실패했습니다. 다시 시도해 주십시오."),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // 팝업 닫기
              },
              child: const Text("확인"),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    connection?.dispose();
    _bluetoothDataController.close(); // StreamController 닫기
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('블루투스 연결하기'),
      ),
      body: Stack(
        children: [
          Column(
            children: <Widget>[
              SwitchListTile(
                title: const Text('블루투스 사용'),
                value: _bluetoothState.isEnabled,
                onChanged: (bool value) {
                  if (value) {
                    FlutterBluetoothSerial.instance.requestEnable();
                  } else {
                    FlutterBluetoothSerial.instance.requestDisable();
                  }
                  _getPairedDevices();
                },
              ),
              DropdownButton<BluetoothDevice>(
                hint: const Text('장치 선택'),
                items: _devicesList.map((BluetoothDevice device) {
                  return DropdownMenuItem<BluetoothDevice>(
                    value: device,
                    child: Text(device.name!),
                  );
                }).toList(),
                onChanged: (BluetoothDevice? value) {
                  setState(() {
                    _selectedDevice = value;
                  });
                },
                value: _selectedDevice,
              ),
              ElevatedButton(
                onPressed: _selectedDevice != null && !_isConnecting
                    ? () => _connectToDevice(_selectedDevice!)
                    : null,
                child: const Text('연결하기'),
              ),
            ],
          ),
          if (_isConnecting)
            const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 10),
                  Text('연결 중...'),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
