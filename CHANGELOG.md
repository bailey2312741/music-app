# Changelog

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
