"""Writes the four listening-stage icons to assets/icons/stages/.

Each stage has a large version (64 x 64 viewBox) and a compact one
(24 x 24 viewBox). All eight share the same arched frame and are drawn in
one colour (#F3F0E7, paper50); the app recolours them from the theme.

Geometry is hand-built here rather than traced, so edit the numbers below
and run `python3 tool/build_stage_icons.py` to regenerate.
"""

from pathlib import Path

OUT = Path(__file__).resolve().parent.parent / "assets" / "icons" / "stages"
INK = "#F3F0E7"


def fmt(v):
    return f"{v:.2f}".rstrip("0").rstrip(".")


def pts(*xy):
    return " ".join(f"{fmt(x)} {fmt(y)}" for x, y in xy)


def poly(*xy):
    head, *rest = xy
    return f"M{pts(head)} " + " ".join(f"L{pts(p)}" for p in rest) + " Z"


def svg(size, frame, shapes):
    body = "\n  ".join(f'<path d="{d}"/>' for d in shapes)
    return (
        f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 {size} {size}" '
        f'width="{size}" height="{size}">\n'
        f'  <path d="{frame[0]}" fill="none" stroke="{INK}" stroke-width="{fmt(frame[1])}" '
        f'stroke-linejoin="round"/>\n'
        f'  <g fill="{INK}" fill-rule="evenodd">\n  {body}\n  </g>\n</svg>\n'
    )


def arch(left, right, top_y, bottom, stroke):
    r = (right - left) / 2
    return (
        f"M{fmt(left)} {fmt(bottom)} V{fmt(top_y + r)} "
        f"A{fmt(r)} {fmt(r)} 0 0 1 {fmt(right)} {fmt(top_y + r)} "
        f"V{fmt(bottom)} Z",
        stroke,
    )


def winding_path(centre, widths, apex, left_base, right_base, right_side):
    """A mountain split by a winding trail that widens towards the viewer.

    centre: list of cubic segments [(p0, c1, c2, p1), ...] along the trail.
    widths: half-width of the trail at each segment end (len = segments + 1).
    Returns the two mountain pieces either side of the trail.
    """

    def shift(p, dx):
        return (p[0] + dx, p[1])

    left_edge, right_edge = [], []
    for i, (p0, c1, c2, p1) in enumerate(centre):
        w0, w1 = widths[i], widths[i + 1]
        wc1, wc2 = w0 + (w1 - w0) / 3, w0 + 2 * (w1 - w0) / 3
        left_edge.append((shift(p0, -w0), shift(c1, -wc1), shift(c2, -wc2), shift(p1, -w1)))
        right_edge.append((shift(p0, w0), shift(c1, wc1), shift(c2, wc2), shift(p1, w1)))

    # Left piece: base-left, up to the apex, then down the trail's left edge.
    d = f"M{pts(left_base)} L{pts(apex)} L{pts(left_edge[0][0])}"
    for _, c1, c2, p1 in left_edge:
        d += f" C{pts(c1, c2, p1)}"
    d += " Z"
    left = d

    # Right piece: apex, down the right side, along the base, up the trail's right edge.
    d = f"M{pts(apex)} " + " ".join(f"L{pts(p)}" for p in right_side)
    d += f" L{pts(right_base)} L{pts(right_edge[-1][3])}"
    for p0, c1, c2, p1 in reversed(right_edge):
        d += f" C{pts(c2, c1, p0)}"
    d += " Z"
    return [left, d]


def circle(cx, cy, r):
    return (
        f"M{fmt(cx - r)} {fmt(cy)} A{fmt(r)} {fmt(r)} 0 1 0 {fmt(cx + r)} {fmt(cy)} "
        f"A{fmt(r)} {fmt(r)} 0 1 0 {fmt(cx - r)} {fmt(cy)} Z"
    )


# ---------------------------------------------------------------- large (64)
L_FRAME = arch(7, 57, 6, 58, 4)
G = 56  # ground line inside the frame

large = {
    "base_camp": [
        # Front of the tent with a doorway cut out.
        poly((13, G), (26, 32), (39, G)) + " " + poly((21, G), (26, 44), (31, G)),
        # The side of the tent, set back by a thin gap.
        poly((29, 32), (39, 32), (52, G), (44, G)),
    ],
    "foothills": [
        circle(23, 23, 5.5),
        # Back hill, a band with a gap below it.
        "M9 45 C17 40 25 40 32 39 C40 38 47 34 55 32 L55 37 C47 39 40 43 32 44 "
        "C25 45 17 47 9 50 Z",
        # Front hill.
        f"M9 {G} L9 54 C19 50 28 51 36 49 C43 47.5 49 45 55 44 L55 {G} Z",
    ],
    "high_altitude": [
        # Three jagged peaks, the middle one tallest, with a zigzag snow line
        # cut across the middle peak.
        poly((9, G), (9, 47), (18, 36), (22, 40), (31, 20), (40, 32), (44, 28), (55, 42), (55, G))
        + " "
        + poly((26.4, 31.6), (28.6, 29.2), (31, 32), (33.5, 28.9), (36.4, 32.4), (36.4, 34.6),
               (33.5, 31.1), (31, 34.2), (28.6, 31.4), (26.4, 33.8)),
    ],
    "summit": winding_path(
        centre=[
            ((35.6, 27), (34, 31), (30, 33), (31, 37)),
            ((31, 37), (32, 41), (40, 41), (38.5, 46)),
            ((38.5, 46), (37, 50.5), (31, 52), (31, G)),
        ],
        widths=[0.5, 1.0, 1.6, 2.6],
        apex=(36, 24),
        left_base=(9, G),
        right_base=(55, G),
        right_side=[(55, 47)],
    )
    + [
        # Flag on the summit: pole and pennant.
        poly((35, 24.6), (35, 12), (37, 12), (37, 24.6)),
        poly((37, 12), (44, 15), (37, 18)),
    ],
}

# -------------------------------------------------------------- compact (24)
C_FRAME = arch(2.5, 21.5, 2, 22, 2)
g = 21  # ground line inside the frame

compact = {
    "base_camp": [
        poly((5.5, g), (11, 11), (16.5, g)) + " " + poly((9.6, g), (11, 17), (12.4, g)),
        poly((12.6, 11), (15, 11), (20.3, g), (18.5, g)),
    ],
    "foothills": [
        circle(8.5, 9, 2.2),
        f"M3.5 {g} L3.5 17 C7.5 15 10.5 15.3 13.5 14.2 C16 13.3 18.2 12.3 20.5 12 L20.5 {g} Z",
    ],
    "high_altitude": [
        poly((3.5, g), (3.5, 17.5), (7, 12.5), (8.8, 14.6), (12, 6.8), (15.4, 12.3), (17, 10.6),
             (20.5, 15), (20.5, g)),
    ],
    "summit": winding_path(
        centre=[
            ((12.9, 13.2), (12.2, 14.6), (11, 15), (11.5, 16.5)),
            ((11.5, 16.5), (12, 18), (14, 18.4), (13.4, g)),
        ],
        widths=[0.35, 0.6, 1.1],
        apex=(13, 11.5),
        left_base=(3.5, g),
        right_base=(20.5, g),
        right_side=[(20.5, 18)],
    )
    + [
        poly((12.4, 11.9), (12.4, 4.8), (13.6, 4.8), (13.6, 11.9)),
        poly((13.6, 4.8), (17.2, 6.1), (13.6, 7.4)),
    ],
}


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    for name, shapes in large.items():
        (OUT / f"{name}_large.svg").write_text(svg(64, L_FRAME, shapes))
    for name, shapes in compact.items():
        (OUT / f"{name}_compact.svg").write_text(svg(24, C_FRAME, shapes))
    print(f"Wrote {len(large) + len(compact)} icons to {OUT}")


if __name__ == "__main__":
    main()
