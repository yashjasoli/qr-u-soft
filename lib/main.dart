import 'package:flutter/material.dart';
import 'package:qru_soft/screen/splash_screen.dart';

import 'screen/home_screen.dart';

void main() {
  runApp(const QruSoftApp());
}

class QruSoftApp extends StatelessWidget {
  const QruSoftApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Qr U Soft",
      theme: ThemeData(
        primarySwatch: Colors.blue,
        brightness: Brightness.light,
      ),
      debugShowCheckedModeBanner: false,
      home:  HomeScreen(),
    );
  }
}
