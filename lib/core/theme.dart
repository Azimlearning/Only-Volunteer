import 'package:flutter/material.dart';

// Figma color palette - KitaHack 2026
const Color figmaOrange = Color(0xFFFF691C);
const Color figmaPurple = Color(0xFF8100DE);
const Color figmaBlack = Color(0xFF333333);

// Page layout (Figma-inspired)
const double kPagePadding = 24.0;
const double kCardRadius = 12.0;
const double kHeaderTitleSize = 22.0;
const double kHeaderSubtitleSize = 14.0;

final ThemeData appTheme = ThemeData(
  useMaterial3: true,
  colorScheme: ColorScheme.fromSeed(
    seedColor: figmaOrange,
    brightness: Brightness.light,
    primary: figmaOrange,
    secondary: figmaPurple,
    surface: Colors.white,
    onPrimary: Colors.white,
    onSecondary: Colors.white,
  ),
  appBarTheme: const AppBarTheme(
    centerTitle: false,
    elevation: 0,
    backgroundColor: Colors.white,
    foregroundColor: figmaBlack,
    titleTextStyle: TextStyle(
      color: figmaBlack,
      fontSize: 20,
      fontWeight: FontWeight.bold,
    ),
  ),
  cardTheme: CardThemeData(
    elevation: 2,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  ),
  inputDecorationTheme: InputDecorationTheme(
    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
    filled: true,
    fillColor: Colors.grey[50],
  ),
  filledButtonTheme: FilledButtonThemeData(
    style: FilledButton.styleFrom(
      backgroundColor: figmaOrange,
      foregroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ),
  ),
  outlinedButtonTheme: OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      foregroundColor: figmaPurple,
      side: const BorderSide(color: figmaPurple),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
    ),
  ),
);
