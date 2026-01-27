import 'package:flutter/material.dart';

class KConstants {
  static const String themeModeKey = 'themeModeKey'; //key for dark mode
}

class KTextStyle {
  static const TextStyle titleTealText = TextStyle(
    color: Color.fromARGB(255, 27, 84, 78),
    fontSize: 20.0,
    fontWeight: FontWeight.bold, //main title
  );

  static const TextStyle descriptionText = TextStyle(
    fontSize: 13.5, //description text
    color: Color.fromARGB(255, 144, 149, 150),
  );
}

class Symbols {
  static Widget get vegSymbol => const Stack(
    alignment: Alignment.center,
    children: [
      Icon(Icons.crop_square_sharp, color: Colors.green, size: 36),
      Icon(Icons.circle, color: Colors.green, size: 14),
    ],
  );

  static Widget get nonVegSymbol => const Stack(
    alignment: Alignment.center,
    children: [
      Icon(Icons.crop_square_sharp, color: Colors.red, size: 36),
      Icon(Icons.circle, color: Colors.red, size: 14),
    ],
  );

  // Distinct Jain symbol: green square with a yellow dot
  static Widget get jainSymbol => const Stack(
    alignment: Alignment.center,
    children: [
      Icon(Icons.crop_square_sharp, color: Colors.green, size: 36),
      Icon(Icons.circle, color: Colors.amber, size: 14),
    ],
  );
}
