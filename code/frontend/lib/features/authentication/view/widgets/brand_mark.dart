import 'package:flutter/material.dart';

/// Theme-specific logo artwork, including the transparent light-mode mark.
class BrandMark extends StatelessWidget {
  const BrandMark({required this.dark, super.key});

  final bool dark;

  @override
  Widget build(BuildContext context) {
    final image = Image.asset(
      dark
          ? 'assets/auth/logo-0.png'
          : 'assets/auth/logo-light-transparent.png',
      width: 40,
      height: 40,
      semanticLabel: 'UniConnect logo',
    );
    if (dark) return image;

    // Match the visible artwork rather than the PNG canvas dimensions:
    // dark U: 214 / 256; light U: 801 / 1254 of the source width.
    // The light artwork is also slightly below the center of its canvas.
    return Transform.translate(
      offset: const Offset(-0.02, -0.54),
      child: Transform.scale(scale: 1.309, child: image),
    );
  }
}
