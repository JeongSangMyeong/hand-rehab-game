// BluetoothScreen.dart
import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:hand_rehab_game/screens/game_list_screen.dart';
import 'package:permission_handler/permission_handler.dart';

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

  @override
  void initState() {
    super.initState();
    _checkPermissions();
    FlutterBluetoothSerial.instance.state.then((state) {
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
    setState(() {
      _isConnecting = true;
    });
    await _attemptAutoConnection();
  }

  Future<void> _attemptAutoConnection() async {
    while (true) {
      setState(() {
        _connectionStatus = "BR14_2052 검색 중...";
      });
      await _getPairedDevices();
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
    setState(() {
      _connectionStatus = "BR14_2052 연결 중...";
    });

    try {
      await BluetoothConnection.toAddress(device.address).then((connection) {
        log.info('Connected to the device');
        this.connection = connection;

        connection.input!.listen((Uint8List data) {
          String incomingData = String.fromCharCodes(data);
          log.info('Received data: $incomingData');
          List<String> parsedNumbers = _parseNumbers(incomingData);

          if (parsedNumbers.isNotEmpty && parsedNumbers.length >= 6) {
            roll = double.tryParse(parsedNumbers[0]) ?? 0.0;
            pitch = double.tryParse(parsedNumbers[1]) ?? 0.0;
            yaw = double.tryParse(parsedNumbers[2]) ?? 0.0;
            accx = double.tryParse(parsedNumbers[3]) ?? 0.0;
            accy = double.tryParse(parsedNumbers[4]) ?? 0.0;
            accz = double.tryParse(parsedNumbers[5]) ?? 0.0;
            pressure1 = parsedNumbers.length > 6
                ? double.tryParse(parsedNumbers[6]) ?? 0.0
                : 0.0;
            pressure2 = parsedNumbers.length > 7
                ? double.tryParse(parsedNumbers[7]) ?? 0.0
                : 0.0;
            _bluetoothDataController.add(
                [roll, pitch, yaw, accx, accy, accz, pressure1, pressure2]);
          }
        }).onDone(() {
          log.info('Disconnected by remote request');
        });

        setState(() {
          _connectionStatus = "BR14_2052 연결되었습니다!";
        });

        Future.delayed(const Duration(seconds: 1), _navigateToGameList);
      });
    } catch (e) {
      log.severe('Error connecting to the device: $e');
      setState(() {
        _connectionStatus = "BR14_2052 연결 실패... 재연결 중...";
      });
      Future.delayed(const Duration(seconds: 3), () {
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

  List<String> _parseNumbers(String data) {
    final RegExp regex = RegExp(r'([-+]?\d*\.\d+|[-+]?\d+)');
    return regex.allMatches(data).map((m) => m.group(0)!).toList();
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
