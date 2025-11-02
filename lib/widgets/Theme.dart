import 'package:flutter/material.dart';

class MyTheme {
  static final ThemeData themeData = ThemeData(
      primaryColor: Colors.blue,
      colorScheme:
          ColorScheme.dark(background: Colors.black, primary: Colors.green),
      fontFamily: 'Roboto',
      elevatedButtonTheme: ElevatedButtonThemeData(
          style: ButtonStyle(
              // minimumSize: MaterialStatePropertyAll(Size(337, 49)),
              shape: MaterialStatePropertyAll(StadiumBorder(
                  side: BorderSide(color: Colors.white, width: 1))),
              backgroundColor: MaterialStatePropertyAll(Colors.black),
              foregroundColor: MaterialStatePropertyAll(Colors.white))),
      outlinedButtonTheme: OutlinedButtonThemeData(
          style: ButtonStyle(
              minimumSize: MaterialStatePropertyAll(Size(337, 49)),
              foregroundColor: MaterialStatePropertyAll(Colors.black),
              backgroundColor:
                  MaterialStatePropertyAll(Color.fromARGB(200, 30, 215, 96)),
              shape: MaterialStatePropertyAll(StadiumBorder(
                  side: BorderSide(
                color: Colors.white,
                width: 1,
              ))))));

  static ThemeData getTheme() {
    return themeData;
  }
}
