import 'package:flutter/material.dart';

import 'details.dart';
import 'models.dart';
import 'store.dart';

/// Adds or removes an album from Listen later, with a short confirmation.
Future<void> toggleListenLater(BuildContext context, Store store, Album album) async {
  final messenger = ScaffoldMessenger.of(context);
  final added = await store.toggleListenLater(album);
  _undoMessage(
    messenger,
    added ? 'Saved to Listen later' : 'Removed from Listen later',
    () => store.toggleListenLater(album),
  );
}

/// Pins an album to Your Range. When all five slots are full, asks which to replace.
Future<void> pinToRange(BuildContext context, Store store, Album album) async {
  if (store.isPinned(album.id)) {
    await store.unpin(album.id);
    return;
  }
  if (!store.rangeFull) {
    await store.pin(album);
    return;
  }
  final range = store.range;
  final slot = await showDialog<int>(
    context: context,
    builder: (c) => SimpleDialog(
      title: const Text('Your Range is full. Replace which album?'),
      children: [
        for (var i = 0; i < range.length; i++)
          SimpleDialogOption(
            onPressed: () => Navigator.pop(c, i),
            child: Text('${i + 1}. ${range[i]?.title ?? 'Empty'} · ${range[i]?.artist ?? ''}'),
          ),
      ],
    ),
  );
  if (slot != null) await store.pin(album, slot: slot);
}

/// The one Undo message style: short text, an Undo button, gone after
/// four seconds (long enough to reach Undo, short enough not to linger).
void _undoMessage(ScaffoldMessengerState messenger, String text, VoidCallback undo) {
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(text),
        duration: const Duration(seconds: 4),
        persist: false, // an Undo button would otherwise keep it on screen forever
        action: SnackBarAction(label: 'Undo', onPressed: undo),
      ),
    );
}

/// Removes an album rating, with a short "Rating removed. Undo" message.
Future<void> clearRating(BuildContext context, Store store, Album album) async {
  final messenger = ScaffoldMessenger.of(context);
  final old = store.ratingOf(album.id);
  if (old == null) return;
  final at = store.ratedAtOf(album.id);
  await store.rate(album, null);
  _undoMessage(messenger, 'Rating removed', () => store.rate(album, old, at: at));
}

/// Removes a song rating, with Undo.
Future<void> clearTrackRating(BuildContext context, Store store, Track track) async {
  final messenger = ScaffoldMessenger.of(context);
  final old = store.trackRatingOf(track.id);
  if (old == null) return;
  await store.rateTrack(track, null);
  _undoMessage(messenger, 'Rating removed', () => store.rateTrack(track, old));
}

/// Shows a message with Undo (Reset progress, Delete expedition).
void showUndo(BuildContext context, String text, VoidCallback undo) =>
    _undoMessage(ScaffoldMessenger.of(context), text, undo);

/// Same, when the page that asked may already be closed.
void showUndoOn(ScaffoldMessengerState messenger, String text, VoidCallback undo) =>
    _undoMessage(messenger, text, undo);
