import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:music_app/design/design.dart';
import 'package:music_app/difficulty.dart';

Widget _app(Widget child) => MaterialApp(
  theme: AppTheme.dark(),
  home: Scaffold(body: Center(child: child)),
);

void main() {
  test('every listening stage has a large and a compact drawing', () {
    for (final d in Difficulty.values) {
      for (final (large, box) in [(true, 64), (false, 24)]) {
        final file = File(StageIcon.asset(d.icon, large: large));
        expect(file.existsSync(), isTrue, reason: file.path);
        final svg = file.readAsStringSync();
        expect(svg, contains('viewBox="0 0 $box $box"'), reason: file.path);
        // One colour only, so the theme can recolour it.
        final colours = RegExp(r'#[0-9A-Fa-f]{6}').allMatches(svg).map((m) => m[0]).toSet();
        expect(colours, {'#F3F0E7'}, reason: file.path);
      }
    }
  });

  testWidgets('stage icons and badges render', (t) async {
    await t.pumpWidget(
      _app(
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (final d in Difficulty.values) ...[
              StageIcon(d.icon, size: 64),
              DifficultyTag(d),
              DifficultyTag(d, small: true),
            ],
            DifficultySquare(Difficulty.summit, onTap: () {}),
          ],
        ),
      ),
    );
    await t.pumpAndSettle();
    expect(find.text('HIGH ALTITUDE'), findsWidgets);
    expect(find.text('Summit'), findsOneWidget);
    expect(t.takeException(), isNull);
  });

  testWidgets('a tappable stage badge has a 48 px tap area', (t) async {
    var taps = 0;
    await t.pumpWidget(_app(StageBadge(name: 'summit', label: 'Summit', onTap: () => taps++)));
    expect(t.getSize(find.byType(InkWell)).height, greaterThanOrEqualTo(48));
    await t.tap(find.byType(StageBadge));
    expect(taps, 1);
  });

  testWidgets('genre buttons: 48 px tall, text only, selected state for screen readers', (t) async {
    String? picked;
    await t.pumpWidget(
      _app(
        StatefulBuilder(
          builder: (context, setState) => Wrap(
            children: [
              for (final g in ['Rock', 'R&B & Soul', 'Experimental & Ambient'])
                GenreButton(
                  g,
                  selected: g == picked,
                  onPressed: () => setState(() => picked = g == picked ? null : g),
                ),
              const GenreButton('Other'), // disabled
            ],
          ),
        ),
      ),
    );
    for (final b in t.widgetList<GenreButton>(find.byType(GenreButton))) {
      expect(t.getSize(find.byWidget(b)).height, greaterThanOrEqualTo(48));
    }
    expect(find.byType(Icon), findsNothing);
    expect(find.text('R&B & SOUL'), findsOneWidget);

    await t.tap(find.text('ROCK'));
    await t.pumpAndSettle();
    expect(picked, 'Rock');
    expect(
      t.getSemantics(find.byType(GenreButton).first),
      matchesSemantics(
        label: 'Rock',
        isButton: true,
        hasSelectedState: true,
        isSelected: true,
        hasEnabledState: true,
        isEnabled: true,
        isFocusable: true,
        hasTapAction: true,
        hasFocusAction: true,
      ),
    );
    // Tapping the selected genre again clears it.
    await t.tap(find.text('ROCK'));
    await t.pumpAndSettle();
    expect(picked, isNull);
    // The disabled button does nothing.
    await t.tap(find.text('OTHER'));
    expect(picked, isNull);
  });
}
