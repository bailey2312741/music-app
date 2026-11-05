# Changelog

## v0.9.0: Expeditions redesign (Phases A to E)
The whole app now uses the Expeditions design: dark forest green, Outfit and Inter, custom stage icons, shared album cards and the redesigned Discover, album, Expeditions, You, artist, genre, chart, song and expedition editor screens.

Phase E, motion and polish:
- Your Range peaks rise from the empty slot to their stage height when an album is added, and sink back when it is removed (Undo raises it again). Ratings never move a peak.
- The expedition trail's travelled path grows to the next stop after a rating is saved, the Next Stop label moves with it, the trail scrolls to reveal the new stop if it is off screen, and a completed expedition gets a check on its final stop. Progress bars fill smoothly.
- Album covers fly from the tapped card into the album page and back.
- One short fade-and-slide page transition everywhere.
- The rating number settles when saved; phones give a light tick per half point and on save.
- Bookmarks swap with a quick scale; unlocking a stop brightens it.
- Every animation is off when the system asks for reduced motion.

## Unreleased: stage icons and genre buttons (Phase B)
- Four new listening-stage drawings (Base Camp tent, Foothills hills and sun, High Altitude jagged range, Summit peak with trail and flag), each in a detailed and a compact version, replace the old difficulty icons everywhere.
- Genres in the Discover chip row are text-only buttons. Tap again to clear, as before.

## Phase A: Expeditions design foundation
- New dark forest-green brand theme from design/DESIGN_SYSTEM_V1.md, built from tokens in lib/design/.
- Outfit (headings) and Inter (everything else) fonts bundled, with their open font licences.
- Album cards are a few pixels taller so the new fonts fit. No features, data or navigation changed.

## v0.8
Change numbers match the v0.8 wish list.

**1. Bailey's items**
- 1.1 Release date sort: "Release date" is in every Sort menu (oldest first, tap again for newest first). It is the default on artist pages only.
- 1.2 Clearing a rating: tap the big number in the rating bar (a faint "tap to clear" shows under it while rated), swipe a rated album sideways in the Rated list, or swipe a rated track on the album page. Each shows "Rating removed" with Undo. Clearing never relocks expedition albums.
- 1.3 Artist pages scroll all the way down: the last less-known releases sit fully above the tab bar (checked on The Beatles in the web version).

**2. Rating flow**
- 2.1 The rating bar is fixed at the bottom of every album and song page.
- 2.2 Unrated: grey track, thumb at the far left and a dash. The first touch sets the value. The expedition rating works the same way.
- 2.3 The track rating sheet saves and closes when you let go.
- 2.4 After rating an album opened from an expedition, the rating bar shows "Next: [album]".

**3. Carried over**
- 3.1 Your Range peaks show your rating on each cover.
- 3.2 Tapping an empty Your Range slot opens your rated albums, highest first, with a search box.
- 3.3 The expedition trail scrolls sideways, keeping the zig-zag, the solid and dashed line and the bigger final stop. It opens at your next stop.

**4. Menu and navigation**
- 4.1 Chart chips under the search bar: Popular, Top rated (your own ratings for now, and it says so), Hardest (expedition albums only for now, and it says so) and one per decade. Each opens a numbered list.
- 4.2 The tab bar stays on every page.
- 4.3 Every page has its own web address, so the browser's back button goes back one page. On Android, back on Expeditions or You goes to Discover first, then exits.
- 4.4 "Date rated" added to Sort. The Sort button always names the order in use ("Recently rated", "Most popular", "Oldest first") and its menu has the default at the top to go back to.
- 4.5 Every album card shows a bookmark for Listen later. New empty-list text.
- 4.6 Tap the open tab to go back to its first page and scroll to the top; tap again on Discover to clear the search. The search bar is pinned at the top with an x.
- 4.7 "Continue" card at the top of Expeditions: the next album of the expedition you were last on, opening its page with the rating bar ready.
- 4.8 Tapping a difficulty tag or square shows what the level means in a short line at the bottom.
- 4.9 Reset progress is in the menu on the expedition header, with Undo instead of a confirmation. Deleting your own expedition also has Undo now.
- 4.10 Sort, the track Rate buttons and the card bookmark are all at least 44 px.
- 4.11 An empty Rated list has a "Find albums" button that opens Discover.
- 4.12 Tab names and page titles match: Discover, Expeditions, You.
- 4.13 "New expedition" is a + in the Expeditions header.
- 4.14 "Rated by me" chip in Discover.
- 4.15 On a computer the app is capped at 600 px wide, centred.
- 4.16 Same as 3.2.
- 4.17 Menu Option A: three tabs (Discover opens first, Expeditions, You). Profile and Ratings are merged into You (nickname, Your Range, then Rated / Listen later / Reviews, About at the bottom). Both corner icons are gone; the nickname is edited in place instead of in a pop-up.

## v0.7.1 (bug fixes)
- Fixed wrong album data: 26 albums from Bailey's rankings pointed at the wrong MusicBrainz entry (The Bends pointed at the 1996 single). They now use the real album, and any ratings, reviews or saves you made on the old entry move across automatically.
- Removed 931 bootlegs (unofficial live recordings and rarities) from the library, which now has 9,120 albums. Every album also has its full release date.
- Artist pages: releases played far less than the artist's best-known album are tucked into a "Less-known releases" section at the bottom, closed until you tap Show. Rated albums and albums from Bailey's rankings always show.
- Album pages reuse the cover already loaded for the card, so it appears instantly. The tracklist shows the track count straight away where known.
- Every library change is now checked automatically against a list of known albums (data/known_albums.json). If a check fails, the change isn't published.

## v0.7
- Album page redesign: cover on the left, with the title, type and track count beside it and an artist button with a small round picture (for now, the artist's most popular cover). Ratings count, your rating and the average sit on the right.
- Tracklist on every album page, with each track's length and average. Tap "Rate" to rate a track right from the list.
- Song pages: tap a track to open it. It looks like the album page but with a round cover, a "Song" label and a link back to its album, and has its own rating, chart and reviews.
- Mountain rating chart: the rating spread is drawn as a mountain range, with snow and a flag on the highest peak. A temporary "Test" button fills it with made-up ratings to preview the look.
- Release date (month, day, year), total duration and record label under the chart. Tracklists and these facts load from MusicBrainz the first time you open an album, then stay saved on the phone.
- Reviews on albums and songs, with like, comment and report buttons. This is a test version: everything stays on your phone and the totals only count your own ratings until online accounts exist.
- Artist pages: studio albums first, oldest to newest and shown bigger, then EPs, mixtapes, live albums, soundtracks and other releases below in smaller cards.
- Faster covers: on the phone, covers are saved after the first load so they show instantly next time, and artist cards use smaller images.
- Fixed: the "Saved to Listen later" banner now disappears after two seconds.

## v0.6
- First real library: about 10,000 of the most listened-to albums, plus every album from Bailey's rankings and the expeditions. It ships inside the app, so search is still instant and works offline.
- Popularity comes from ListenBrainz listen counts for now, until the app has enough ratings of its own. Search results, genre rows and the Popularity sort all use it.
- Album types: studio albums, mixtapes, EPs, live albums, soundtracks and remix albums are all included. Anything that isn't a studio album has a small label on its cover. Singles, demos, DJ mixes, spoken word and compilations are left out, apart from a short hand-picked list of important compilations.
- Browse by genre: Search now shows one sideways row per main genre, most popular first, with "See all" for the full list. The full list sorts by popularity or A to Z, and A to Z adds a letter index to jump through it.
- Artist cards for the top 2,000 artists by popularity, plus any artist you've rated. Each card uses an enlarged cover of the artist's most popular album.
- Fixed wrong covers: every album now stores its exact cover from the Cover Art Archive, so it can never show another album's cover. Albums without a cover show a plain placeholder.
- Genres for albums outside Bailey's rankings are a first guess from MusicBrainz tags, mapped onto the genre list from the rankings.

## v0.5
- Profile page, opened from the person icon in the top corner: a nickname you set with the small pencil (saved on the phone), with a placeholder @username underneath until online accounts exist.
- Your Range: pin up to five favourite albums from their page. They're drawn as a mountain skyline, with peak height set by difficulty and albums without a difficulty at base height with a "?". Empty slots are dashed. Tap a peak to open the album, press and hold to remove it, and choose which to replace when all five are full.
- Listen later: a bookmark in the corner of album cards (shows on hover on a PC; press and hold on a phone), plus a button on the album page. The list lives on the Ratings tab next to your rated albums.
- Sort menu on Search, artist pages and the Ratings tab: Alphabetical, Popularity, Difficulty, Your rating. Pick an option again to reverse it; the button shows the current order. Popularity counts ratings, which for now means only this device's.
- Artists show as wide cards with the image filling the card and the name over it, above the albums in Search.
- Album page: difficulty in an info square under the cover (symbol, with the level underneath), main genre larger with subgenres smaller underneath, and the album type shown only when it isn't a studio album.
- Expeditions: bigger, tinted cards with stacked covers and your average rating, and a "Rate this expedition" slider, separate from the album ratings.
- Reset progress on any expedition. Album ratings are kept, and albums count again once you rate them afresh.
- Edit your own expeditions: name, description, add or remove albums, reorder, and the in-order toggle. Official expeditions stay read-only.
- Journey look: stops zig-zag down the page like landmarks on a trail, joined by a line that's solid where you've been and dashed ahead. The final album is bigger and centred.

## v0.4
- Ratings save as soon as you let go of the slider. The Save and Remove buttons are gone.
- Album page shows an average rating next to yours. For now it only counts ratings on this device.
- Fixed: choosing an album while making an expedition now adds it, instead of opening it to rate.
- Search uses a fixed test list of about 240 proper albums (from Bailey's rankings plus the expedition albums), so results are instant and The Beatles come up first. Singles and compilations are left out.
- Covers come from a fast image service, so they load much more quickly. The "Search failed" error is gone, because search no longer goes online.
- Search shows results as you type, with genre tags to filter by and matching artists on top.
- Artist pages list an artist's albums, oldest first. Tap an artist in search or on an album page.
- Albums show their genre and subgenre tags on the album page.
- The Search tab is no longer blank before you type: it shows every album to browse.

## v0.3
- Expeditions can be marked "In order": each album unlocks once you rate the one before. Locked albums stay visible but greyed out. Jazz Breaks Free now works this way, starting with Kind of Blue.
- Removing a rating doesn't lock later albums again.
- Create your own expeditions: name, optional description, albums picked from search, drag to reorder, "Sort by year", and a "Listen in order" toggle. Saved on this device only; delete from the expedition page.
- Each expedition shows a picture: its first albums' covers stacked, with the first album on top.
- Difficulty tags now show on album cards everywhere (Ratings and Search too), not just in expeditions.
- Expedition albums are looked up in the background when the app starts.
- Info page covers the new expedition features and shows the version.

## v0.2
- Web version for trying the app in a PC browser.
- Expeditions tab lists three expeditions with progress; tap one to open it.
- Albums show as portrait cards with cover art, title and artist, three across, with your rating as a badge.
- New Ratings tab, newest first. Tabs reordered: Ratings, Search, Expeditions.
- Difficulty shows as a small tag with icon and level name.
- Info page (ⓘ) explaining difficulty levels, ratings and expeditions.
- Simpler album page with a confirmation when you save or remove a rating.

## v0.1
- Base app: album search (MusicBrainz), 0–10 rating in half steps, difficulty as a word with an icon, one test expedition with Next stop and progress. Ratings saved on the device.
