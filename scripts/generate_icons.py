#!/usr/bin/env python3
"""
Generate a ninja app's single-colour icon set from one black-on-white drawing.

Usage:
    python generate_icons.py --repo auraninja            # write the outputs
    python generate_icons.py --repo auraninja --check    # verify only, never write
    python generate_icons.py --app-dir . --check         # app checked out elsewhere (CI)
    python generate_icons.py --repo auraninja --preview out/   # also write preview PNGs
    python generate_icons.py --app-dir . --check-regenerated   # CI, after flutter_launcher_icons

Inputs come from the app's `icon_config.yml` (see the bottom of this docstring).
The outputs are committed in the app repo. The SVG is the source of truth; the
drawing is only an authoring input and does not need to live in the repo:

  - with `artwork` configured, the drawing is traced and fitted onto the colour
    icon, and all outputs are written from that;
  - without it, the committed SVG is read back and the other outputs are
    regenerated from it (no tracing, so nothing about the placement can move).

  - `svg`                 the mark in the brand colour. Its 0-100 viewBox IS the
                          canvas of `reference_icon`, so drawn at the same size the
                          two overlay: that is what keeps the Android themed icon
                          in exactly the same place as the colour one.
  - `monochrome_png`      white-on-transparent render of that SVG at the reference
                          icon's size, fed to flutter_launcher_icons as
                          `adaptive_icon_monochrome`. The tool applies the same
                          inset to it as to the colour foreground, so the two
                          layers stay aligned without any hand edit.
  - `notification_vector` (optional) Android notification small icon: the same
                          path framed on its own, long edge 20dp centred in 24dp.

How the mark is fitted: the drawing is traced (marching squares on a lightly
blurred darkness field, so edges are sub-pixel; RDP simplification; midpoint
quadratic smoothing that keeps sharp corners), then registered onto the colour
icon by the scale and offset that maximise pixel overlap (IoU). The fit is then
judged on the outline alone (see outline_iou): a faithful trace scores ~0.98+,
and anything under MIN_FIT_IOU is refused rather than written.

`--check` is deterministic on purpose and never re-traces: the tracer's float
maths depends on the numpy/Pillow versions, so a re-trace in CI could differ in
the last digit and fail for nothing. It verifies the committed outputs agree with
each other and with the app's flutter_launcher_icons config, which is the drift
that actually happens (a hand edit to one output, or a config key removed).

Requires: numpy, Pillow, PyYAML   (pip install numpy pillow pyyaml)

icon_config.yml:
    artwork: path/to/drawing.jpg                  # optional: black mark on white, to (re)trace
    reference_icon: assets/icons/<app>_icon.png   # the colour icon (RGBA)
    brand_color: "#3D7A3F"                        # fill of the SVG
    svg: assets/icons/<app>_mono.svg
    monochrome_png: assets/icons/<app>_monochrome.png
    notification_vector: android/app/src/main/res/drawable/ic_stat_<app>.xml  # optional
    min_fit_iou: 0.90                             # optional; refuse a worse outline fit
    trace:                                        # optional overrides
      rdp_tolerance: 0.5
"""

import argparse
import math
import os
import re
import sys

try:
    import numpy as np
    from PIL import Image, ImageDraw, ImageFilter
    import yaml
except ImportError as e:
    print(f"Missing dependency ({e.name}). Install with: pip install numpy pillow pyyaml")
    sys.exit(1)

SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))
REPOS_DIR = os.path.dirname(os.path.dirname(SCRIPT_DIR))
CONFIG_NAME = "icon_config.yml"

TRACE_DEFAULTS = {
    "blur": 0.8,            # px, before iso-lining at 0.5 darkness
    "rdp_tolerance": 0.5,   # px of the source drawing
    "corner_degrees": 55.0, # turn above which a vertex stays a sharp join
    "min_area": 40.0,       # px^2; drops JPEG specks
}
UNITS = 100.0               # every path lives in a 0-100 box
# Fit quality is judged on the OUTLINE: the mark's own white details (headband,
# belt, eye slits) are excused, because against a solid colour icon they read as
# mismatch although they are the design. The raw pixel IoU, which still drives
# the search, sits near 0.81 even for a near-perfect trace. Measured on auraninja:
# good traces 0.983 and 0.996, a different character 0.695, an unrelated shape
# 0.429. Below the floor the placement cannot be trusted.
MIN_FIT_IOU = 0.90


# --------------------------------------------------------------------- tracing

def _marching_squares(f, iso=0.5):
    """Closed iso-contours of a 2-D field, as float (x, y) point arrays."""
    a = f[:-1, :-1] > iso
    b = f[:-1, 1:] > iso
    c = f[1:, 1:] > iso
    d = f[1:, :-1] > iso
    case = a * 8 + b * 4 + c * 2 + d * 1
    cells = np.argwhere((case != 0) & (case != 15))

    def interp(p1, p2, v1, v2):
        t = (iso - v1) / (v2 - v1)
        return (p1[0] + t * (p2[0] - p1[0]), p1[1] + t * (p2[1] - p1[1]))

    point_of = {}

    def edge(key):
        if key not in point_of:
            kind, y, x = key
            if kind == "h":
                point_of[key] = interp((x, y), (x + 1, y), f[y, x], f[y, x + 1])
            else:
                point_of[key] = interp((x, y), (x, y + 1), f[y, x], f[y + 1, x])
        return key

    adj = {}
    for y, x in cells:
        k = case[y, x]
        T, B, L, R = ("h", y, x), ("h", y + 1, x), ("v", y, x), ("v", y, x + 1)
        centre = (f[y, x] + f[y, x + 1] + f[y + 1, x] + f[y + 1, x + 1]) / 4
        table = {
            1: [(L, B)], 2: [(B, R)], 3: [(L, R)], 4: [(T, R)],
            6: [(T, B)], 7: [(L, T)], 8: [(L, T)], 9: [(T, B)],
            11: [(T, R)], 12: [(L, R)], 13: [(B, R)], 14: [(L, B)],
            5: [(L, T), (B, R)] if centre > iso else [(L, B), (T, R)],
            10: [(L, B), (T, R)] if centre > iso else [(L, T), (B, R)],
        }
        for e1, e2 in table[k]:
            s, e = edge(e1), edge(e2)
            adj.setdefault(s, []).append(e)
            adj.setdefault(e, []).append(s)

    loops, seen = [], set()
    for start in adj:
        if start in seen:
            continue
        loop, prev, cur = [start], None, start
        seen.add(start)
        while True:
            nxt = [n for n in adj[cur] if n != prev]
            if not nxt or nxt[0] == start or nxt[0] in seen:
                break
            n = nxt[0]
            seen.add(n)
            loop.append(n)
            prev, cur = cur, n
        if len(loop) > 8:
            loops.append(np.array([point_of[k] for k in loop]))
    return loops


def _area(p):
    x, y = p[:, 0], p[:, 1]
    return 0.5 * (np.dot(x, np.roll(y, -1)) - np.dot(y, np.roll(x, -1)))


def _rdp(pts, tol):
    if len(pts) < 3:
        return pts
    stack, keep = [(0, len(pts) - 1)], np.zeros(len(pts), bool)
    keep[0] = keep[-1] = True
    while stack:
        i, j = stack.pop()
        if j <= i + 1:
            continue
        p, q = pts[i], pts[j]
        seg = q - p
        n = np.hypot(*seg)
        r = pts[i + 1:j] - p
        dist = np.hypot(*r.T) if n == 0 else np.abs(seg[0] * r[:, 1] - seg[1] * r[:, 0]) / n
        k = int(np.argmax(dist))
        if dist[k] > tol:
            m = i + 1 + k
            keep[m] = True
            stack += [(i, m), (m, j)]
    return pts[keep]


def _rdp_closed(p, tol):
    far = int(np.argmax(np.hypot(*(p - p[0]).T)))
    a1 = _rdp(p[:far + 1], tol)
    a2 = _rdp(np.vstack([p[far:], p[:1]]), tol)
    return np.vstack([a1[:-1], a2[:-1]])


def _fmt(v):
    t = f"{v:.2f}".rstrip("0").rstrip(".")
    return "0" if t in ("-0", "") else t


def _smooth_path(p, corner_deg):
    """Midpoint-quadratic closed path; vertices turning more than corner_deg stay sharp."""
    n = len(p)

    def turn(i):
        v1, v2 = p[i] - p[i - 1], p[(i + 1) % n] - p[i]
        n1, n2 = np.hypot(*v1), np.hypot(*v2)
        if n1 == 0 or n2 == 0:
            return 0.0
        return math.degrees(math.acos(np.clip(np.dot(v1, v2) / (n1 * n2), -1, 1)))

    mid = lambda i: (p[i] + p[(i + 1) % n]) / 2
    s = mid(n - 1)
    out = [f"M{_fmt(s[0])},{_fmt(s[1])}"]
    for i in range(n):
        m = mid(i)
        if turn(i) > corner_deg:
            out.append(f"L{_fmt(p[i][0])},{_fmt(p[i][1])}L{_fmt(m[0])},{_fmt(m[1])}")
        else:
            out.append(f"Q{_fmt(p[i][0])},{_fmt(p[i][1])} {_fmt(m[0])},{_fmt(m[1])}")
    out.append("Z")
    return "".join(out)


def _strip_border_regions(im, threshold=128):
    """Paint white every dark region that touches the image border.

    Scan edges, frames and crop remnants are what reaches the border; the mark
    itself never should. Deliberately not a size filter: a thin artefact and a
    real detail (the eyes, a robe line) can have the same area, so area cannot
    tell them apart, but position can.
    """
    im = im.copy()
    w, h = im.size
    px = im.load()
    border = ([(x, 0) for x in range(w)] + [(x, h - 1) for x in range(w)] +
              [(0, y) for y in range(h)] + [(w - 1, y) for y in range(h)])
    for xy in border:
        if px[xy] < threshold:
            ImageDraw.floodfill(im, xy, 255, thresh=threshold)
    return im


def trace(artwork_path, opts):
    """Trace the drawing into (path_d, rings) normalised so the figure fits 0-100, centred."""
    im = Image.open(artwork_path).convert("L")
    im = _strip_border_regions(im)
    f = 1.0 - np.asarray(im.filter(ImageFilter.GaussianBlur(opts["blur"])), dtype=np.float64) / 255.0
    ys, xs = np.nonzero(f > 0.5)
    if len(xs) == 0:
        raise SystemExit(f"{artwork_path}: no dark pixels, expected a black mark on white")
    pad = 3
    f = f[max(0, ys.min() - pad):ys.max() + pad + 1, max(0, xs.min() - pad):xs.max() + pad + 1]
    f = np.pad(f, 1, constant_values=0.0)   # every contour closes inside the field

    rings = [l for l in _marching_squares(f) if abs(_area(l)) >= opts["min_area"]]
    rings = [_rdp_closed(l, opts["rdp_tolerance"]) for l in rings]
    allp = np.vstack(rings)
    mn, mx = allp.min(0), allp.max(0)
    w, h = mx - mn
    s = UNITS / max(w, h)
    off = (UNITS - np.array([w, h]) * s) / 2 - mn * s
    rings = [l * s + off for l in rings]
    d = "".join(_smooth_path(l, opts["corner_degrees"]) for l in rings)
    return d, rings


# ------------------------------------------------------------------- geometry

_NUM = re.compile(r"-?\d+(?:\.\d+)?")


def transform_path(d, scale, tx, ty):
    """Apply x' = scale*x + tx, y' = scale*y + ty to every absolute coordinate pair."""
    nums = [float(v) for v in _NUM.findall(d)]
    if len(nums) % 2:
        raise ValueError("odd number of coordinates in path")
    out = []
    for i in range(0, len(nums), 2):
        out += [scale * nums[i] + tx, scale * nums[i + 1] + ty]
    it = iter(out)
    return _NUM.sub(lambda m: _fmt(next(it)), d)


def path_bbox(d):
    nums = [float(v) for v in _NUM.findall(d)]
    xs, ys = nums[0::2], nums[1::2]
    return min(xs), min(ys), max(xs), max(ys)


def _flatten(d, steps=8):
    """Polygons (one per subpath) from our own M/L/Q/Z absolute path format."""
    polys = []
    for sub in d.split("Z"):
        toks = re.findall(r"[MLQ]|" + _NUM.pattern, sub)
        pts, cur, i = [], None, 0
        while i < len(toks):
            c = toks[i]
            if c in ("M", "L"):
                cur = (float(toks[i + 1]), float(toks[i + 2]))
                pts.append(cur)
                i += 3
            elif c == "Q":
                c1 = (float(toks[i + 1]), float(toks[i + 2]))
                e = (float(toks[i + 3]), float(toks[i + 4]))
                for k in range(1, steps + 1):
                    t = k / steps
                    pts.append(((1 - t) ** 2 * cur[0] + 2 * (1 - t) * t * c1[0] + t * t * e[0],
                                (1 - t) ** 2 * cur[1] + 2 * (1 - t) * t * c1[1] + t * t * e[1]))
                cur = e
                i += 5
            else:
                raise ValueError(f"unexpected path token {c!r}")
        if len(pts) >= 3:
            polys.append(pts)
    return polys


def rasterize(d, size, supersample=4):
    """Even-odd coverage of a 0-100 path as an 8-bit alpha image of size x size."""
    S = size * supersample
    k = S / UNITS
    acc = np.zeros((S, S), bool)
    for poly in _flatten(d):
        im = Image.new("1", (S, S), 0)
        ImageDraw.Draw(im).polygon([(x * k, y * k) for x, y in poly], fill=1)
        acc ^= np.asarray(im, bool)
    img = Image.fromarray((acc * 255).astype(np.uint8))
    return img.resize((size, size), Image.LANCZOS) if supersample > 1 else img


def _rings_mask(rings, px):
    """Plain polygon raster of the traced rings (no curve smoothing): what registration fits."""
    acc = np.zeros((px, px), bool)
    for l in rings:
        im = Image.new("1", (px, px), 0)
        ImageDraw.Draw(im).polygon([(x * px / UNITS, y * px / UNITS) for x, y in l], fill=1)
        acc ^= np.asarray(im, bool)
    return Image.fromarray(np.where(acc, 0, 255).astype(np.uint8))


def validate_reference(reference_path):
    """The fit needs a square colour icon whose figure sits on transparency."""
    img = Image.open(reference_path)
    if img.size[0] != img.size[1]:
        raise SystemExit(f"{reference_path}: {img.size} is not square; the adaptive-icon "
                         "canvas is, and the mark is fitted onto it")
    if "A" not in img.getbands():
        raise SystemExit(f"{reference_path}: no alpha channel. The mark is fitted onto the "
                         "figure's silhouette, so the colour icon must be a figure on transparency")
    alpha = np.asarray(img.convert("RGBA"))[:, :, 3]
    clear = float((alpha < 128).mean())
    if not 0.05 <= clear <= 0.95:
        raise SystemExit(f"{reference_path}: {clear:.0%} of it is transparent. Expected a figure "
                         "on a transparent canvas; a full-bleed or empty image has no "
                         "silhouette to fit onto")


def outline_iou(d, reference_path, size=512):
    """Overlap of the mark's outline with the colour icon's silhouette.

    The mark's white details are closed (a morphological closing wide enough for
    a headband band) and counted as covered wherever the colour icon is solid
    there, so only the outline decides. Generous by construction: a real gap
    inside a tight concave corner is excused too, so read it as an upper bound.
    """
    ref = np.asarray(Image.open(reference_path).convert("RGBA").resize((size, size), Image.LANCZOS))[:, :, 3] > 128
    m = np.asarray(rasterize(d, size)) > 128
    closed = Image.fromarray(np.where(m, 255, 0).astype(np.uint8)).copy()
    r = max(1, round(size * 24 / 512))
    for _ in range(r):
        closed = closed.filter(ImageFilter.MaxFilter(3))
    for _ in range(r):
        closed = closed.filter(ImageFilter.MinFilter(3))
    covered = m | ((np.asarray(closed) > 128) & ~m & ref)
    return float((covered & ref).sum() / max(1, (covered | ref).sum()))


def register(rings, reference_path):
    """Scale/offset (in reference-canvas units) that best overlays the mark on the colour icon."""
    mark = _rings_mask(rings, 800)

    def ref_mask(px):
        rgba = Image.open(reference_path).convert("RGBA").resize((px, px), Image.LANCZOS)
        return np.asarray(rgba)[:, :, 3] > 128

    def iou(ppu, a, tx, ty, C):
        n = max(1, int(round(UNITS * a * ppu)))
        m = np.asarray(mark.resize((n, n), Image.LANCZOS)) < 128
        P = C.shape[0]
        canvas = np.zeros_like(C)
        x, y = int(round(tx * ppu)), int(round(ty * ppu))
        x0, y0, x1, y1 = max(0, x), max(0, y), min(P, x + n), min(P, y + n)
        if x1 <= x0 or y1 <= y0:
            return 0.0
        canvas[y0:y1, x0:x1] = m[y0 - y:y1 - y, x0 - x:x1 - x]
        return float((canvas & C).sum() / (canvas | C).sum())

    # Start from matching bounding boxes, then search around that. The mark's own
    # box is its long edge = 100 units, centred.
    C = ref_mask(200)
    ys, xs = np.nonzero(C)
    rb = np.array([xs.min(), ys.min(), xs.max() + 1, ys.max() + 1]) / 2.0
    est = max(rb[2] - rb[0], rb[3] - rb[1]) / UNITS
    best = (0.0,)
    for a in np.arange(round(est - 0.08, 2), est + 0.08, 0.01):
        n = UNITS * a
        cx0, cy0 = (rb[0] + rb[2] - n) / 2, (rb[1] + rb[3] - n) / 2
        for tx in np.arange(math.floor(cx0 - 6), cx0 + 6.01, 1.0):
            for ty in np.arange(math.floor(cy0 - 6), cy0 + 6.01, 1.0):
                v = iou(2, a, tx, ty, C)
                if v > best[0]:
                    best = (v, a, tx, ty)
    C = ref_mask(400)
    _, a0, tx0, ty0 = best
    best = (0.0,)
    for a in np.arange(a0 - 0.012, a0 + 0.0121, 0.002):
        for tx in np.arange(tx0 - 1.5, tx0 + 1.51, 0.25):
            for ty in np.arange(ty0 - 1.5, ty0 + 1.51, 0.25):
                v = iou(4, a, tx, ty, C)
                if v > best[0]:
                    best = (v, a, tx, ty)
    return {"iou": best[0], "scale": float(best[1]), "tx": float(best[2]), "ty": float(best[3])}


# -------------------------------------------------------------------- outputs

GENERATED = ("Generated by ninja_material/scripts/generate_icons.py from icon_config.yml.\n"
             "Do not edit by hand: change the artwork or the config and re-run the script.")


def _xml_comment(text):
    body = "\n".join("  " + line for line in text.splitlines())
    if "--" in body:
        raise ValueError("XML comments cannot contain a double hyphen")
    return f"<!--\n{body}\n-->"


def svg_text(d, color):
    return (f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100">\n'
            f'{_xml_comment(GENERATED + chr(10) + "The 0-100 viewBox is the canvas of the colour icon, so the two overlay at equal size.")}\n'
            f'<path fill="{color}" fill-rule="evenodd" d="{d}"/>\n'
            f'</svg>\n')


def notification_vector_text(d):
    x0, y0, x1, y1 = path_bbox(d)
    s = 20.0 / max(x1 - x0, y1 - y0)
    tx, ty = 12 - s * (x0 + x1) / 2, 12 - s * (y0 + y1) / 2
    note = (GENERATED + "\n"
            "Android notification small icon. The system draws it as an alpha mask\n"
            "and supplies the colour, so only the shape matters. Framed on its own:\n"
            "long edge 20dp centred in 24dp, the Material system-icon live area.")
    return (f'<?xml version="1.0" encoding="utf-8"?>\n{_xml_comment(note)}\n'
            f'<vector xmlns:android="http://schemas.android.com/apk/res/android"\n'
            f'    android:width="24dp"\n    android:height="24dp"\n'
            f'    android:viewportWidth="24"\n    android:viewportHeight="24">\n'
            f'    <group\n'
            f'        android:scaleX="{s:.4f}"\n        android:scaleY="{s:.4f}"\n'
            f'        android:translateX="{tx:.4f}"\n        android:translateY="{ty:.4f}">\n'
            f'        <path\n            android:fillColor="#FFFFFFFF"\n'
            f'            android:fillType="evenOdd"\n'
            f'            android:pathData="{d}" />\n'
            f'    </group>\n</vector>\n')


def monochrome_image(d, size):
    alpha = rasterize(d, size)
    img = Image.new("RGBA", (size, size), (255, 255, 255, 0))
    img.putalpha(alpha)
    return img


# ----------------------------------------------------------------- repo glue

def load_config(app_dir):
    path = os.path.join(app_dir, CONFIG_NAME)
    if not os.path.exists(path):
        raise SystemExit(f"{path} not found")
    with open(path, encoding="utf-8") as fh:
        cfg = yaml.safe_load(fh) or {}
    for key in ("reference_icon", "brand_color", "svg", "monochrome_png"):
        if not cfg.get(key):
            raise SystemExit(f"{path}: missing required key '{key}'")
    return cfg


def _read_svg_path(path):
    m = re.search(r'\sd="([^"]+)"', open(path, encoding="utf-8").read())
    if not m:
        raise SystemExit(f"{path}: no path data")
    return m.group(1)


def _write(path, text):
    os.makedirs(os.path.dirname(path) or ".", exist_ok=True)
    with open(path, "w", encoding="utf-8", newline="\n") as fh:
        fh.write(text)


def generate(app_dir, cfg, preview_dir=None):
    p = lambda k: os.path.join(app_dir, cfg[k])
    validate_reference(p("reference_icon"))
    ref_size = Image.open(p("reference_icon")).size[0]

    if cfg.get("artwork"):
        if not os.path.exists(p("artwork")):
            raise SystemExit(f"{cfg['artwork']} (artwork) does not exist. Remove the key to "
                             "rebuild from the committed SVG instead of re-tracing.")
        opts = dict(TRACE_DEFAULTS, **(cfg.get("trace") or {}))
        d_norm, rings = trace(p("artwork"), opts)
        reg = register(rings, p("reference_icon"))
        d = transform_path(d_norm, reg["scale"], reg["tx"], reg["ty"])
        fit = outline_iou(d, p("reference_icon"))
        floor = float(cfg.get("min_fit_iou", MIN_FIT_IOU))
        if fit < floor:
            print(f"Fit onto {cfg['reference_icon']} is too poor to trust: outline overlap "
                  f"{fit:.3f} < {floor} (scale {reg['scale']:.3f}). Nothing was written.")
            print("The drawing and the colour icon probably do not show the same figure, or the "
                  "search window missed. If the drawing is genuinely looser, lower min_fit_iou "
                  "in icon_config.yml deliberately.")
            return 1
        _write(p("svg"), svg_text(d, cfg["brand_color"]))
        print(f"traced {len(rings)} rings, {len(d)} chars of path")
        print(f"fit onto {cfg['reference_icon']}: scale {reg['scale']:.3f}, offset "
              f"({reg['tx']:.2f}, {reg['ty']:.2f}), outline overlap {fit:.3f} "
              f"(raw pixel overlap {reg['iou']:.3f}, lower by design: the mark's white details)")
    else:
        if not os.path.exists(p("svg")):
            raise SystemExit(f"{cfg['svg']} does not exist and no artwork is configured: "
                             "there is nothing to build from")
        d = _read_svg_path(p("svg"))
        print(f"no artwork configured: rebuilding outputs from {cfg['svg']} (no tracing)")
    img = monochrome_image(d, ref_size)
    os.makedirs(os.path.dirname(p("monochrome_png")) or ".", exist_ok=True)
    img.save(p("monochrome_png"), optimize=True)
    if cfg.get("notification_vector"):
        _write(p("notification_vector"), notification_vector_text(d))
    if preview_dir:
        write_preview(app_dir, cfg, d, preview_dir)
    return 0


def write_preview(app_dir, cfg, d, out_dir):
    """Overlay on the colour icon plus the mark at notification sizes."""
    os.makedirs(out_dir, exist_ok=True)
    S = 648
    col = Image.open(os.path.join(app_dir, cfg["reference_icon"])).convert("RGBA").resize((S, S), Image.LANCZOS)
    base = Image.new("RGBA", (S, S), (255, 255, 255, 255))
    base.alpha_composite(col)
    red = Image.new("RGBA", (S, S), (230, 0, 0, 0))
    red.putalpha(Image.eval(rasterize(d, S), lambda v: int(v * 0.45)))
    base.alpha_composite(red)
    base.save(os.path.join(out_dir, "overlay.png"))
    sheet = Image.new("L", (24 + 48 + 96 + 60, 106), 255)
    x = 10
    for sz in (24, 48, 96):
        sheet.paste(Image.eval(rasterize(d, sz), lambda v: 255 - v), (x, 5))
        x += sz + 20
    sheet.resize((sheet.width * 3, sheet.height * 3), Image.NEAREST).save(os.path.join(out_dir, "sizes.png"))
    print(f"previews in {out_dir}")


def check(app_dir, cfg):
    p = lambda k: os.path.join(app_dir, cfg[k])
    problems = []
    for key in ("reference_icon", "svg", "monochrome_png") + (
            ("notification_vector",) if cfg.get("notification_vector") else ()):
        if not os.path.exists(p(key)):
            problems.append(f"{cfg[key]} ({key}) does not exist")
    if problems:
        return _report(problems)

    d = _read_svg_path(p("svg"))
    fill = re.search(r'fill="([^"]+)"', open(p("svg"), encoding="utf-8").read())
    if not fill or fill.group(1).lower() != str(cfg["brand_color"]).lower():
        problems.append(f"{cfg['svg']}: fill is not brand_color {cfg['brand_color']}")

    if cfg.get("notification_vector"):
        m = re.search(r'android:pathData="([^"]+)"', open(p("notification_vector"), encoding="utf-8").read())
        if not m or m.group(1) != d:
            problems.append(f"{cfg['notification_vector']}: path differs from {cfg['svg']}")

    png = Image.open(p("monochrome_png"))
    ref_size = Image.open(p("reference_icon")).size
    if png.size != ref_size:
        problems.append(f"{cfg['monochrome_png']}: {png.size} but the colour icon is {ref_size}; "
                        "the two must share one canvas")
    else:
        have = np.asarray(png.convert("RGBA"))[:, :, 3] > 128
        want = np.asarray(rasterize(d, png.size[0])) > 128
        iou = (have & want).sum() / max(1, (have | want).sum())
        if iou < 0.995:
            problems.append(f"{cfg['monochrome_png']}: does not match {cfg['svg']} (IoU {iou:.4f})")

    pubspec = os.path.join(app_dir, "pubspec.yaml")
    with open(pubspec, encoding="utf-8") as fh:
        fli = (yaml.safe_load(fh) or {}).get("flutter_launcher_icons") or {}
    if fli.get("adaptive_icon_monochrome") != cfg["monochrome_png"]:
        problems.append(f"pubspec.yaml: flutter_launcher_icons.adaptive_icon_monochrome should be "
                        f"{cfg['monochrome_png']}, is {fli.get('adaptive_icon_monochrome')!r}")
    if fli.get("adaptive_icon_foreground") != cfg["reference_icon"]:
        problems.append(f"pubspec.yaml: adaptive_icon_foreground is {fli.get('adaptive_icon_foreground')!r}, "
                        f"but the mark was fitted onto {cfg['reference_icon']}")
    return _report(problems)


def check_regenerated(app_dir, tolerance=1):
    """After flutter_launcher_icons has re-run: anything beyond PNG rounding is drift.

    The tool's resampler is not guaranteed to round a pixel identically on every
    OS, so a re-run PNG within `tolerance` (of 255) per channel of the committed
    one counts as unchanged. Anything else fails: a different size, a real pixel
    change, a text/XML edit, a new or deleted file.
    """
    import io as _io
    import subprocess
    out = subprocess.run(["git", "status", "--porcelain"], cwd=app_dir,
                         capture_output=True, text=True, check=True).stdout.splitlines()
    problems = []
    for line in out:
        code, path = line[:2].strip(), line[3:].strip().strip('"')
        if code == "M" and path.lower().endswith(".png"):
            head = subprocess.run(["git", "show", f"HEAD:{path}"], cwd=app_dir,
                                  capture_output=True, check=True).stdout
            a = np.asarray(Image.open(_io.BytesIO(head)).convert("RGBA"), dtype=np.int16)
            b = np.asarray(Image.open(os.path.join(app_dir, path)).convert("RGBA"), dtype=np.int16)
            if a.shape == b.shape and int(np.abs(a - b).max()) <= tolerance:
                continue
            problems.append(f"{path}: pixels changed (not just rounding)")
        else:
            what = "modified" if code == "M" else "added or removed"
            problems.append(f"{path}: {what} by re-running flutter_launcher_icons")
    if problems:
        problems.append("The committed launcher icons no longer come from pubspec.yaml: run "
                        "flutter_launcher_icons and commit the result, or fix the config.")
    return _report(problems, ok="Launcher icons match the flutter_launcher_icons config.")


def _report(problems, ok="Icon check passed."):
    if problems:
        print("Icon check FAILED:")
        for pr in problems:
            print(f"  - {pr}")
        print("Fix the config or re-run: python generate_icons.py --repo <app>")
        return 1
    print(ok)
    return 0


def main():
    ap = argparse.ArgumentParser(description=__doc__.split("\n\n")[0])
    where = ap.add_mutually_exclusive_group(required=True)
    where.add_argument("--repo", help="app directory name next to ninja_material")
    where.add_argument("--app-dir", help="path to the app repo (CI)")
    ap.add_argument("--check", action="store_true", help="verify only, never write")
    ap.add_argument("--check-regenerated", action="store_true",
                    help="CI, after flutter_launcher_icons re-ran: fail on anything but PNG rounding")
    ap.add_argument("--preview", metavar="DIR", help="also write preview PNGs to DIR")
    args = ap.parse_args()

    app_dir = os.path.abspath(args.app_dir) if args.app_dir else os.path.join(REPOS_DIR, args.repo)
    if not os.path.isdir(app_dir):
        hint = (f"--repo resolves next to ninja_material, so expected {app_dir}; clone the app "
                "beside ninja_material or pass --app-dir") if args.repo else "check the --app-dir path"
        raise SystemExit(f"{app_dir} is not a directory ({hint})")
    if args.check_regenerated:
        sys.exit(check_regenerated(app_dir))
    cfg = load_config(app_dir)
    sys.exit(check(app_dir, cfg) if args.check else generate(app_dir, cfg, args.preview))


if __name__ == "__main__":
    main()
