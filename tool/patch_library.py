"""Fixes the existing library file (assets/catalogue.json) in place, without
rebuilding it: drops bootlegs, adds full release dates, and corrects sheet
albums that point at the wrong MusicBrainz entry (old IDs become aliases so
saved ratings follow). Takes a few minutes. Same rules as build_library.py."""

import json
import re

from build_library import caa_front, log, mb_details, mb_find, norm, save_cache


def main():
    path = "assets/catalogue.json"
    lib = json.load(open(path, encoding="utf-8"))
    albums = lib["albums"]
    aliases = dict(lib.get("aliases") or {})
    ids = json.load(open("data/sheet_ids.json", encoding="utf-8"))
    sheet = json.load(open("data/albums.json", encoding="utf-8"))
    protected = set(ids.values())  # Bailey's sheet and the exceptions always stay

    details = mb_details(a["id"] for a in albums if not a["id"].startswith("local:"))
    kept, bootlegs = [], 0
    for a in albums:
        g = details.get(a["id"])
        if g:
            statuses = {r.get("status") for r in g.get("releases") or []}
            if statuses and "Official" not in statuses and a["id"] not in protected:
                bootlegs += 1
                log(f"  bootleg removed: {a['a']} - {a['t']}")
                continue
            if g.get("first-release-date"):
                a["d"] = g["first-release-date"]
        kept.append(a)
    by_id = {a["id"]: a for a in kept}
    by_name = {}
    for a in kept:
        if a.get("p"):
            by_name.setdefault(norm(a["a"]) + "|" + norm(a["t"]), a)

    # Sheet albums: make sure each points at the real album entry.
    sheet_details = mb_details(v for v in ids.values() if v and not v.startswith("local:"))
    fixed = 0
    for s in sheet:
        key = f"{s['artist']}|{s['title']}"
        old = ids.get(key)
        if not old or old.startswith("local:"):
            continue
        title = re.sub(r"\s*\[.*?\]", "", s["title"])
        g = sheet_details.get(old)
        wrong_type = g is not None and g.get("primary-type") not in ("Album", "EP", None)
        twin = by_name.get(norm(s["artist"]) + "|" + norm(title))
        new = old
        if twin and twin["id"] != old and not by_id.get(old, {}).get("p"):
            new = twin["id"]
        elif wrong_type:
            new = mb_find(title, s["artist"]) or old
        if new == old:
            continue
        mine = by_id.pop(old, None) or {}
        target = by_id.get(new) or {"id": new, "p": 0}
        # Bailey's own title, artist, genres and type win.
        keys = ["t", "a", "y", "g", "s", "ty"]
        if mine.get("p"):
            # Merged in 0.6 with the popular entry: its plays and cover are the album's.
            keys += ["p", "cr", "ci", "d"]
        target.update({k: mine[k] for k in keys if k in mine})
        target["id"] = new
        if not target.get("ci"):
            target["cr"], target["ci"] = caa_front(new)
        by_id[new] = target
        ids[key] = new
        aliases[old] = new
        fixed += 1
        log(f"  {key}: {old} -> {new}")

    for old, new in list(aliases.items()):  # follow chains of corrections
        while new in aliases and aliases[new] != new:
            new = aliases[new]
        aliases[old] = new
    lib["albums"] = sorted(by_id.values(), key=lambda a: -a.get("p", 0))
    lib["aliases"] = aliases
    json.dump(lib, open(path, "w", encoding="utf-8"), ensure_ascii=False, separators=(",", ":"))
    json.dump(ids, open("data/sheet_ids.json", "w", encoding="utf-8"), ensure_ascii=False, indent=1)
    save_cache()
    log(f"\nPatched: {bootlegs} bootlegs removed, {fixed} sheet albums corrected, "
        f"{len(lib['albums'])} albums, {sum(1 for a in lib['albums'] if a.get('d'))} with full dates")


if __name__ == "__main__":
    main()
