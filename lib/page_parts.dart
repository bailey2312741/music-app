import 'package:flutter/material.dart';

import 'catalogue.dart';
import 'nav.dart';
import 'store.dart';
import 'widgets.dart';

/// Ratings count, your rating and the average, stacked in a narrow column.
class RatingStats extends StatelessWidget {
  final int count;
  final double? yours;
  final double? average;
  const RatingStats({super.key, required this.count, this.yours, this.average});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    Widget stat(String value, String label) => Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Column(
        children: [
          Text(value, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
          Text(label, style: theme.textTheme.labelSmall),
        ],
      ),
    );
    return SizedBox(
      width: 64,
      child: Column(
        children: [
          stat('$count', count == 1 ? 'rating' : 'ratings'),
          stat(yours == null ? '–' : fmt(yours!), 'yours'),
          stat(average == null ? '–' : fmt(average!), 'average'),
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
    return ActionChip(
      avatar: ArtistAvatar(image: Catalogue.artistImage(artist), size: 24),
      label: Text(artist, overflow: TextOverflow.ellipsis),
      visualDensity: VisualDensity.compact,
      onPressed: known ? () => openArtist(context, artist) : null,
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
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(title, style: Theme.of(c).textTheme.titleMedium, textAlign: TextAlign.center),
              const SizedBox(height: 8),
              Text(draft == null ? '–' : fmt(draft!), style: Theme.of(c).textTheme.displaySmall),
              Slider(
                value: draft ?? 0,
                min: 0,
                max: 10,
                divisions: 20,
                label: draft == null ? null : fmt(draft!),
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
    final controller = TextEditingController(text: store.reviewOf(subject)?.text ?? '');
    final text = await showDialog<String>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Your review'),
        content: TextField(
          controller: controller,
          autofocus: true,
          minLines: 4,
          maxLines: 10,
          maxLength: 2000,
          textCapitalization: TextCapitalization.sentences,
          decoration: const InputDecoration(hintText: 'What did you think?'),
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
          maxLines: 4,
          maxLength: 500,
          textCapitalization: TextCapitalization.sentences,
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
          for (final r in reasons)
            SimpleDialogOption(onPressed: () => Navigator.pop(c, r), child: Text(r)),
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
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final review = store.reviewOf(subject);
    final who = store.nickname.isEmpty ? 'You' : store.nickname;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: Text('Reviews', style: theme.textTheme.titleMedium)),
            TextButton.icon(
              onPressed: () => _edit(context),
              icon: Icon(review == null ? Icons.rate_review_outlined : Icons.edit, size: 18),
              label: Text(review == null ? 'Write a review' : 'Edit'),
            ),
          ],
        ),
        if (review == null)
          Text('No reviews yet.', style: theme.textTheme.bodySmall)
        else
          Card(
            margin: EdgeInsets.zero,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 6, 6),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$who · ${_ago(review.at)}',
                    style: theme.textTheme.labelMedium?.copyWith(color: scheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 6),
                  Text(review.text, style: theme.textTheme.bodyMedium),
                  Row(
                    children: [
                      TextButton.icon(
                        onPressed: () => store.toggleLike(subject),
                        icon: Icon(
                          review.liked ? Icons.favorite : Icons.favorite_border,
                          size: 18,
                          color: review.liked ? Colors.red.shade600 : null,
                        ),
                        label: Text('${review.liked ? 1 : 0}'),
                      ),
                      TextButton.icon(
                        onPressed: () => _comment(context),
                        icon: const Icon(Icons.chat_bubble_outline, size: 18),
                        label: Text('${review.comments.length}'),
                      ),
                      const Spacer(),
                      _ReportButton(reported: review.reported, onPressed: () => _report(context)),
                    ],
                  ),
                  for (var i = 0; i < review.comments.length; i++)
                    Container(
                      margin: const EdgeInsets.only(left: 12, bottom: 6),
                      padding: const EdgeInsets.only(left: 10),
                      decoration: BoxDecoration(
                        border: Border(left: BorderSide(color: scheme.outlineVariant, width: 2)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '$who · ${_ago(review.comments[i].at)}',
                                  style: theme.textTheme.labelSmall?.copyWith(
                                    color: scheme.onSurfaceVariant,
                                  ),
                                ),
                                Text(review.comments[i].text, style: theme.textTheme.bodySmall),
                              ],
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
    visualDensity: small ? VisualDensity.compact : null,
    iconSize: small ? 16 : 20,
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
/// at the left and a dash; the first touch sets the value. Saves when you let
/// go. Tap the number to clear it. [next] (expeditions) sits under it.
class RatingBar extends StatefulWidget {
  final double? saved;
  final Future<void> Function(double score) onSave;
  final VoidCallback onClear;
  final Widget? next;
  const RatingBar({
    super.key,
    required this.saved,
    required this.onSave,
    required this.onClear,
    this.next,
  });

  @override
  State<RatingBar> createState() => _RatingBarState();
}

class _RatingBarState extends State<RatingBar> {
  late double? _draft = widget.saved;
  bool _dragging = false;

  @override
  void didUpdateWidget(RatingBar old) {
    super.didUpdateWidget(old);
    if (!_dragging) _draft = widget.saved;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final unrated = _draft == null;
    return Material(
      color: scheme.surfaceContainer,
      child: SafeArea(
        top: false,
        child: Padding(
          // Wide side padding keeps the thumb away from Android's back-swipe edge.
          padding: const EdgeInsets.fromLTRB(20, 6, 20, 6),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: widget.saved == null ? null : widget.onClear,
                    child: SizedBox(
                      width: 72,
                      height: 60,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              unrated ? '–' : fmt(_draft!),
                              style: theme.textTheme.headlineSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: unrated ? scheme.outline : null,
                              ),
                            ),
                            if (widget.saved != null)
                              Text(
                                'tap to clear',
                                style: theme.textTheme.labelSmall?.copyWith(color: scheme.outline),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  Expanded(
                    child: SliderTheme(
                      data: unrated
                          ? SliderTheme.of(context).copyWith(
                              activeTrackColor: scheme.outlineVariant,
                              inactiveTrackColor: scheme.outlineVariant,
                              thumbColor: scheme.outline,
                            )
                          : SliderTheme.of(context),
                      child: Slider(
                        value: _draft ?? 0,
                        min: 0,
                        max: 10,
                        divisions: 20,
                        label: unrated ? null : fmt(_draft!),
                        onChangeStart: (_) => _dragging = true,
                        onChanged: (v) => setState(() => _draft = v),
                        onChangeEnd: (v) async {
                          _dragging = false;
                          await widget.onSave(v);
                        },
                      ),
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
