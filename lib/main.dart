import 'package:flutter/material.dart';

import 'screens/bluetooth_screen.dart'; // 블루투스 연결 화면 불러오기

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: const BluetoothScreen(), // 첫 화면을 블루투스 연결 화면으로 설정
    );
  }
}
