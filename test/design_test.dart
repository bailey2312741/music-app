import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:music_app/catalogue.dart';
import 'package:music_app/design/design.dart';
import 'package:music_app/models.dart';
import 'package:music_app/page_parts.dart';
import 'package:music_app/screens.dart';
import 'package:music_app/store.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'brand_fonts.dart';

/// WCAG 2 contrast ratio between two opaque colours.
double contrast(Color a, Color b) {
  double lum(Color c) {
    double ch(double v) => v <= 0.04045 ? v / 12.92 : pow((v + 0.055) / 1.055, 2.4).toDouble();
    return 0.2126 * ch(c.r) + 0.7152 * ch(c.g) + 0.0722 * ch(c.b);
  }

  final la = lum(a), lb = lum(b);
  return (max(la, lb) + 0.05) / (min(la, lb) + 0.05);
}

Color hex(String h) => Color(int.parse('FF${h.substring(1)}', radix: 16));

void main() {
  final tokens =
      jsonDecode(File('design/design_tokens_v1.json').readAsStringSync()) as Map<String, dynamic>;
  final primitives = (tokens['primitives'] as Map)['colors'] as Map<String, dynamic>;
  final semantic = tokens['semantic'] as Map<String, dynamic>;

  test('Dart colours match design_tokens_v1.json exactly', () {
    expect(Palette.byName.keys.toSet(), primitives.keys.toSet());
    for (final e in primitives.entries) {
      expect(Palette.byName[e.key], hex(e.value as String), reason: e.key);
    }
    final roles = AppColors.dark.byName;
    expect(roles.keys.toSet(), semantic.keys.toSet());
    for (final e in semantic.entries) {
      expect(roles[e.key], Palette.byName[e.value], reason: e.key);
    }
  });

  test('type roles match design_tokens_v1.json', () {
    final roles = (tokens['typography'] as Map)['roles'] as Map<String, dynamic>;
    final dart = {
      'display': AppType.displayRole,
      'screenTitle': AppType.screenTitle,
      'sectionTitle': AppType.sectionTitle,
      'cardTitle': AppType.cardTitle,
      'body': AppType.body,
      'bodySmall': AppType.bodySmall,
      'label': AppType.label,
      'caption': AppType.caption,
      'score': AppType.score,
      'scoreSmall': AppType.scoreSmall,
    };
    expect(dart.keys.toSet(), roles.keys.toSet());
    for (final e in roles.entries) {
      final r = e.value as Map<String, dynamic>, s = dart[e.key]!;
      expect(s.fontFamily, r['family'], reason: e.key);
      expect(s.fontSize, r['size'], reason: e.key);
      expect(s.fontSize! * s.height!, closeTo((r['lineHeight'] as num).toDouble(), 0.001));
      expect(s.fontWeight!.value, r['weight'], reason: e.key);
      expect(s.letterSpacing, r['letterSpacing'], reason: e.key);
      expect(s.fontFeatures?.isNotEmpty ?? false, r.containsKey('features'), reason: e.key);
    }
  });

  test('sizes and motion match design_tokens_v1.json', () {
    final p = tokens['primitives'] as Map<String, dynamic>;
    final spacing = p['spacing'] as Map<String, dynamic>;
    expect([
      AppSpace.zero,
      AppSpace.xxs,
      AppSpace.xs,
      AppSpace.sm,
      AppSpace.md,
      AppSpace.lg, //
      AppSpace.xl, AppSpace.xxl, AppSpace.xxxl, AppSpace.huge,
    ], spacing.values.map((v) => (v as num).toDouble()).toList());
    final radii = p['radii'] as Map<String, dynamic>;
    expect([
      AppRadii.none,
      AppRadii.xs,
      AppRadii.sm,
      AppRadii.md,
      AppRadii.lg,
      AppRadii.xl,
      AppRadii.full,
    ], radii.values.map((v) => (v as num).toDouble()).toList());
    final covers = p['covers'] as Map<String, dynamic>;
    expect(AppCoverSizes.xl, covers['xl']);
    expect(AppCoverSizes.hero(360), closeTo(201.6, 1e-9));
    expect(AppCoverSizes.hero(300), 200);
    expect(AppCoverSizes.hero(600), 240);
    final sizes = p['sizes'] as Map<String, dynamic>;
    expect(AppSizes.bottomNavHeight, sizes['bottomNavHeightExcludingSafeInset']);
    expect(AppSizes.ratingBarHeight, sizes['fixedRatingBarHeight']);
    expect(AppSizes.ratingValueWidth, sizes['ratingValueWidth']);
    final motion = p['motion'] as Map<String, dynamic>;
    final dart = {
      'press': AppMotion.press,
      'ratingValue': AppMotion.ratingValue,
      'fade': AppMotion.fade,
      'coverReveal': AppMotion.coverReveal,
      'hero': AppMotion.hero,
      'screen': AppMotion.screen,
      'trail': AppMotion.trail,
      'rangePeak': AppMotion.rangePeak,
      'completeMoment': AppMotion.completeMoment,
    };
    for (final e in dart.entries) {
      expect(e.value.duration.inMilliseconds, (motion[e.key] as Map)['durationMs'], reason: e.key);
    }
  });

  test('text colours meet WCAG contrast on the surfaces they sit on', () {
    final c = AppColors.dark;
    // Normal text needs 4.5:1.
    for (final (fg, bg, name) in [
      (c.textPrimary, c.page, 'primary on page'),
      (c.textPrimary, c.chrome, 'primary on chrome'),
      (c.textPrimary, c.surfaceRaised, 'primary on raised'),
      (c.textPrimary, c.surfaceSelected, 'primary on selected'),
      (c.textSecondary, c.page, 'secondary on page'),
      (c.textSecondary, c.surfaceRaised, 'secondary on raised'),
      (c.textSecondary, c.surfaceSelected, 'secondary on selected'),
      (c.textTertiary, c.page, 'tertiary on page'),
      (c.textTertiary, c.surfaceRaised, 'tertiary on raised'),
      (c.primaryButtonText, c.primaryButtonFill, 'button text on cream'),
      (c.ratingFill, c.chrome, 'mint (Undo) on chrome'),
      (c.error, c.page, 'error on page'),
      (c.warning, c.page, 'warning on page'),
    ]) {
      expect(contrast(fg, bg), greaterThanOrEqualTo(4.5), reason: name);
    }
    // Control edges and slider fills need 3:1.
    expect(contrast(c.lineFunctional, c.page), greaterThanOrEqualTo(3));
    expect(contrast(c.ratingFill, c.ratingTrack), greaterThanOrEqualTo(3));
    // Figures quoted in the spec.
    expect(contrast(c.textPrimary, c.page), closeTo(12.87, 0.05));
    expect(contrast(c.textPrimary, c.chrome), closeTo(14.21, 0.05));
  });

  testWidgets('reduced motion turns motion tokens off', (t) async {
    late MotionToken normal, reduced;
    await t.pumpWidget(
      Builder(
        builder: (context) {
          normal = AppMotion.fade.resolve(context);
          return MediaQuery(
            data: const MediaQueryData(disableAnimations: true),
            child: Builder(
              builder: (context) {
                reduced = AppMotion.fade.resolve(context);
                return const SizedBox();
              },
            ),
          );
        },
      ),
    );
    expect(normal.duration, const Duration(milliseconds: 180));
    expect(reduced.duration, Duration.zero);
  });

  testWidgets('the app still works with the brand theme', _clickThrough);

  // With the real Inter and Outfit fonts loaded, nothing overflows on phone
  // widths. (The default test font is much wider than Inter.)
  // Also at 130% and 200% system text size.
  for (final width in [360.0, 412.0, 600.0]) {
    for (final scale in [1.0, 1.3, 2.0]) {
      testWidgets('no overflow with the brand fonts at $width wide, ${scale * 100}% text', (
        t,
      ) async {
        await loadBrandFonts();
        t.view.devicePixelRatio = 1;
        t.view.physicalSize = Size(width, 800);
        t.platformDispatcher.textScaleFactorTestValue = scale;
        addTearDown(t.view.reset);
        addTearDown(t.platformDispatcher.clearTextScaleFactorTestValue);
        await _clickThrough(t);
      });
    }
  }
}

Future<void> _clickThrough(WidgetTester t) async {
  SharedPreferences.setMockInitialValues({});
  Catalogue.use(const [
    Album(id: 'k1', title: 'Kind of Blue', artist: 'Miles Davis', year: '1959', genre: 'Jazz'),
  ]);
  final store = await Store.load();
  final theme = AppTheme.dark();
  expect(theme.extension<AppColors>(), AppColors.dark);
  expect(theme.colorScheme.surface, Palette.forest800);
  await t.pumpWidget(MaterialApp.router(theme: theme, routerConfig: buildRouter(store)));
  await t.pumpAndSettle();
  expect(find.text('Popular'), findsOneWidget);
  await t.enterText(find.byType(TextField), 'kind of blue');
  await t.pumpAndSettle();
  await t.tap(find.text('Kind of Blue').last);
  await t.pumpAndSettle();
  expect(find.byType(RatingBar), findsOneWidget);
  expect(t.getSize(find.byType(NavigationBar)).height, AppSizes.bottomNavHeight);
  await store.rate(Catalogue.byId('k1')!, 8);
  await t.pumpAndSettle();
  await t.tap(find.text('tap to clear'));
  await t.pumpAndSettle();
  expect(store.ratingOf('k1'), isNull);
  await t.tap(find.text('Undo'));
  await t.pumpAndSettle();
  expect(store.ratingOf('k1'), 8);
  for (final tab in ['Expeditions', 'You', 'Discover']) {
    await t.tap(find.text(tab).last);
    await t.pumpAndSettle();
  }
  expect(t.takeException(), isNull);
}
