import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import 'album_screen.dart';
import 'catalogue.dart';
import 'charts.dart';
import 'details.dart';
import 'expedition_screens.dart';
import 'models.dart';
import 'search_screen.dart';
import 'song_screen.dart';
import 'store.dart';
import 'you_screen.dart';

/// The three tabs. Each keeps its own stack of pages, and the tab bar stays
/// on every page. Every page has its own web address, so the browser's back
/// button goes back one page.
const tabs = ['discover', 'expeditions', 'you'];

/// Counts taps on the tab that's already open, per tab, so the tab's first
/// page can scroll to the top (and, on Discover, clear the search).
final tabReselects = [for (final _ in tabs) ValueNotifier<int>(0)];

GoRouter buildRouter(Store store) {
  // Pages any tab can open, kept inside that tab.
  List<RouteBase> shared() => [
    GoRoute(
      path: 'album/:id',
      builder: (context, state) {
        final id = state.pathParameters['id']!;
        final album = Catalogue.byId(id) ?? store.albumById(id) ?? state.extra as Album?;
        if (album == null) return const _Missing('album');
        return AlbumScreen(
          store: store,
          album: album,
          expeditionId: state.uri.queryParameters['exp'],
        );
      },
      routes: [
        GoRoute(
          path: 'song/:tid',
          builder: (context, state) {
            final id = state.pathParameters['id']!;
            final tid = state.pathParameters['tid']!;
            final album = Catalogue.byId(id) ?? store.albumById(id);
            final track =
                state.extra as Track? ??
                store.trackInfo(tid) ??
                DetailsLoader.cached(id)?.tracks.where((t) => t.id == tid).firstOrNull;
            if (album == null || track == null) return const _Missing('song');
            return SongScreen(store: store, album: album, track: track);
          },
        ),
      ],
    ),
    GoRoute(
      path: 'artist/:name',
      builder: (context, state) =>
          ArtistScreen(store: store, artist: state.pathParameters['name']!),
    ),
    GoRoute(
      path: 'genre/:name',
      builder: (context, state) => GenreScreen(store: store, genre: state.pathParameters['name']!),
    ),
    GoRoute(
      path: 'chart/:kind',
      builder: (context, state) => ChartScreen(store: store, kind: state.pathParameters['kind']!),
    ),
  ];

  return GoRouter(
    initialLocation: '/discover',
    redirect: (context, state) => state.uri.path == '/' ? '/discover' : null,
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => HomeShell(shell: shell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/discover',
                builder: (context, state) => DiscoverScreen(store: store),
                routes: shared(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/expeditions',
                builder: (context, state) => ExpeditionListScreen(store: store),
                routes: [
                  ...shared(),
                  GoRoute(
                    path: 'new',
                    builder: (context, state) => CreateExpeditionScreen(store: store),
                  ),
                  GoRoute(
                    path: 'trail/:eid',
                    builder: (context, state) =>
                        ExpeditionScreen(store: store, expeditionId: state.pathParameters['eid']!),
                    routes: [
                      GoRoute(
                        path: 'edit',
                        builder: (context, state) {
                          final e = store.customExpeditions
                              .where((x) => x.id == state.pathParameters['eid'])
                              .firstOrNull;
                          return CreateExpeditionScreen(store: store, editing: e);
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/you',
                builder: (context, state) => YouScreen(store: store),
                routes: [
                  ...shared(),
                  GoRoute(path: 'about', builder: (context, state) => const AboutScreen()),
                  GoRoute(
                    path: 'range/:slot',
                    builder: (context, state) => RangePickerScreen(
                      store: store,
                      slot: int.tryParse(state.pathParameters['slot']!) ?? 0,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    ],
  );
}

class HomeShell extends StatelessWidget {
  final StatefulNavigationShell shell;
  const HomeShell({super.key, required this.shell});

  void _select(BuildContext context, int i) {
    if (i != shell.currentIndex) {
      shell.goBranch(i);
      return;
    }
    // Tapping the open tab: back to its first page, or if already there,
    // scroll up (a second tap on Discover also clears the search).
    final path = GoRouter.of(context).state.uri.path;
    if (path != '/${tabs[i]}') {
      shell.goBranch(i, initialLocation: true);
    } else {
      tabReselects[i].value++;
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      // Android back: pages pop first (handled by the router); on the first
      // page of Expeditions or You it goes to Discover, and only exits from there.
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        if (shell.currentIndex != 0) {
          shell.goBranch(0);
        } else {
          SystemNavigator.pop();
        }
      },
      child: Scaffold(
        body: shell,
        bottomNavigationBar: NavigationBar(
          selectedIndex: shell.currentIndex,
          onDestinationSelected: (i) => _select(context, i),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.explore_outlined),
              selectedIcon: Icon(Icons.explore),
              label: 'Discover',
            ),
            NavigationDestination(icon: Icon(Icons.hiking), label: 'Expeditions'),
            NavigationDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person),
              label: 'You',
            ),
          ],
        ),
      ),
    );
  }
}

class _Missing extends StatelessWidget {
  final String what;
  const _Missing(this.what);

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(),
    body: Center(child: Text("Couldn't find this $what.")),
  );
}

// ---------------------------------------------------------------- opening pages

/// The tab the user is in, so pages open inside it.
String _tab(BuildContext context) {
  final first = GoRouter.of(context).state.uri.pathSegments.firstOrNull;
  return tabs.contains(first) ? first! : 'discover';
}

String _enc(String s) => Uri.encodeComponent(s);

void openAlbum(BuildContext context, Store store, Album album, {String? expeditionId}) {
  final exp = expeditionId == null ? '' : '?exp=${_enc(expeditionId)}';
  context.push('/${_tab(context)}/album/${_enc(album.id)}$exp', extra: album);
}

/// Opens the next album of an expedition in place of the current page.
void replaceWithAlbum(BuildContext context, Album album, String expeditionId) {
  context.pushReplacement(
    '/${_tab(context)}/album/${_enc(album.id)}?exp=${_enc(expeditionId)}',
    extra: album,
  );
}

void openSong(BuildContext context, Store store, Album album, Track track) =>
    context.push('/${_tab(context)}/album/${_enc(album.id)}/song/${_enc(track.id)}', extra: track);

void openArtist(BuildContext context, String artist) =>
    context.push('/${_tab(context)}/artist/${_enc(artist)}');

void openGenre(BuildContext context, String genre) =>
    context.push('/${_tab(context)}/genre/${_enc(genre)}');

void openChart(BuildContext context, String kind) =>
    context.push('/${_tab(context)}/chart/${_enc(kind)}');

void openExpedition(BuildContext context, String id) =>
    context.push('/expeditions/trail/${_enc(id)}');
