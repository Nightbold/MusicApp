import 'dart:math';

import 'package:flutter/material.dart';

class Helper {
  static double calculateLuminance(Color color) {
    return 0.299 * color.red + 0.587 * color.green + 0.114 * color.blue;
  }

  static Color generateDarkColor() {
    Random random = Random();
    Color color;

    // Ensure the color is dark
    do {
      color = Color.fromRGBO(
        random.nextInt(256), // Red
        random.nextInt(256), // Green
        random.nextInt(256), // Blue
        1, // Opacity
      );
    } while (calculateLuminance(color) > 128);

    return color;
  }
}
