import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:material_ui/material_ui.dart';

abstract final class RelayTheme {
  static ThemeData get light => FlexThemeData.light(
    scheme: FlexScheme.indigo,
    useMaterial3: true,
    primary: const Color(0xFF5945A8),
    surface: const Color(0xFFF8F6F2),
    scaffoldBackground: const Color(0xFFF8F6F2),
    onSurface: const Color(0xFF172033),
    error: const Color(0xFFBA1A1A),
  );

  static ThemeData get dark => FlexThemeData.dark(
    scheme: FlexScheme.indigo,
    useMaterial3: true,
    primary: const Color(0xFFBDB1FF),
    primaryLightRef: const Color(0xFF5945A8),
    surface: const Color(0xFF101522),
    scaffoldBackground: const Color(0xFF101522),
    onSurface: const Color(0xFFF0F0F5),
    error: const Color(0xFFFFB4AB),
  );
}
