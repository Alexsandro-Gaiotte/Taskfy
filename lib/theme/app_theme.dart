import 'package:flutter/material.dart';

class AppTheme {
  // New Dark Neon Wallet Palette
  static const Color backgroundDark = Color(0xFF191919); // Muted dark background
  static const Color cardColor = Color(0xFF242424); // Slightly lighter for cards
  static const Color primaryNeon = Color(0xFF820AD1); // Nubank Primary Purple
  static const Color secondaryNeon = Color(0xFF2CB1F5); // Light Blue for gradients
  static const Color activeGreen = Color(0xFF00FF7F); // Bright Green for success
  static const Color textWhite = Color(0xFFFFFFFF);
  static const Color textBody =
      Color(0xFFA0AEC0); // Soft gray for secondary text

  static final ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    fontFamily: 'Inter',
    scaffoldBackgroundColor: backgroundDark,
    colorScheme: ColorScheme.dark(
      primary: primaryNeon,
      secondary: secondaryNeon,
      surface: cardColor,
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      iconTheme: IconThemeData(color: textWhite),
      titleTextStyle: TextStyle(
        color: textWhite,
        fontSize: 20,
        fontWeight: FontWeight.w600,
        fontFamily: 'Inter',
      ),
      centerTitle: true,
    ),
  );

  // Purple to Blue top gradient
  static const LinearGradient topHeaderGradient = LinearGradient(
    colors: [
      Color(0xFF820AD1), // Nubank Purple
      Color(0xFFA25BDB), // Lighter Purple
      Color(0xFF2CB1F5), // Light Blue
    ],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    stops: [0.0, 0.4, 1.0],
  );

  static const LinearGradient buttonGradient = LinearGradient(
    colors: [
      Color(0xFF820AD1), // Nubank Purple
      Color(0xFF2CB1F5), // Light Blue
    ],
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
  );
}
