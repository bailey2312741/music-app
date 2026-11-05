import 'dart:io';

import 'package:flutter/services.dart';

/// Loads the bundled Inter and Outfit so widget tests measure text like the
/// app does. (The default test font is much wider than Inter.)
Future<void> loadBrandFonts() async {
  for (final (family, files) in [
    ('Inter', ['Regular', 'Medium', 'SemiBold', 'Bold']),
    ('Outfit', ['Bold', 'ExtraBold']),
  ]) {
    final loader = FontLoader(family);
    for (final f in files) {
      final bytes = File('assets/fonts/${family.toLowerCase()}/$family-$f.ttf').readAsBytesSync();
      loader.addFont(Future.value(ByteData.sublistView(bytes)));
    }
    await loader.load();
  }
}
