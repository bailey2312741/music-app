import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import 'catalogue.dart';
import 'design/design.dart';
import 'screens.dart';
import 'store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Every page gets its own web address, so the browser's back button goes back one page.
  GoRouter.optionURLReflectsImperativeAPIs = true;
  _registerFontLicences();
  final store = await Store.load();
  await Catalogue.load();
  await store.applyAliases(Catalogue.aliases);
  runApp(MusicApp(store: store));
}

/// The bundled fonts' licences, shown on Flutter's licences page.
void _registerFontLicences() {
  LicenseRegistry.addLicense(() async* {
    for (final (font, path) in [
      ('Inter', 'assets/fonts/inter/OFL.txt'),
      ('Outfit', 'assets/fonts/outfit/OFL.txt'),
    ]) {
      yield LicenseEntryWithLineBreaks([font], await rootBundle.loadString(path));
    }
  });
}

class MusicApp extends StatefulWidget {
  final Store store;
  const MusicApp({super.key, required this.store});

  @override
  State<MusicApp> createState() => _MusicAppState();
}

class _MusicAppState extends State<MusicApp> {
  late final _router = buildRouter(widget.store);
  static final _theme = AppTheme.dark();

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Music App',
      theme: _theme,
      routerConfig: _router,
      // On a wide screen (the web on a computer) the app stays phone-width, centred.
      builder: (context, child) => ColoredBox(
        color: AppColors.dark.chrome,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: AppBreakpoints.webMaxWidth),
            child: child,
          ),
        ),
      ),
    );
  }
}
