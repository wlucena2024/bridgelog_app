import 'package:flutter/material.dart';

ThemeData buildAppTheme() {
  final base = ThemeData.light();
  return base.copyWith(
    colorScheme: base.colorScheme.copyWith(
      primary: Colors.blue.shade800,
      secondary: Colors.orange.shade600,
    ),
    appBarTheme: const AppBarTheme(
      elevation: 0,
      centerTitle: true,
    ),
    scaffoldBackgroundColor: Colors.white,
  );
}
