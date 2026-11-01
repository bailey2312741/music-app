"""Checks assets/catalogue.json after a build. Exits with an error (so the
new library is not published) when a known fact is wrong or the data looks
broken. Facts live in data/known_albums.json."""

import json
import re
import sys
import unicodedata


def norm(s):
    s = unicodedata.normalize("NFKD", s or "").encode("ascii", "ignore").decode().lower()
    return re.sub(r"[^a-z0-9]+", " ", s.replace("&", "and")).strip()


def main(path="assets/catalogue.json"):
    lib = json.load(open(path, encoding="utf-8"))
    known = json.load(open("data/known_albums.json", encoding="utf-8"))
    albums = lib["albums"]
    errors, warnings = [], []
    by_name = {}
    for a in albums:
        by_name.setdefault((norm(a["a"]), norm(a["t"])), []).append(a)

    ids = [a["id"] for a in albums]
    if len(ids) != len(set(ids)):
        errors.append("the same album ID appears twice")
    if len(albums) < 5000:
        errors.append(f"only {len(albums)} albums")

    for k in known["albums"]:
        found = by_name.get((norm(k["artist"]), norm(k["title"])))
        if not found:
            errors.append(f"missing: {k['artist']} - {k['title']}")
            continue
        a = max(found, key=lambda x: x.get("p", 0))
        name = f"{k['artist']} - {k['title']}"
        if k.get("year") and a.get("y") != k["year"]:
            errors.append(f"{name}: year {a.get('y')}, expected {k['year']}")
        if k.get("tracks") and a.get("n") and a["n"] != k["tracks"]:
            errors.append(f"{name}: {a['n']} tracks, expected {k['tracks']}")
        if "type" in k and a.get("ty") != k["type"]:
            errors.append(f"{name}: type {a.get('ty')}, expected {k['type'] or 'Studio'}")
    for k in known.get("absent", []):
        if by_name.get((norm(k["artist"]), norm(k["title"]))):
            errors.append(f"should not be in the library: {k['artist']} - {k['title']}")

    # Looks-wrong warnings: a studio album with very few tracks is often a single.
    for a in albums:
        if a.get("n") and a["n"] < 4 and not a.get("ty"):
            warnings.append(f"{a['a']} - {a['t']}: studio album with {a['n']} tracks")
    print(f"{len(albums)} albums, {sum(1 for a in albums if a.get('rl'))} with a chosen release")
    for w in warnings[:50]:
        print("  warning:", w)
    if len(warnings) > 50:
        print(f"  ...and {len(warnings) - 50} more warnings")
    for e in errors:
        print("ERROR:", e)
    if errors:
        sys.exit(f"{len(errors)} library check(s) failed; not publishing")
    print("All library checks passed")


if __name__ == "__main__":
    main(*sys.argv[1:])
