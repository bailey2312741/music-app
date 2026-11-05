import 'dart:math' as math;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

import '../tokens/spacing.dart';

/// Sizes for portrait album cards, worked out from the space available and the
/// phone's text size, so cards are always exactly as tall as their content.
///
/// About three cards across on a phone, four on the 600 px web layout, and at
/// most two when text is 150% or larger so titles stay readable.
@immutable
class AlbumCardMetrics {
  /// Widest a card may be before another column is added.
  final double maxCardWidth;
  final TextScaler textScaler;

  /// Whether any card in the set shows a listening-stage tag or a caption.
  final bool withStage;
  final bool withCaption;

  const AlbumCardMetrics({
    this.maxCardWidth = defaultMaxWidth,
    this.textScaler = TextScaler.noScaling,
    this.withStage = false,
    this.withCaption = false,
  });

  static const defaultMaxWidth = 140.0;
  static const gap = AppSizes.albumCardGap; // between columns
  static const rowGap = AppSpace.md; // between rows
  static const coverGap = AppSpace.sm; // cover to title

  /// Smallest tap height of the stage tag row on a card.
  static const stageRowMin = 32.0;

  double _line(double fontSize, double lineHeight) =>
      textScaler.scale(fontSize) / fontSize * lineHeight;

  bool get largeText => textScaler.scale(10) >= 15;

  int columns(double width) {
    var n = ((width + gap) / (maxCardWidth + gap)).ceil();
    if (largeText) n = math.min(n, 2);
    return math.max(1, n);
  }

  double cardWidth(double width) {
    final n = columns(width);
    return (width - (n - 1) * gap) / n;
  }

  /// Height of a card [width] wide: cover, two title lines, artist line and
  /// any stage or caption row.
  double cardHeight(double width) {
    var h = width + coverGap + 2 * _line(15, 20) + AppSpace.xxs + _line(13, 19);
    if (withStage) h += AppSpace.xs + math.max(stageRowMin, _line(12, 17) + 8);
    if (withCaption) h += AppSpace.xxs + _line(12, 17);
    return h + AppSpace.xs; // breathing room under the last line
  }

  SliverGridDelegate delegate() => _AlbumGridDelegate(this);

  @override
  bool operator ==(Object other) =>
      other is AlbumCardMetrics &&
      other.maxCardWidth == maxCardWidth &&
      other.textScaler == textScaler &&
      other.withStage == withStage &&
      other.withCaption == withCaption;

  @override
  int get hashCode => Object.hash(maxCardWidth, textScaler, withStage, withCaption);
}

class _AlbumGridDelegate extends SliverGridDelegate {
  final AlbumCardMetrics m;
  const _AlbumGridDelegate(this.m);

  @override
  SliverGridLayout getLayout(SliverConstraints constraints) {
    final width = constraints.crossAxisExtent;
    final n = m.columns(width);
    final cardWidth = m.cardWidth(width);
    final height = m.cardHeight(cardWidth);
    return SliverGridRegularTileLayout(
      crossAxisCount: n,
      mainAxisStride: height + AlbumCardMetrics.rowGap,
      crossAxisStride: cardWidth + AlbumCardMetrics.gap,
      childMainAxisExtent: height,
      childCrossAxisExtent: cardWidth,
      reverseCrossAxis: axisDirectionIsReversed(constraints.crossAxisDirection),
    );
  }

  @override
  bool shouldRelayout(_AlbumGridDelegate old) => old.m != m;
}
