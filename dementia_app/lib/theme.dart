import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// New color palette
const Color kBlack = Color(0xFF000000);
const Color kWhite = Color(0xFFFFFFFF);
const Color kCeladon = Color(0xFFABE0AC);
const Color kLightGreen1 = Color(0xFF6DE371);
const Color kOlivine = Color(0xFF88BD8A);
const Color kLightGreen2 = Color(0xFF9AFC9D);
const Color kPalatinate = Color(0xFF6E1B6B);

// Light Theme
final ThemeData appLightTheme = ThemeData(
  brightness: Brightness.light,
  scaffoldBackgroundColor: kWhite,
  fontFamily: GoogleFonts.nunito().fontFamily,
  colorScheme: ColorScheme.light(
    primary: kOlivine,
    secondary: kCeladon,
    tertiary: kPalatinate,
    background: kWhite,
    surface: kLightGreen2,
    onPrimary: kBlack,
    onSecondary: kBlack,
    onBackground: kBlack,
    onSurface: kPalatinate,
  ),
  appBarTheme: AppBarTheme(
    backgroundColor: kCeladon,
    foregroundColor: kBlack,
  ),
  bottomAppBarTheme: BottomAppBarTheme(
    color: kLightGreen2,
  ),
  textTheme: GoogleFonts.nunitoTextTheme(
    ThemeData.light().textTheme,
  ).copyWith(
    bodyLarge: TextStyle(fontSize: 18, color: kPalatinate),
    bodyMedium: TextStyle(fontSize: 16, color: kBlack),
    labelLarge: TextStyle(
      letterSpacing: 1.5,
      fontWeight: FontWeight.bold,
      color: kPalatinate,
    ),
    displayLarge: TextStyle(
      fontWeight: FontWeight.bold,
      color: kLightGreen1,
    ),
    titleMedium: TextStyle(
      color: kOlivine,
    ),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: kLightGreen1,
      foregroundColor: kBlack,
      textStyle: const TextStyle(
        letterSpacing: 1,
        fontWeight: FontWeight.bold,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
    ),
  ),
  textButtonTheme: TextButtonThemeData(
    style: TextButton.styleFrom(
      foregroundColor: kPalatinate,
      textStyle: const TextStyle(
        fontWeight: FontWeight.w600,
      ),
    ),
  ),
);

// Dark Theme
final ThemeData appDarkTheme = ThemeData(
  brightness: Brightness.dark,
  scaffoldBackgroundColor: kBlack,
  fontFamily: GoogleFonts.poppins().fontFamily,
  colorScheme: ColorScheme.dark(
    primary: kPalatinate,
    secondary: kLightGreen1,
    tertiary: kLightGreen2,
    background: kBlack,
    surface: kOlivine,
    onPrimary: kWhite,
    onSecondary: kBlack,
    onBackground: kWhite,
    onSurface: kCeladon,
  ),
  appBarTheme: AppBarTheme(
    backgroundColor: kPalatinate,
    foregroundColor: kWhite,
  ),
  bottomAppBarTheme: BottomAppBarTheme(
    color: kOlivine,
  ),
  textTheme: GoogleFonts.robotoTextTheme(
    ThemeData.dark().textTheme,
  ).copyWith(
    bodyLarge: TextStyle(fontSize: 18, color: kCeladon),
    bodyMedium: TextStyle(fontSize: 16, color: kLightGreen2),
    labelLarge: TextStyle(
      letterSpacing: 1.5,
      fontWeight: FontWeight.bold,
      color: kLightGreen1,
    ),
    displayLarge: TextStyle(
      fontWeight: FontWeight.bold,
      color: kLightGreen2,
    ),
    titleMedium: TextStyle(
      color: kCeladon,
    ),
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: kPalatinate,
      foregroundColor: kWhite,
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
      foregroundColor: kLightGreen2,
      textStyle: const TextStyle(
        fontWeight: FontWeight.w600,
      ),
    ),
  ),
);