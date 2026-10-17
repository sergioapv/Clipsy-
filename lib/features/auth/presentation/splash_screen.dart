import 'package:flutter/material.dart';

import '../../../core/widgets/clipsy_logo.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) => const Scaffold(
    body: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ClipsyLogo(),
          SizedBox(height: 32),
          CircularProgressIndicator(),
        ],
      ),
    ),
  );
}
