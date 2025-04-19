import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

final ThemeData appTheme = ThemeData(
  brightness: Brightness.dark,
  scaffoldBackgroundColor: Colors.black,
  fontFamily: GoogleFonts.poppins().fontFamily,
  colorScheme: const ColorScheme.dark().copyWith(
    primary: Colors.blueAccent,
    secondary: Colors.purpleAccent,
  ),
  bottomAppBarTheme: const BottomAppBarTheme(
    color: Colors.black87,
  ),
  textTheme: GoogleFonts.robotoTextTheme(
    ThemeData.light().textTheme,
  ).copyWith(
    bodyLarge: const TextStyle(fontSize: 18),
    bodyMedium: const TextStyle(fontSize: 16),
    labelLarge: const TextStyle(
      letterSpacing: 1.5,
      fontWeight: FontWeight.bold,
    ),
    displayLarge: const TextStyle(
      fontWeight: FontWeight.bold,
    ),
    titleMedium: const TextStyle(
      color: Colors.grey,
    ),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: Colors.blueAccent,
      foregroundColor: Colors.white,
      textStyle: const TextStyle(
        letterSpacing: 1.5,
        fontWeight: FontWeight.bold,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
  ),
  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(
      foregroundColor: Colors.purpleAccent,
      textStyle: const TextStyle(
        fontWeight: FontWeight.w600,
      ),
    ),
  ),
);
