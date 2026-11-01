"""Builds the app's album library (assets/catalogue.json).

Sources (all free, no keys):
- ListenBrainz: popularity (listen counts), the most-listened artists, each
  artist's most-listened release groups, and the exact cover-art ID for each.
- MusicBrainz: album details (secondary types, release date) and tags, which
  are mapped onto the genre list from Bailey's sheet (data/genres.json).
- Cover Art Archive: covers, addressed by exact release and image ID so an
  album can never show another album's cover.

Always included: Bailey's sheet and the expedition albums (data/albums.json)
and hand-picked compilations (data/exceptions.json).

Runs on GitHub Actions (about 90 minutes). Standard library only.
Set LIBRARY_SIZE to change how many popular albums are kept.
"""

import json
import os
import re
import sys
import time
import unicodedata
import urllib.error
import urllib.parse
import urllib.request

UA = "MusicApp/0.6 (https://github.com/bailey2312741/music-app)"
LB = "https://api.listenbrainz.org/1"
MB = "https://musicbrainz.org/ws/2"
LIBRARY_SIZE = int(os.environ.get("LIBRARY_SIZE", "10000"))
FEATURED_ARTISTS = 2000
MAX_SEED_ARTISTS = int(os.environ.get("MAX_SEED_ARTISTS", "3500"))

KEEP_SECONDARY = {"Mixtape/Street": "Mixtape", "Live": "Live", "Soundtrack": "Soundtrack", "Remix": "Remix"}
DROP_SECONDARY = {"Compilation", "Demo", "DJ-mix", "Spokenword", "Interview", "Audiobook", "Audio drama",
                  "Field recording"}

_last = {}

# Answers saved between runs (GitHub keeps .cache/ with actions/cache), so a run
# that stops early, or a later rebuild, doesn't ask the same questions again.
CACHE_FILE = ".cache/answers.json"
try:
    _cache = json.load(open(CACHE_FILE, encoding="utf-8"))
except (OSError, ValueError):
    _cache = {}
# Stop looking through artists after this many minutes, so the run always finishes.
ARTIST_BUDGET = float(os.environ.get("ARTIST_MINUTES", "95")) * 60


def save_cache():
    os.makedirs(".cache", exist_ok=True)
    json.dump(_cache, open(CACHE_FILE, "w", encoding="utf-8"), separators=(",", ":"))


def log(*a):
    print(*a, flush=True)


def fetch(url, data=None, host_pause=None):
    """GET (or POST JSON) with polite pacing per host and retries on rate limits.
    GET answers are cached."""
    if data is None and url in _cache:
        return _cache[url]
    result, ok = _fetch(url, data, host_pause)
    if ok and data is None and "/stats/sitewide/" not in url:
        _cache[url] = result
    return result


def _fetch(url, data, host_pause):
    """Returns (answer, whether it is a real answer worth caching)."""
    host = urllib.parse.urlparse(url).netloc
    if host_pause is None:
        host_pause = 1.0 if 'listenbrainz' in host else 0.25
    wait = host_pause - (time.time() - _last.get(host, 0))
    if wait > 0:
        time.sleep(wait)
    body = json.dumps(data).encode() if data is not None else None
    for attempt in range(6):
        _last[host] = time.time()
        req = urllib.request.Request(url, data=body, headers={
            "User-Agent": UA, "Accept": "application/json", "Content-Type": "application/json"})
        try:
            with urllib.request.urlopen(req, timeout=30) as r:
                if r.status == 204:
                    return None, True
                return json.load(r), True
        except urllib.error.HTTPError as e:
            # ListenBrainz sometimes answers 401 instead of 429 when requests come too fast.
            if e.code in (401, 429, 503, 502, 500):
                if e.code == 401 and attempt == 0:
                    log("  401, slowing down:", e.read()[:200])
                delay = float(e.headers.get("Retry-After") or e.headers.get("X-RateLimit-Reset-In") or 2 * (attempt + 1))
                time.sleep(min(delay, 30) + 0.5)
                continue
            if e.code in (400, 404):
                return None, True
            log("  HTTP", e.code, url[:120])
            return None, False
        except Exception as e:  # network blip
            log("  retry", attempt + 1, e)
            time.sleep(2 * (attempt + 1))
    return None, False


def norm(s):
    s = re.sub("[‐-―]", "-", s or "")
    s = unicodedata.normalize("NFKD", s).encode("ascii", "ignore").decode().lower()
    s = s.replace("&", "and")
    return re.sub(r"[^a-z0-9]+", " ", s).strip()


# ---------------------------------------------------------------- genres

GENRES = json.load(open("data/genres.json", encoding="utf-8"))
SUB_TO_FAMILY = {norm(s): (fam, s) for fam, subs in GENRES.items() for s in subs}
FAMILY_ALIASES = {
    "rock": "Rock", "alternative rock": "Rock", "indie": "Rock", "pop": "Pop", "hip hop": "Hip-hop",
    "rap": "Hip-hop", "electronic": "Electronic", "dance": "Electronic", "metal": "Metal", "punk": "Punk",
    "r and b": "R&B & Soul", "rnb": "R&B & Soul", "soul": "R&B & Soul", "folk": "Folk", "country": "Folk",
    "jazz": "Jazz", "psychedelic": "Psychedelia", "psychedelia": "Psychedelia", "ambient": "Experimental & Ambient",
    "experimental": "Experimental & Ambient", "blues": "Other", "reggae": "Other", "classical": "Other",
    "soundtrack": "Other",
}
# A few common MusicBrainz spellings that differ from the sheet.
SUB_ALIASES = {"singer songwriter": "Singer-Songwriter", "trip hop": "Trip Hop", "post punk": "Post-Punk",
               "post rock": "Post-Rock", "neo psychedelia": "Neo-Psychedelia", "neo soul": "Neo-Soul",
               "drum and bass": "Drum and Bass", "uk garage": "UK Garage", "contemporary r and b": "Contemporary R&B",
               "rhythm and blues": "Rhythm & Blues", "east coast hip hop": "Boom Bap",
               "gangsta rap": "Gangsta Rap", "trap": "Trap", "progressive rock": "Progressive Rock"}


def genres_from_tags(tags):
    """Maps MusicBrainz tags (most votes first) onto the sheet's genre list."""
    family, subs = None, []
    for t in sorted(tags or [], key=lambda t: -t.get("count", 0)):
        n = norm(t.get("name", ""))
        if n in SUB_ALIASES:
            n = norm(SUB_ALIASES[n])
        if n in SUB_TO_FAMILY:
            fam, sub = SUB_TO_FAMILY[n]
            family = family or fam
            if sub not in subs and len(subs) < 3:
                subs.append(sub)
        elif n in FAMILY_ALIASES and not family:
            family = FAMILY_ALIASES[n]
    return family, subs


# ---------------------------------------------------------------- ListenBrainz

def sitewide(kind, rng, limit):
    """Paged sitewide stats (artists or release-groups)."""
    out, offset = [], 0
    while offset < limit:
        d = fetch(f"{LB}/stats/sitewide/{kind}?range={rng}&count=100&offset={offset}")
        rows = ((d or {}).get("payload") or {}).get(kind.replace("-", "_")) or []
        if not rows:
            break
        out += rows
        offset += len(rows)
    return out


def seed_artists():
    artists = {}  # mbid -> listen count (best seen)
    for rng in ("all_time", "year", "half_yearly", "quarter", "month", "this_year"):
        rows = sitewide("artists", rng, 1000)
        for r in rows:
            m = r.get("artist_mbid")
            if m:
                artists[m] = max(artists.get(m, 0), r.get("listen_count", 0))
        log(f"sitewide artists {rng}: {len(rows)} rows, {len(artists)} unique so far")
    for rng in ("all_time", "year"):
        rows = sitewide("release-groups", rng, 3000)
        for r in rows:
            for m in r.get("artist_mbids") or []:
                artists.setdefault(m, 0)
        log(f"sitewide release groups {rng}: {len(rows)} rows, {len(artists)} artists so far")
    return artists


def artist_listens(mbids):
    out = {}
    ids = list(mbids)
    for i in range(0, len(ids), 50):
        d = fetch(f"{LB}/popularity/artist", {"artist_mbids": ids[i:i + 50]}) or []
        for r in d:
            if r and r.get("artist_mbid"):
                out[r["artist_mbid"]] = r.get("total_listen_count") or 0
    return out


# ---------------------------------------------------------------- MusicBrainz

def mb_details(ids):
    """Secondary types, date, artist credit and tags for release groups, 40 per request."""
    out = {}
    ids = list(ids)
    for i in range(0, len(ids), 40):
        chunk = ids[i:i + 40]
        q = "rgid:(" + " OR ".join(chunk) + ")"
        url = f"{MB}/release-group?" + urllib.parse.urlencode({"query": q, "fmt": "json", "limit": "100"})
        d = fetch(url, host_pause=1.1) or {}
        for g in d.get("release-groups", []):
            out[g["id"]] = g
        if (i // 40) % 25 == 0:
            log(f"  MusicBrainz details {min(i + 40, len(ids))}/{len(ids)}")
    return out


def credit_name(g):
    return "".join(c.get("name", "") + c.get("joinphrase", "") for c in g.get("artist-credit", []))


def mb_find(title, artist):
    """Finds one album by title and artist (for sheet albums without a known ID)."""
    q = f'releasegroup:"{title}" AND artist:"{artist}"'
    d = fetch(f"{MB}/release-group?" + urllib.parse.urlencode({"query": q, "fmt": "json", "limit": "5"}),
              host_pause=1.1) or {}
    for g in d.get("release-groups", []):
        if norm(artist) in norm(credit_name(g)) or norm(credit_name(g)) in norm(artist):
            return g["id"]
    return None


def caa_front(rgid):
    """Exact front cover (release ID and image ID) for a release group, if one exists."""
    d = fetch(f"https://coverartarchive.org/release-group/{rgid}", host_pause=0.2)
    if not d:
        return None, None
    rel = (d.get("release") or "").rstrip("/").split("/")[-1] or None
    for img in d.get("images", []):
        if img.get("front"):
            return rel, str(img.get("id"))
    return None, None


# ---------------------------------------------------------------- main

def main():
    t0 = time.time()
    seeds = seed_artists()
    log(f"{len(seeds)} seed artists")
    listens = artist_listens(seeds)
    ranked_artists = sorted(seeds, key=lambda m: -listens.get(m, 0))[:MAX_SEED_ARTISTS]

    # Each artist's most-listened release groups, with type and exact cover IDs.
    cands = {}
    looked = 0
    for n, m in enumerate(ranked_artists):
        if time.time() - t0 > ARTIST_BUDGET:
            log(f"time budget reached after {n} artists (cached answers make the next run go further)")
            break
        looked = n + 1
        for r in fetch(f"{LB}/popularity/top-release-groups-for-artist/{m}") or []:
            rg = r.get("release_group") or {}
            gid = r.get("release_group_mbid")
            if not gid or rg.get("type") not in ("Album", "EP"):
                continue
            prev = cands.get(gid)
            if prev and prev["p"] >= (r.get("total_listen_count") or 0):
                continue
            cands[gid] = {
                "id": gid,
                "t": rg.get("name") or "",
                "a": (r.get("artist") or {}).get("name") or "",
                "y": (rg.get("date") or "")[:4] or None,
                "pt": rg.get("type"),
                "p": r.get("total_listen_count") or 0,
                "cr": rg.get("caa_release_mbid"),
                "ci": str(rg["caa_id"]) if rg.get("caa_id") else None,
                "am": m,
            }
        if n % 250 == 0:
            save_cache()
            log(f"artist albums {n}/{len(ranked_artists)}: {len(cands)} candidates ({int(time.time() - t0)}s)")

    # Check types on MusicBrainz for the most popular candidates (with headroom for drops).
    pool = sorted(cands.values(), key=lambda c: -c["p"])[: int(LIBRARY_SIZE * 1.5)]
    details = mb_details(c["id"] for c in pool)
    kept, dropped = [], {}
    for c in pool:
        g = details.get(c["id"])
        if not g:
            dropped["no details"] = dropped.get("no details", 0) + 1
            continue
        sec = g.get("secondary-types") or []
        bad = [s for s in sec if s in DROP_SECONDARY or s not in KEEP_SECONDARY]
        if bad:
            dropped[bad[0]] = dropped.get(bad[0], 0) + 1
            continue
        label = next((KEEP_SECONDARY[s] for s in sec), None) or ("EP" if c["pt"] == "EP" else None)
        fam, subs = genres_from_tags(g.get("tags"))
        date = g.get("first-release-date") or ""
        kept.append({**c, "t": g.get("title") or c["t"], "a": credit_name(g) or c["a"],
                     "y": date[:4] or c["y"], "ty": label, "g": fam, "s": subs})
        if len(kept) >= LIBRARY_SIZE:
            break
    log(f"kept {len(kept)} popular albums; dropped {dropped}")

    by_id = {k["id"]: k for k in kept}

    # Always include Bailey's sheet, the expedition albums and the exceptions.
    sheet = json.load(open("data/albums.json", encoding="utf-8"))
    ids = json.load(open("data/sheet_ids.json", encoding="utf-8"))
    exceptions = json.load(open("data/exceptions.json", encoding="utf-8"))["albums"]
    forced = [dict(a, _sheet=True) for a in sheet] + [dict(a, _sheet=False) for a in exceptions]
    missing_cover = 0
    for a in forced:
        key = f"{a['artist']}|{a['title']}"
        gid = ids.get(key) or mb_find(re.sub(r"\s*\[.*?\]", "", a["title"]), a["artist"])
        if gid:
            ids[key] = gid
        else:
            gid = "local:" + norm(a["artist"] + " " + a["title"]).replace(" ", "-")
        entry = by_id.get(gid) or {"id": gid, "p": 0, "cr": None, "ci": None}
        if not entry.get("ci") and not gid.startswith("local:"):
            entry["cr"], entry["ci"] = caa_front(gid)
        if not entry.get("ci"):
            missing_cover += 1
        if a["_sheet"]:
            # Bailey's own title, artist and genres win for sheet albums.
            entry.update({"t": a["title"], "a": a["artist"], "y": a.get("year") or entry.get("y"),
                          "g": a.get("genre"), "s": a.get("subgenres") or [],
                          "ty": None if a.get("type") in (None, "Studio") else a["type"]})
        else:
            entry.setdefault("t", a["title"])
            entry.setdefault("a", a["artist"])
            entry["ty"] = "Compilation"
            entry.setdefault("g", None)
            entry.setdefault("s", [])
        by_id[gid] = entry
    save_cache()
    json.dump(ids, open("data/sheet_ids.json", "w", encoding="utf-8"), ensure_ascii=False, indent=1)

    albums = sorted(by_id.values(), key=lambda a: -a.get("p", 0))
    out_albums = []
    for a in albums:
        row = {"id": a["id"], "t": a["t"], "a": a["a"]}
        for k in ("y", "ty", "g", "cr", "ci"):
            if a.get(k):
                row[k] = a[k]
        if a.get("s"):
            row["s"] = a["s"]
        if a.get("p"):
            row["p"] = a["p"]
        out_albums.append(row)

    # Artists: popularity = their total listens across kept albums.
    art = {}
    for a in out_albums:
        art[a["a"]] = art.get(a["a"], 0) + a.get("p", 0)
    featured = [n for n, _ in sorted(art.items(), key=lambda x: -x[1])[:FEATURED_ARTISTS]]

    json.dump({"version": 2, "albums": out_albums, "featuredArtists": featured},
              open("assets/catalogue.json", "w", encoding="utf-8"), ensure_ascii=False, separators=(",", ":"))

    with_genre = sum(1 for a in out_albums if a.get("g"))
    with_cover = sum(1 for a in out_albums if a.get("ci"))
    types = {}
    for a in out_albums:
        types[a.get("ty") or "Studio"] = types.get(a.get("ty") or "Studio", 0) + 1
    log(f"artists looked through: {looked}/{len(ranked_artists)}")
    log(f"\nDONE in {int(time.time() - t0)}s: {len(out_albums)} albums, {len(featured)} featured artists")
    log(f"covers: {with_cover}, genres: {with_genre}, types: {types}, sheet/exception albums without cover: {missing_cover}")


if __name__ == "__main__":
    main()
