import 'package:flutter/material.dart';

import 'catalogue.dart';
import 'design/design.dart';
import 'nav.dart';
import 'store.dart';
import 'widgets.dart';

/// Number of ratings, yours and the average in one quiet row (album and
/// song pages).
class RatingSummary extends StatelessWidget {
  final int count;
  final double? yours, average;
  const RatingSummary({super.key, required this.count, this.yours, this.average});

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    Widget cell(String value, String label, String spoken, {bool empty = false}) => Expanded(
      child: Semantics(
        container: true,
        label: spoken,
        excludeSemantics: true,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: AppSpace.sm, horizontal: AppSpace.xs),
          child: Column(
            children: [
              Text(
                value,
                style: AppType.score.copyWith(
                  fontSize: 18,
                  color: empty ? c.textTertiary : c.textPrimary,
                ),
              ),
              Text(
                label,
                textAlign: TextAlign.center,
                style: AppType.caption.copyWith(color: c.textSecondary),
              ),
            ],
          ),
        ),
      ),
    );
    Widget rule() => Container(width: 1, height: 28, color: c.lineDecorative);
    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(color: c.lineDecorative),
        borderRadius: BorderRadius.circular(AppRadii.card),
      ),
      child: Row(
        children: [
          cell(
            '$count',
            count == 1 ? 'rating' : 'ratings',
            '$count ${count == 1 ? 'rating' : 'ratings'}',
          ),
          rule(),
          cell(
            yours == null ? '–' : formatScore(yours!),
            'yours',
            yours == null ? 'You have not rated it' : 'Your rating ${formatScore(yours!)}',
            empty: yours == null,
          ),
          rule(),
          cell(
            average == null ? '–' : formatScore(average!),
            'average',
            average == null ? 'No average yet' : 'Average ${formatScore(average!)}',
            empty: average == null,
          ),
        ],
      ),
    );
  }
}

/// The artist's name with a small round picture; opens the artist page.
class ArtistButton extends StatelessWidget {
  final Store store;
  final String artist;
  const ArtistButton({super.key, required this.store, required this.artist});

  @override
  Widget build(BuildContext context) {
    final known = Catalogue.byArtist(artist).isNotEmpty;
    final c = AppColors.of(context);
    // A text link with the artist's small picture. Long names wrap rather
    // than being cut off.
    return TextButton.icon(
      style: TextButton.styleFrom(
        foregroundColor: c.textPrimary,
        disabledForegroundColor: c.textSecondary,
        padding: const EdgeInsets.symmetric(horizontal: AppSpace.md, vertical: AppSpace.xs),
      ),
      onPressed: known ? () => openArtist(context, artist) : null,
      icon: ArtistAvatar(image: Catalogue.artistImage(artist), size: 24),
      label: Text(
        artist,
        textAlign: TextAlign.center,
        semanticsLabel: known ? 'Artist: $artist. Open artist page' : 'Artist: $artist',
        style: AppType.cardTitle,
      ),
    );
  }
}

/// A rating slider in a bottom sheet (used for tracks). Saves when you let go.
Future<void> showRatingSheet(
  BuildContext context, {
  required String title,
  required double? current,
  required Future<void> Function(double? score) onSave,
}) {
  return showModalBottomSheet<void>(
    context: context,
    builder: (c) {
      var draft = current;
      return StatefulBuilder(
        builder: (c, setSheet) => Padding(
          padding: const EdgeInsets.fromLTRB(AppSpace.xl, AppSpace.lg, AppSpace.xl, AppSpace.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                title,
                style: AppType.sectionTitle.copyWith(color: AppColors.of(c).textPrimary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: AppSpace.sm),
              ExcludeSemantics(child: ScoreText(draft, scale: 1.5)),
              RatingSlider(
                value: draft,
                noun: 'song',
                onChanged: (v) => setSheet(() => draft = v),
                // Saves and closes in one move.
                onChangeEnd: (v) {
                  onSave(v);
                  Navigator.pop(c);
                },
              ),
              if (current != null || draft != null)
                TextButton(
                  onPressed: () {
                    onSave(null);
                    Navigator.pop(c);
                  },
                  child: const Text('Remove rating'),
                ),
            ],
          ),
        ),
      );
    },
  );
}

/// Your review of an album or song, with likes, comments and report buttons.
/// Everything stays on the phone until there are online accounts.
class ReviewSection extends StatelessWidget {
  final Store store;
  final String subject; // "album:ID" or "track:ID"
  const ReviewSection({super.key, required this.store, required this.subject});

  Future<void> _edit(BuildContext context) async {
    final existing = store.reviewOf(subject);
    final controller = TextEditingController(text: existing?.text ?? '');
    // null: cancelled. Empty text removes the review (the Delete button).
    final text = await showDialog<String>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(existing == null ? 'Write a review' : 'Edit your review'),
        content: TextField(
          controller: controller,
          autofocus: true,
          minLines: 4,
          maxLines: 10,
          maxLength: 2000,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(
            hintText: 'What did you think?',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          if (existing != null)
            TextButton(
              style: TextButton.styleFrom(foregroundColor: AppColors.of(c).error),
              onPressed: () => Navigator.pop(c, ''),
              child: const Text('Delete'),
            ),
          TextButton(onPressed: () => Navigator.pop(c), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(c, controller.text),
            child: const Text('Post'),
          ),
        ],
      ),
    );
    if (text != null) await store.saveReview(subject, text);
  }

  Future<void> _comment(BuildContext context) async {
    final controller = TextEditingController();
    final text = await showDialog<String>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Add a comment'),
        content: TextField(
          controller: controller,
          autofocus: true,
          minLines: 2,
          maxLines: 4,
          maxLength: 500,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(border: OutlineInputBorder()),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(c, controller.text),
            child: const Text('Post'),
          ),
        ],
      ),
    );
    if (text != null) await store.addComment(subject, text);
  }

  Future<void> _report(BuildContext context, {int? comment}) async {
    const reasons = ['Spam', 'Hateful or abusive', 'Spoilers or off-topic', 'Something else'];
    final reason = await showDialog<String>(
      context: context,
      builder: (c) => SimpleDialog(
        title: Text(comment == null ? 'Report this review' : 'Report this comment'),
        children: [
          for (final r in reasons) DialogChoice(title: r, onTap: () => Navigator.pop(c, r)),
          const DialogCancel(),
        ],
      ),
    );
    if (reason == null || !context.mounted) return;
    await store.report(subject, reason, comment: comment);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text('Reported. Thanks for letting us know.'),
          duration: Duration(seconds: 2),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final review = store.reviewOf(subject);
    final who = store.nickname.isEmpty ? 'You' : store.nickname;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SectionHeader(
          'Reviews',
          padding: EdgeInsets.zero,
          trailing: TextButton.icon(
            onPressed: () => _edit(context),
            icon: Icon(
              review == null ? Icons.rate_review_outlined : Icons.edit_outlined,
              size: AppIconSizes.small,
            ),
            label: Text(review == null ? 'Write a review' : 'Edit'),
          ),
        ),
        if (review == null)
          Text('No reviews yet.', style: AppType.bodySmall.copyWith(color: c.textSecondary))
        else
          DecoratedBox(
            decoration: BoxDecoration(
              color: c.surfaceRaised,
              borderRadius: BorderRadius.circular(AppRadii.card),
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpace.lg,
                AppSpace.md,
                AppSpace.xs,
                AppSpace.xs,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$who · ${_ago(review.at)}',
                    style: AppType.caption.copyWith(color: c.textSecondary),
                  ),
                  const SizedBox(height: AppSpace.xs),
                  Padding(
                    padding: const EdgeInsets.only(right: AppSpace.md),
                    child: Text(review.text, style: AppType.body.copyWith(color: c.textPrimary)),
                  ),
                  Row(
                    children: [
                      TextButton.icon(
                        style: TextButton.styleFrom(foregroundColor: c.textSecondary),
                        onPressed: () => store.toggleLike(subject),
                        icon: Icon(
                          review.liked ? Icons.favorite : Icons.favorite_border,
                          size: AppIconSizes.small,
                          color: review.liked ? c.textPrimary : null,
                        ),
                        label: Text(
                          '${review.liked ? 1 : 0}',
                          semanticsLabel: review.liked ? 'Liked' : 'Like',
                        ),
                      ),
                      TextButton.icon(
                        style: TextButton.styleFrom(foregroundColor: c.textSecondary),
                        onPressed: () => _comment(context),
                        icon: const Icon(Icons.chat_bubble_outline, size: AppIconSizes.small),
                        label: Text(
                          '${review.comments.length}',
                          semanticsLabel: 'Comment, ${review.comments.length} so far',
                        ),
                      ),
                      const Spacer(),
                      _ReportButton(reported: review.reported, onPressed: () => _report(context)),
                    ],
                  ),
                  for (var i = 0; i < review.comments.length; i++)
                    Container(
                      margin: const EdgeInsets.only(left: AppSpace.xs, bottom: AppSpace.sm),
                      padding: const EdgeInsets.only(left: AppSpace.md),
                      decoration: BoxDecoration(
                        border: Border(
                          left: BorderSide(
                            color: c.lineFunctional,
                            width: AppSizes.indicatorBorderWidth,
                          ),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(top: AppSpace.xs),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '$who · ${_ago(review.comments[i].at)}',
                                    style: AppType.caption.copyWith(color: c.textSecondary),
                                  ),
                                  Text(
                                    review.comments[i].text,
                                    style: AppType.bodySmall.copyWith(color: c.textPrimary),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          _ReportButton(
                            reported: review.comments[i].reported,
                            small: true,
                            onPressed: () => _report(context, comment: i),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _ReportButton extends StatelessWidget {
  final bool reported;
  final bool small;
  final VoidCallback onPressed;
  const _ReportButton({required this.reported, required this.onPressed, this.small = false});

  @override
  Widget build(BuildContext context) => IconButton(
    tooltip: reported ? 'Reported' : 'Report',
    // A smaller icon on comments, but the same 48 px tap area.
    iconSize: small ? AppIconSizes.small : AppIconSizes.regular,
    onPressed: reported ? null : onPressed,
    icon: Icon(reported ? Icons.flag : Icons.outlined_flag),
  );
}

String _ago(int ms) {
  final d = DateTime.now().difference(DateTime.fromMillisecondsSinceEpoch(ms));
  if (d.inMinutes < 1) return 'just now';
  if (d.inHours < 1) return '${d.inMinutes} min ago';
  if (d.inDays < 1) return '${d.inHours} hr ago';
  if (d.inDays < 30) return '${d.inDays} ${d.inDays == 1 ? 'day' : 'days'} ago';
  final t = DateTime.fromMillisecondsSinceEpoch(ms);
  return '${t.day}/${t.month}/${t.year}';
}

/// The rating bar fixed to the bottom of album and song pages, so the slider
/// is always in the same place. Unrated: a grey track with the thumb parked
/// at the left and a dash; the first touch sets the value (0 is a real
/// rating). Saves when you let go. Tap the number to clear it (with Undo).
/// [next] (expeditions) sits under it.
class RatingBar extends StatefulWidget {
  final double? saved;
  final Future<void> Function(double score) onSave;
  final VoidCallback onClear;
  final Widget? next;

  /// What is being rated, for screen readers: "album" or "song".
  final String noun;
  const RatingBar({
    super.key,
    required this.saved,
    required this.onSave,
    required this.onClear,
    this.next,
    this.noun = 'album',
  });

  @override
  State<RatingBar> createState() => _RatingBarState();
}

class _RatingBarState extends State<RatingBar> with SingleTickerProviderStateMixin {
  late double? _draft = widget.saved;
  bool _dragging = false;

  /// A short settle of the number when a rating is saved (120 ms).
  late final _settle = AnimationController(
    vsync: this,
    duration: AppMotion.ratingValue.duration,
    value: 1,
  );
  late final Animation<double> _scale = Tween(
    begin: 1.08,
    end: 1.0,
  ).animate(CurvedAnimation(parent: _settle, curve: AppMotion.ratingValue.curve));

  @override
  void dispose() {
    _settle.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(RatingBar old) {
    super.didUpdateWidget(old);
    if (!_dragging) _draft = widget.saved;
  }

  @override
  Widget build(BuildContext context) {
    final c = AppColors.of(context);
    final saved = widget.saved;
    final score = Semantics(
      button: saved != null,
      label: saved == null
          ? 'Not rated yet'
          : 'Your rating ${formatScore(saved)} out of 10. Tap to clear',
      excludeSemantics: true,
      onTap: saved == null ? null : widget.onClear,
      child: InkWell(
        onTap: saved == null ? null : widget.onClear,
        borderRadius: BorderRadius.circular(AppRadii.card),
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            minWidth: AppSizes.ratingValueWidth,
            minHeight: AppSizes.ratingBarHeight - 2 * AppSpace.xs,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ScaleTransition(scale: _scale, child: ScoreText(_draft)),
              if (saved != null)
                Text(
                  'tap to clear',
                  softWrap: false,
                  style: AppType.caption.copyWith(color: c.textTertiary),
                ),
            ],
          ),
        ),
      ),
    );
    return DecoratedBox(
      decoration: BoxDecoration(
        color: c.chrome,
        border: Border(top: BorderSide(color: c.lineDecorative)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          // Wide side padding keeps the thumb away from Android's back-swipe edge.
          padding: const EdgeInsets.fromLTRB(
            AppSpace.lg,
            AppSpace.xs,
            AppSpace.xl - 4,
            AppSpace.xs,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  score,
                  const SizedBox(width: AppSpace.xs),
                  Expanded(
                    child: RatingSlider(
                      value: _draft,
                      noun: widget.noun,
                      onChangeStart: (_) => _dragging = true,
                      onChanged: (v) => setState(() => _draft = v),
                      onChangeEnd: (v) async {
                        // Show exactly what is saved, even if the last move
                        // arrived without its own frame.
                        setState(() {
                          _dragging = false;
                          _draft = v;
                        });
                        if (!AppMotion.reduced(context)) _settle.forward(from: 0);
                        await widget.onSave(v);
                      },
                    ),
                  ),
                ],
              ),
              ?widget.next,
            ],
          ),
        ),
      ),
    );
  }
}
