import 'package:flutter/material.dart';

import 'catalogue.dart';
import 'expeditions.dart';
import 'models.dart';
import 'store.dart';

enum SortBy {
  alphabetical('Alphabetical', 'A to Z', 'Z to A'),
  popularity('Popularity', 'Most popular', 'Least popular'),
  releaseDate('Release date', 'Oldest first', 'Newest first'),
  dateRated('Date rated', 'Recently rated', 'Oldest rated'),
  difficulty('Difficulty', 'Hardest first', 'Easiest first'),
  rating('Your rating', 'Highest rated', 'Lowest rated');

  final String label;
  final String firstWay; // first tap
  final String otherWay; // second tap
  const SortBy(this.label, this.firstWay, this.otherWay);
}

/// A chosen sort: which field, and whether it's reversed from its first tap.
class SortOrder {
  final SortBy by;
  final bool reversed;
  const SortOrder(this.by, {this.reversed = false});

  String get description => reversed ? by.otherWay : by.firstWay;

  /// Sorts albums. Albums without a value (no difficulty, not rated) always go last.
  List<Album> apply(List<Album> albums, Store store) {
    int byTitle(Album a, Album b) => Catalogue.norm(a.title).compareTo(Catalogue.norm(b.title));
    int compare(Album a, Album b) {
      switch (by) {
        case SortBy.alphabetical:
          final c = byTitle(a, b);
          return reversed ? -c : c;
        case SortBy.popularity:
          // Outside listening counts for now; the app's own rating counts later.
          var c = b.popularity.compareTo(a.popularity);
          if (c == 0) c = store.ratingCount(b.id).compareTo(store.ratingCount(a.id));
          return (reversed ? -c : c) != 0 ? (reversed ? -c : c) : byTitle(a, b);
        case SortBy.releaseDate:
          // Oldest first; albums without a date go last either way.
          final da = a.date ?? a.year, db = b.date ?? b.year;
          if (da == null && db == null) return byTitle(a, b);
          if (da == null) return 1;
          if (db == null) return -1;
          final c = da.compareTo(db);
          return (reversed ? -c : c) != 0 ? (reversed ? -c : c) : byTitle(a, b);
        case SortBy.dateRated:
          final ta = store.ratedAtOf(a.id), tb = store.ratedAtOf(b.id);
          if (ta == 0 && tb == 0) return byTitle(a, b);
          if (ta == 0) return 1;
          if (tb == 0) return -1;
          final c = tb.compareTo(ta); // most recent first
          return (reversed ? -c : c) != 0 ? (reversed ? -c : c) : byTitle(a, b);
        case SortBy.difficulty:
        case SortBy.rating:
          final va = by == SortBy.rating
              ? store.ratingOf(a.id)
              : difficultyOf(store, a.id)?.index.toDouble();
          final vb = by == SortBy.rating
              ? store.ratingOf(b.id)
              : difficultyOf(store, b.id)?.index.toDouble();
          if (va == null && vb == null) return byTitle(a, b);
          if (va == null) return 1;
          if (vb == null) return -1;
          final c = vb.compareTo(va); // highest first
          return (reversed ? -c : c) != 0 ? (reversed ? -c : c) : byTitle(a, b);
      }
    }

    return [...albums]..sort(compare);
  }
}

/// One sort button. Pick an option to sort by it; pick the same option again
/// to reverse it. The button always names the current order; [defaultLabel]
/// names the page's own order (null value), which is also the menu's first
/// option, so there is always a way back to it.
class SortButton extends StatelessWidget {
  final SortOrder? value;
  final String defaultLabel;
  final ValueChanged<SortOrder?> onChanged;
  const SortButton({
    super.key,
    required this.value,
    required this.onChanged,
    required this.defaultLabel,
  });

  @override
  Widget build(BuildContext context) {
    final v = value;
    return PopupMenuButton<SortBy?>(
      tooltip: 'Sort',
      onSelected: (by) => onChanged(
        by == null
            ? null
            : v != null && v.by == by
            ? SortOrder(by, reversed: !v.reversed)
            : SortOrder(by),
      ),
      itemBuilder: (_) => [
        PopupMenuItem<SortBy?>(
          value: null,
          child: Row(
            children: [
              Expanded(child: Text(defaultLabel)),
              if (v == null) const Icon(Icons.check, size: 18),
            ],
          ),
        ),
        const PopupMenuDivider(),
        for (final by in SortBy.values)
          PopupMenuItem<SortBy?>(
            value: by,
            child: Row(
              children: [
                Expanded(child: Text(by.label)),
                if (v?.by == by)
                  Text(v!.description, style: Theme.of(context).textTheme.labelSmall),
              ],
            ),
          ),
      ],
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 48, minWidth: 48),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.sort, size: 20),
              const SizedBox(width: 4),
              Text(
                v == null ? defaultLabel : v.description,
                style: Theme.of(context).textTheme.labelLarge,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
