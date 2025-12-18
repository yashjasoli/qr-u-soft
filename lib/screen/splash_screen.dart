import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:qru_soft/screen/home_screen.dart';

class SplashScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Lottie.network(
          'https://lottie.host/6bbd4d3a-4e2d-46fc-b0a8-9cd05a954876/9qjylOBAvH.json',
          repeat: false,
          onLoaded: (c) {
            Future.delayed(
              c.duration,
                  () => Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const HomeScreen()),
              ),
            );
          },
        ),
      ),
    );
  }
}
