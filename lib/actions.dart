import 'package:flutter/material.dart';

import 'models.dart';
import 'store.dart';

/// Adds or removes an album from Listen later, with a short confirmation.
Future<void> toggleListenLater(BuildContext context, Store store, Album album) async {
  final messenger = ScaffoldMessenger.of(context);
  final added = await store.toggleListenLater(album);
  messenger
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(added ? 'Saved to Listen later' : 'Removed from Listen later'),
        duration: const Duration(seconds: 2),
        action: SnackBarAction(label: 'Undo', onPressed: () => store.toggleListenLater(album)),
      ),
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
