import 'package:flutter/material.dart';

import 'actions.dart';
import 'catalogue.dart';
import 'difficulty.dart';
import 'expeditions.dart';
import 'models.dart';
import 'search_screen.dart';
import 'store.dart';
import 'widgets.dart';

void openAlbum(BuildContext context, Store store, Album album) {
  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => AlbumScreen(store: store, album: album),
    ),
  );
}

class AlbumScreen extends StatefulWidget {
  final Store store;
  final Album album;
  const AlbumScreen({super.key, required this.store, required this.album});

  @override
  State<AlbumScreen> createState() => _AlbumScreenState();
}

class _AlbumScreenState extends State<AlbumScreen> {
  late double? _draft = widget.store.ratingOf(widget.album.id);

  @override
  Widget build(BuildContext context) {
    final store = widget.store;
    final a = Catalogue.byId(widget.album.id) ?? widget.album;
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(),
      body: ListenableBuilder(
        listenable: store,
        builder: (context, _) {
          final saved = store.ratingOf(a.id);
          final difficulty = difficultyOf(store, a.id);
          final average = store.averageOf(a.id);
          final count = store.ratingCount(a.id);
          // Studio is the default, so the type is only worth showing when it's something else.
          final meta = [
            a.year,
            if (a.type != null && a.type != 'Studio') a.type,
          ].whereType<String>().join(' · ');

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
            children: [
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 300),
                  child: Cover(album: a, radius: 12, large: true),
                ),
              ),
              if (difficulty != null) ...[
                const SizedBox(height: 12),
                Center(child: DifficultySquare(difficulty)),
              ],
              const SizedBox(height: 16),
              Text(
                a.title,
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 4),
              Center(
                child: InkWell(
                  borderRadius: BorderRadius.circular(6),
                  onTap: Catalogue.byArtist(a.artist).isEmpty
                      ? null
                      : () => Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => ArtistScreen(store: store, artist: a.artist),
                          ),
                        ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    child: Text(a.artist, style: theme.textTheme.titleMedium),
                  ),
                ),
              ),
              if (meta.isNotEmpty)
                Text(
                  meta,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall?.copyWith(color: scheme.onSurfaceVariant),
                ),
              // Main genre larger and on top, subgenres smaller underneath.
              if (a.genre != null) ...[
                const SizedBox(height: 12),
                Center(
                  child: Chip(label: Text(a.genre!, style: theme.textTheme.titleSmall)),
                ),
              ],
              if (a.subgenres.isNotEmpty) ...[
                const SizedBox(height: 6),
                Wrap(
                  alignment: WrapAlignment.center,
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    for (final t in a.subgenres)
                      Chip(
                        label: Text(t, style: theme.textTheme.labelSmall),
                        visualDensity: VisualDensity.compact,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                  ],
                ),
              ],
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextButton.icon(
                    onPressed: () => toggleListenLater(context, store, a),
                    icon: Icon(
                      store.isListenLater(a.id) ? Icons.bookmark : Icons.bookmark_add_outlined,
                    ),
                    label: Text(store.isListenLater(a.id) ? 'Saved for later' : 'Listen later'),
                  ),
                  TextButton.icon(
                    onPressed: () => pinToRange(context, store, a),
                    icon: Icon(store.isPinned(a.id) ? Icons.landscape : Icons.landscape_outlined),
                    label: Text(store.isPinned(a.id) ? 'In Your Range' : 'Add to Your Range'),
                  ),
                ],
              ),
              const Divider(height: 24),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        Text('Your rating', style: theme.textTheme.labelLarge),
                        Text(
                          _draft == null ? '–' : fmt(_draft!),
                          style: theme.textTheme.headlineLarge,
                        ),
                        Text(
                          saved == null ? 'Slide to rate' : 'Saved',
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        Text('Average', style: theme.textTheme.labelLarge),
                        Text(
                          average == null ? '–' : fmt(average),
                          style: theme.textTheme.headlineLarge,
                        ),
                        Text(
                          count == 0
                              ? 'No ratings yet'
                              : '$count ${count == 1 ? 'rating' : 'ratings'}',
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              // Saves as soon as you let go of the slider.
              Slider(
                value: _draft ?? 5,
                min: 0,
                max: 10,
                divisions: 20,
                label: fmt(_draft ?? 5),
                onChanged: (v) => setState(() => _draft = v),
                onChangeEnd: (v) => store.rate(a, v),
              ),
            ],
          );
        },
      ),
    );
  }
}
