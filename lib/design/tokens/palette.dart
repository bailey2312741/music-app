import 'package:flutter/painting.dart';

/// Raw brand colours from design/design_tokens_v1.json (`primitives.colors`).
///
/// Screens and widgets should not use these directly. Use the semantic roles
/// in [AppColors] (or the Material [ColorScheme] built from them) instead, so
/// every colour decision lives in one place.
abstract final class Palette {
  static const forest900 = Color(0xFF0F2423);
  static const forest800 = Color(0xFF172C2B); // canonical brand forest
  static const forest700 = Color(0xFF24403C);
  static const forest650 = Color(0xFF304D48);
  static const paper50 = Color(0xFFF3F0E7); // canonical warm off-white
  static const paper200 = Color(0xFFC4D1CC);
  static const paper300 = Color(0xFFAABDB5);
  static const borderSubtle = Color(0xFF557C71);
  static const borderFunctional = Color(0xFF76968B);
  static const mint200 = Color(0xFFB6E0C6);
  static const amber200 = Color(0xFFF6D48C);
  static const coral200 = Color(0xFFF4B7B1);
  static const ink = Color(0xFF0F2423);

  /// Every primitive by its token name, for tests that compare against the JSON.
  static const byName = <String, Color>{
    'forest900': forest900,
    'forest800': forest800,
    'forest700': forest700,
    'forest650': forest650,
    'paper50': paper50,
    'paper200': paper200,
    'paper300': paper300,
    'borderSubtle': borderSubtle,
    'borderFunctional': borderFunctional,
    'mint200': mint200,
    'amber200': amber200,
    'coral200': coral200,
    'ink': ink,
  };
}
