// BluetoothScreen.dart
// ignore_for_file: unused_field

import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:hand_rehab_game/screens/game_list_screen.dart';
import 'package:permission_handler/permission_handler.dart';

import '../bluetooth/line_buffer.dart';
import '../bluetooth/sensor_parser.dart';
import '../utils/logger.dart';

class BluetoothScreen extends StatefulWidget {
  const BluetoothScreen({super.key});

  @override
  _BluetoothScreenState createState() => _BluetoothScreenState();
}

class _BluetoothScreenState extends State<BluetoothScreen> {
  BluetoothState _bluetoothState = BluetoothState.UNKNOWN;
  BluetoothConnection? connection;
  BluetoothDevice? _targetDevice;
  bool _isConnecting = false;
  String _connectionStatus = "BR14_2052 연결 중...";

  double roll = 0.0, pitch = 0.0, yaw = 0.0;
  double accx = 0.0, accy = 0.0, accz = 0.0;
  double pressure1 = 0.0, pressure2 = 0.0;
  final StreamController<List<double>> _bluetoothDataController =
      StreamController<List<double>>.broadcast();
  final SerialLineBuffer _lineBuffer = SerialLineBuffer(
    onOverflow: () => log.warning('Dropped data: no line ending within '
        '${SerialLineBuffer.defaultMaxLineLength} bytes'),
    onChunkMode: () => log.warning('No line ending from device yet: '
        'reading each chunk as one line (legacy mode)'),
  );

  @override
  void initState() {
    super.initState();
    _checkPermissions();
    FlutterBluetoothSerial.instance.state.then((state) {
      if (!mounted) return;
      setState(() {
        _bluetoothState = state;
      });
    });

    // 블루투스 활성화 요청 후 자동 연결 시도
    _startAutoConnection();
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

  void _startAutoConnection() async {
    if (!mounted) return;
    setState(() {
      _isConnecting = true;
    });
    await _attemptAutoConnection();
  }

  Future<void> _attemptAutoConnection() async {
    while (mounted) {
      setState(() {
        _connectionStatus = "BR14_2052 검색 중...";
      });
      await _getPairedDevices();
      if (!mounted) return;
      if (_targetDevice != null) {
        await _attemptConnection(_targetDevice!);
        break;
      } else {
        setState(() {
          _connectionStatus = "BR14_2052 연결 실패... 재연결 중...";
        });
        await Future.delayed(const Duration(seconds: 3));
      }
    }
  }

  Future<void> _getPairedDevices() async {
    try {
      List<BluetoothDevice> devices =
          await FlutterBluetoothSerial.instance.getBondedDevices();
      for (BluetoothDevice device in devices) {
        if (device.name == 'BR14_2052') {
          if (!mounted) return;
          setState(() {
            _targetDevice = device;
          });
          break;
        }
      }
    } catch (e) {
      log.severe("Error getting paired devices: $e");
    }
  }

  Future<void> _attemptConnection(BluetoothDevice device) async {
    if (!mounted) return;
    setState(() {
      _connectionStatus = "BR14_2052 연결 중...";
    });

    try {
      await BluetoothConnection.toAddress(device.address).then((connection) {
        log.info('Connected to the device');
        this.connection = connection;
        // 새 연결은 이전 연결에서 남은 반쪽 줄 없이 시작한다.
        _lineBuffer.clear();

        connection.input!.listen((Uint8List data) {
          String incomingData = String.fromCharCodes(data);
          log.info('Received data: $incomingData');
          // 덩어리가 아니라 줄 끝까지 모인 줄 단위로 파싱한다.
          for (final line in _lineBuffer.add(data)) {
            _handleSensorLine(line);
          }
        }).onDone(() {
          _lineBuffer.clear();
          log.info('Disconnected by remote request');
        });

        if (!mounted) return;
        setState(() {
          _connectionStatus = "BR14_2052 연결되었습니다!";
        });

        Future.delayed(const Duration(seconds: 1), () {
          if (!mounted) return;
          _navigateToGameList();
        });
      });
    } catch (e) {
      log.severe('Error connecting to the device: $e');
      if (!mounted) return;
      setState(() {
        _connectionStatus = "BR14_2052 연결 실패... 재연결 중...";
      });
      Future.delayed(const Duration(seconds: 3), () {
        if (!mounted) return;
        _attemptAutoConnection();
      });
    }
  }

  void _navigateToGameList() {
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
  }

  void _handleSensorLine(String line) {
    final values = parseSensorLine(line);
    if (values == null) {
      log.warning('Dropped invalid line: $line');
      return;
    }
    roll = values[0];
    pitch = values[1];
    yaw = values[2];
    accx = values[3];
    accy = values[4];
    accz = values[5];
    pressure1 = values[6];
    pressure2 = values[7];
    _bluetoothDataController.add(values);
  }

  @override
  void dispose() {
    connection?.dispose();
    _bluetoothDataController.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('블루투스 연결하기'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              _connectionStatus,
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 20),
            const CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
