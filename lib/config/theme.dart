import 'package:flutter/material.dart';

class AppTheme {
  static const Color primaryColor = Color(0xFF1877F2);  // Facebook 블루 색상(웹사이트와 동일)
  static const Color secondaryColor = Color(0xFF42B72A); // Facebook 그린 색상
  static const Color backgroundColor = Color(0xFFF0F2F5); // 배경색
  static const Color errorColor = Color(0xFFE74C3C);      // 에러 메시지 색상
  static const Color warningColor = Color(0xFFF39C12);    // 경고 색상
  static const Color textPrimaryColor = Color(0xFF1C1E21); // 기본 텍스트 색상
  static const Color textSecondaryColor = Color(0xFF606770); // 보조 텍스트 색상
  static const Color dividerColor = Color(0xFFDADDE1);    // 구분선 색상
  static const Color cardColor = Colors.white;            // 카드 색상

  // 텍스트 스타일
  static const TextStyle titleLarge = TextStyle(
    fontSize: 24, 
    fontWeight: FontWeight.bold,
    color: textPrimaryColor,
  );
  
  static const TextStyle titleMedium = TextStyle(
    fontSize: 20, 
    fontWeight: FontWeight.bold,
    color: textPrimaryColor,
  );

  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16, 
    fontWeight: FontWeight.normal,
    color: textPrimaryColor,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14, 
    fontWeight: FontWeight.normal,
    color: textPrimaryColor,
  );

  static const TextStyle bodySmall = TextStyle(
    fontSize: 12, 
    fontWeight: FontWeight.normal,
    color: textSecondaryColor,
  );

  static const TextStyle buttonText = TextStyle(
    fontSize: 16, 
    fontWeight: FontWeight.bold,
    color: Colors.white,
  );

  static const TextStyle linkText = TextStyle(
    fontSize: 14, 
    fontWeight: FontWeight.normal,
    color: primaryColor,
    decoration: TextDecoration.none,
  );

  // 테마 데이터
  static ThemeData lightTheme = ThemeData(
    primaryColor: primaryColor,
    scaffoldBackgroundColor: backgroundColor,
    cardColor: cardColor,
    colorScheme: const ColorScheme.light(
      primary: primaryColor,
      secondary: secondaryColor,
      error: errorColor,
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.white,
      elevation: 1,
      iconTheme: IconThemeData(color: primaryColor),
      titleTextStyle: TextStyle(
        color: textPrimaryColor,
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        foregroundColor: Colors.white,
        backgroundColor: primaryColor,
        textStyle: buttonText,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6),
        ),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        elevation: 0,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: primaryColor,
        side: const BorderSide(color: dividerColor),
        textStyle: buttonText.copyWith(color: primaryColor),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6),
        ),
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: primaryColor,
        textStyle: linkText,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(6),
        ),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: const BorderSide(color: dividerColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: const BorderSide(color: dividerColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: const BorderSide(color: primaryColor, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(6),
        borderSide: const BorderSide(color: errorColor),
      ),
      hintStyle: bodyMedium.copyWith(color: textSecondaryColor.withOpacity(0.7)),
      errorStyle: bodySmall.copyWith(color: errorColor),
    ),
    dividerTheme: const DividerThemeData(
      thickness: 1,
      color: dividerColor,
    ),
    cardTheme: CardTheme(
      color: cardColor,
      elevation: 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    ),
    checkboxTheme: CheckboxThemeData(
      checkColor: MaterialStateProperty.all(Colors.white),
      fillColor: MaterialStateProperty.all(primaryColor),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(4),
      ),
    ),
  );
}