import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

class LottieLoader extends StatelessWidget {
  final double? width;
  final double? height;

  const LottieLoader({super.key, this.width = 200, this.height = 200});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Lottie.asset(
        'assets/animations/loader.json',
        width: width,
        height: height,
        fit: BoxFit.contain,
        repeat: true,
        frameRate: FrameRate.max,
      ),
    );
  }
}
