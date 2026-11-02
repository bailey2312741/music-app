import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'catalogue.dart';
import 'screens.dart';
import 'store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Every page gets its own web address, so the browser's back button goes back one page.
  GoRouter.optionURLReflectsImperativeAPIs = true;
  final store = await Store.load();
  await Catalogue.load();
  await store.applyAliases(Catalogue.aliases);
  runApp(MusicApp(store: store));
}

class MusicApp extends StatefulWidget {
  final Store store;
  const MusicApp({super.key, required this.store});

  @override
  State<MusicApp> createState() => _MusicAppState();
}

class _MusicAppState extends State<MusicApp> {
  late final _router = buildRouter(widget.store);

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = ThemeData(colorSchemeSeed: Colors.teal, useMaterial3: true);
    return MaterialApp.router(
      title: 'Music App',
      theme: theme,
      routerConfig: _router,
      // On a wide screen (the web on a computer) the app stays phone-width, centred.
      builder: (context, child) => ColoredBox(
        color: theme.colorScheme.surfaceContainerLow,
        child: Center(
          child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: 600), child: child),
        ),
      ),
    );
  }
}
