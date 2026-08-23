import 'package:flutter/material.dart';

/// NodeLoc 品牌配色（提取自 www.nodeloc.com 官方主题）
/// 暗色: scheme_8 (#12100D / #1E1A15 / 绿 #118A53 / 橙 #C14924)
/// 亮色: scheme_7 (#FFFFFF / #222222 / 绿 #009966 / 橙 #FF9933)
class NL {
  // 品牌色
  static const Color greenDark = Color(0xFF118A53);
  static const Color greenLight = Color(0xFF009966);
  static const Color orangeDark = Color(0xFFC14924);
  static const Color orangeLight = Color(0xFFFF9933);
  static const Color love = Color(0xFFFA6C8D);
  static const Color dangerDark = Color(0xFFE45735);
  static const Color dangerLight = Color(0xFFC80001);

  // 暗色主题
  static const Color darkBg = Color(0xFF12100D);
  static const Color darkSurface = Color(0xFF1E1A15);
  static const Color darkElevated = Color(0xFF282219);
  static const Color darkText = Color(0xFFD5D5D5);
  static const Color darkTextMuted = Color(0xFF948D82);

  // 亮色主题
  static const Color lightBg = Color(0xFFF7F5F2);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightText = Color(0xFF222222);
  static const Color lightTextMuted = Color(0xFF777269);

  static ThemeData dark() {
    final scheme = ColorScheme.dark(
      primary: greenDark,
      onPrimary: Colors.white,
      secondary: orangeDark,
      onSecondary: Colors.white,
      surface: darkSurface,
      onSurface: darkText,
      surfaceContainerHighest: darkElevated,
      onSurfaceVariant: darkTextMuted,
      error: dangerDark,
    );
    return _base(scheme).copyWith(
      scaffoldBackgroundColor: darkBg,
      appBarTheme: const AppBarTheme(
        backgroundColor: darkBg,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: darkText,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
        iconTheme: IconThemeData(color: darkText),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: darkSurface,
        indicatorColor: greenDark.withOpacity(0.25),
        labelTextStyle: const WidgetStatePropertyAll(
          TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600),
        ),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: darkSurface,
        indicatorColor: greenDark.withOpacity(0.25),
        selectedIconTheme: const IconThemeData(color: Color(0xFF35C481)),
        selectedLabelTextStyle: const TextStyle(
          color: Color(0xFF35C481),
          fontWeight: FontWeight.w700,
        ),
      ),
      dividerTheme: const DividerThemeData(color: Color(0xFF2C261E), thickness: 0.7),
      popupMenuTheme: const PopupMenuThemeData(color: darkElevated),
      dialogTheme: const DialogThemeData(backgroundColor: darkSurface),
    );
  }

  static ThemeData light() {
    final scheme = ColorScheme.light(
      primary: greenLight,
      onPrimary: Colors.white,
      secondary: orangeLight,
      onSecondary: Colors.white,
      surface: lightSurface,
      onSurface: lightText,
      surfaceContainerHighest: lightBg,
      onSurfaceVariant: lightTextMuted,
      error: dangerLight,
    );
    return _base(scheme).copyWith(
      scaffoldBackgroundColor: lightBg,
      appBarTheme: const AppBarTheme(
        backgroundColor: lightBg,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: lightText,
          fontSize: 18,
          fontWeight: FontWeight.w700,
        ),
        iconTheme: IconThemeData(color: lightText),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: lightSurface,
        indicatorColor: greenLight.withOpacity(0.18),
        labelTextStyle: const WidgetStatePropertyAll(
          TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600),
        ),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: lightSurface,
        indicatorColor: greenLight.withOpacity(0.18),
        selectedLabelTextStyle: const TextStyle(
          color: greenLight,
          fontWeight: FontWeight.w700,
        ),
      ),
      dividerTheme: const DividerThemeData(color: Color(0xFFEAE5DE), thickness: 0.7),
      popupMenuTheme: const PopupMenuThemeData(color: lightSurface),
      dialogTheme: const DialogThemeData(backgroundColor: lightSurface),
    );
  }

  static ThemeData _base(ColorScheme scheme) {
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      fontFamilyFallback: const [
        'PingFang SC',
        'Microsoft YaHei',
        'Noto Sans SC',
        'sans-serif',
      ],
      cardTheme: CardThemeData(
        color: scheme.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: scheme.surfaceContainerHighest,
        side: BorderSide.none,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: scheme.surfaceContainerHighest,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 20),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        ),
      ),
      snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
      listTileTheme: const ListTileThemeData(
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      ),
    );
  }
}
