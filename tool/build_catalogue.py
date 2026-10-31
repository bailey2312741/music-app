"""Builds assets/catalogue.json from data/albums.json.

For each album it looks up a MusicBrainz release-group ID (the app's album ID)
and a cover image from Deezer's image CDN, which loads much faster than the
Cover Art Archive. Results already in the catalogue are reused, so only new
albums are looked up. Runs on GitHub Actions; standard library only.
"""

import json
import re
import sys
import time
import unicodedata
import urllib.parse
import urllib.request

UA = "MusicApp/0.4 (https://github.com/bailey2312741/music-app)"
SRC = "data/albums.json"
OUT = "assets/catalogue.json"


def norm(s):
    s = unicodedata.normalize("NFKD", s).encode("ascii", "ignore").decode().lower()
    s = s.replace("&", "and")
    return re.sub(r"[^a-z0-9]+", " ", s).strip()


def query_title(t):
    t = re.sub(r"\s*\[.*?\]", "", t)  # "Weezer [Blue Album]" -> "Weezer"
    if any(ord(c) > 0x2FF for c in t):  # keep the original script, drop romanisation
        t = re.sub(r"\s*\(.*?\)", "", t)
    return t.strip()


_last = [0.0]


def get(url, pause=1.1):
    wait = pause - (time.time() - _last[0])
    if wait > 0:
        time.sleep(wait)
    _last[0] = time.time()
    for attempt in range(4):
        try:
            req = urllib.request.Request(url, headers={"User-Agent": UA, "Accept": "application/json"})
            with urllib.request.urlopen(req, timeout=20) as r:
                return json.load(r)
        except Exception as e:  # rate limits and blips: back off and retry
            print("  retry", attempt + 1, e, file=sys.stderr)
            time.sleep(2 * (attempt + 1))
    return None


def artist_matches(want, got):
    a, b = norm(want), norm(got)
    return bool(a) and bool(b) and (a in b or b in a)


def musicbrainz(album):
    title, artist = query_title(album["title"]), album["artist"]
    esc = lambda s: s.replace('"', '\\"')
    queries = [
        f'releasegroup:"{esc(title)}" AND artist:"{esc(artist)}"',
        f"{title} {artist}",
    ]
    for q in queries:
        url = "https://musicbrainz.org/ws/2/release-group?" + urllib.parse.urlencode(
            {"query": q, "fmt": "json", "limit": "10"})
        data = get(url) or {}
        for g in data.get("release-groups", []):
            credit = "".join(c.get("name", "") + c.get("joinphrase", "") for c in g.get("artist-credit", []))
            if artist_matches(artist, credit) and norm(g.get("title", "")) == norm(title):
                return g["id"]
        for g in data.get("release-groups", []):
            credit = "".join(c.get("name", "") + c.get("joinphrase", "") for c in g.get("artist-credit", []))
            if artist_matches(artist, credit) and g.get("score", 0) >= 90:
                return g["id"]
    return None


def deezer(album):
    title, artist = query_title(album["title"]), album["artist"]
    for q in (f'artist:"{artist}" album:"{title}"', f"{artist} {title}"):
        url = "https://api.deezer.com/search/album?" + urllib.parse.urlencode({"q": q, "limit": "10"})
        data = get(url, pause=0.25) or {}
        for a in data.get("data", []):
            if artist_matches(artist, a.get("artist", {}).get("name", "")):
                return a.get("cover_medium"), a.get("cover_big")
    return None, None


def main():
    albums = json.load(open(SRC, encoding="utf-8"))
    try:
        old = {(a["title"], a["artist"]): a for a in json.load(open(OUT, encoding="utf-8"))}
    except FileNotFoundError:
        old = {}

    out, missing_id, missing_cover = [], [], []
    for i, a in enumerate(albums):
        prev = old.get((a["title"], a["artist"]), {})
        mbid = prev.get("id") if not str(prev.get("id", "")).startswith("local:") else None
        cover, cover_large = prev.get("cover"), prev.get("coverLarge")
        if not mbid:
            mbid = musicbrainz(a)
        if not cover:
            cover, cover_large = deezer(a)
        print(f"[{i + 1}/{len(albums)}] {a['artist']} - {a['title']}: {mbid or '-'} {'cover' if cover else 'no cover'}")
        if not mbid:
            missing_id.append(a)
            mbid = "local:" + norm(a["artist"] + " " + a["title"]).replace(" ", "-")
        if not cover:
            missing_cover.append(a)
        out.append({**a, "id": mbid, "cover": cover, "coverLarge": cover_large})

    json.dump(out, open(OUT, "w", encoding="utf-8"), ensure_ascii=False, indent=1)
    print(f"\n{len(out)} albums, {len(missing_id)} without a MusicBrainz ID, {len(missing_cover)} without a cover")
    for a in missing_id:
        print("  no ID:", a["artist"], "-", a["title"])
    for a in missing_cover:
        print("  no cover:", a["artist"], "-", a["title"])


if __name__ == "__main__":
    main()
