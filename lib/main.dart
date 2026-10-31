import 'package:flutter/material.dart';

import 'catalogue.dart';
import 'screens.dart';
import 'store.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final store = await Store.load();
  await Catalogue.load();
  runApp(MusicApp(store: store));
}

class MusicApp extends StatelessWidget {
  final Store store;
  const MusicApp({super.key, required this.store});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Music App',
      theme: ThemeData(colorSchemeSeed: Colors.teal, useMaterial3: true),
      home: HomeShell(store: store),
    );
  }
}
