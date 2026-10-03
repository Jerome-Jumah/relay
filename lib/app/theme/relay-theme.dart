import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';

abstract final class RelayTheme {
  static final light = FlexThemeData.light(
    scheme: FlexScheme.indigo,
    useMaterial3: true,
    primary: const Color(0xFF5945A8),
    surface: const Color(0xFFF8F6F2),
    scaffoldBackground: const Color(0xFFF8F6F2),
    onSurface: const Color(0xFF172033),
    error: const Color(0xFFBA1A1A),
    materialTapTargetSize: MaterialTapTargetSize.padded,
  );

  static final dark = FlexThemeData.dark(
    scheme: FlexScheme.indigo,
    useMaterial3: true,
    primary: const Color(0xFFBDB1FF),
    primaryLightRef: const Color(0xFF5945A8),
    surface: const Color(0xFF101522),
    scaffoldBackground: const Color(0xFF101522),
    onSurface: const Color(0xFFF0F0F5),
    error: const Color(0xFFFFB4AB),
    materialTapTargetSize: MaterialTapTargetSize.padded,
  );
}
