import 'package:material_ui/material_ui.dart';

class AppTheme {
  static const Color deepGreen = Color(0xFF0F5132);
  static const Color green = Color(0xFF198754);

  static ThemeData _build(Brightness b) {
    final scheme = ColorScheme.fromSeed(
      seedColor: green,
      primary: b == Brightness.light ? deepGreen : green,
      brightness: b,
    );
    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
    );
  }

  static ThemeData get light => _build(Brightness.light);
  static ThemeData get dark => _build(Brightness.dark);
}
