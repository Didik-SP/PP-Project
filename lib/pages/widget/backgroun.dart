import 'package:flutter/material.dart';

class BackgroundWrapper extends StatelessWidget {
  final Widget child;

  const BackgroundWrapper({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Gambar background fullscreen
        Positioned.fill(
          child: Image.asset(
            'assets/images/background.png',
            fit: BoxFit.cover,
          ),
        ),
        // Konten halaman
        Positioned.fill(
          child: Container(
            color: Colors.black.withOpacity(0.3), // optional: overlay gelap
            child: child,
          ),
        ),
      ],
    );
  }
}
