# Generates the JuliaGiac visual identity into brand/assets/.
#
#     julia --project=brand brand/make_brand.jl
#
# The mark is a "G" whose crossbar is the overline of a square root sign, with
# the three Julia dots above its opening: Giac (symbolic computation) in Julia.
# Every asset is drawn from the same geometry below, so changing a constant
# here and re-running the script updates all of them.

using Luxor

const ASSETS = joinpath(@__DIR__, "assets")

# ── Palette ──────────────────────────────────────────────────────────────────
# Julia's logo colours for the dots, a near-black and an off-white for the
# mark itself.
const JULIA_RED = "#CB3C33"
const JULIA_GREEN = "#389826"
const JULIA_PURPLE = "#9558B2"
const INK = "#222326"        # mark on light backgrounds, dark backgrounds
const PAPER = "#F5F5F7"      # mark on dark backgrounds
const MUTED = "#A0A4A8"      # secondary text on dark backgrounds

# ── Geometry ─────────────────────────────────────────────────────────────────
# In units of the ring radius R, origin at the ring centre, y pointing down
# (Luxor's convention). Angles in degrees, clockwise from 3 o'clock.
const RING_WIDTH = 0.34      # stroke width of the G
const ROOT_WIDTH = 0.20      # stroke width of the square root sign
# The ring runs clockwise from the crossbar (3 o'clock) to the opening, top
# right. It ends round at the opening and flat at the crossbar, squared off
# level with the bar's top edge so the bar runs into it without a bump.
const RING_START = 0.0
const RING_END = 305.0
# The square root sign: a short tick, a down stroke and an up stroke that ends
# on the crossbar, whose overline is the G's crossbar.
const ROOT = [(-0.68, 0.22), (-0.52, 0.12), (-0.30, 0.54), (-0.04, 0.0)]
const BAR_END = 1.0          # the crossbar joins the ring on the right
const DOT_RADIUS = 0.15
const DOTS = [((0.02, -1.48), JULIA_RED),
              ((0.48, -1.46), JULIA_GREEN),
              ((0.90, -1.28), JULIA_PURPLE)]

# Bounding box of the mark, in units of R, used to centre and scale it.
function mark_bounds()
    half = RING_WIDTH / 2
    xs = [-1 - half, 1 + half]
    ys = [-1 - half, 1 + half]
    for ((x, y), _) in DOTS
        append!(xs, (x - DOT_RADIUS, x + DOT_RADIUS))
        append!(ys, (y - DOT_RADIUS, y + DOT_RADIUS))
    end
    return minimum(xs), maximum(xs), minimum(ys), maximum(ys)
end

"""
    draw_mark(centre, size, fg)

Draw the mark so that its bounding box is `size` points on its longer side,
centred on `centre`, with the G and the root sign in colour `fg`.
"""
function draw_mark(centre::Point, size::Real, fg)
    xmin, xmax, ymin, ymax = mark_bounds()
    R = size / max(xmax - xmin, ymax - ymin)
    # Ring centre such that the bounding box is centred on `centre`.
    o = centre - Point((xmin + xmax) / 2, (ymin + ymax) / 2) * R
    P(x, y) = o + Point(x, y) * R

    @layer begin
        sethue(fg)
        setlinecap("round")
        setlinejoin("round")

        # The G: an open ring, flat where the crossbar meets it and round at
        # the opening.
        setline(RING_WIDTH * R)
        setlinecap("butt")
        newpath()
        arc(o, R, deg2rad(RING_START), deg2rad(RING_END), :none)
        strokepath()
        circle(o + polar(R, deg2rad(RING_END)), RING_WIDTH * R / 2, :fill)
        # Overlaps the ring by 0.03 R so no anti-aliasing seam shows.
        box(P(1.0, (0.03 - ROOT_WIDTH / 2) / 2), RING_WIDTH * R,
            (ROOT_WIDTH / 2 + 0.03) * R, :fill)
        setlinecap("round")
        # The square root sign, whose overline is the G's crossbar: one
        # stroke, so the corner where they meet is a clean join.
        setline(ROOT_WIDTH * R)
        newpath()
        poly([[P(p...) for p in ROOT]; P(BAR_END, 0.0)], :stroke)
    end

    # The three Julia dots.
    for ((x, y), colour) in DOTS
        @layer begin
            sethue(colour)
            circle(P(x, y), DOT_RADIUS * R, :fill)
        end
    end
end

# ── Assets ───────────────────────────────────────────────────────────────────

# The mark alone, on a transparent background, in SVG and PNG.
function mark(name, fg; px = 1024, margin = 0.08)
    for ext in ("svg", "png")
        Drawing(px, px, joinpath(ASSETS, "$name.$ext"))
        origin()
        background(1, 1, 1, 0)
        draw_mark(O, px * (1 - 2margin), fg)
        finish()
    end
end

# The mark on a dark square, for avatars and icons. `radius` rounds the
# corners (0 for a plain square, which GitHub crops to a circle or rounds
# itself).
function tile(name, px; radius = 0.0, exts = ("svg", "png"), margin = 0.14)
    for ext in exts
        Drawing(px, px, joinpath(ASSETS, "$name.$ext"))
        origin()
        background(1, 1, 1, 0)
        sethue(INK)
        if radius > 0
            box(O, px, px, radius * px, :fill)
        else
            box(O, px, px, :fill)
        end
        draw_mark(O, px * (1 - 2margin), PAPER)
        finish()
    end
end

# GitHub social preview (1280×640): mark on the left, name and tagline on the
# right. Text uses the system's sans-serif font.
function social_preview(name; w = 1280, h = 640)
    Drawing(w, h, joinpath(ASSETS, "$name.png"))
    origin()
    background(INK)
    draw_mark(Point(-w / 4 - 60, 0), h * 0.62, PAPER)
    x = -130
    fontface("Sans")
    sethue(PAPER)
    fontsize(104)
    text("JuliaGiac", Point(x, 10), halign = :left)
    sethue(MUTED)
    fontsize(32)
    text("The Giac computer algebra system, in Julia", Point(x, 80),
         halign = :left)
    finish()
end

function main()
    mkpath(ASSETS)
    mark("juliagiac-mark", INK)              # for light backgrounds
    mark("juliagiac-mark-light", PAPER)      # for dark backgrounds
    tile("juliagiac-avatar", 1024)           # GitHub organisation avatar
    tile("favicon", 64; radius = 0.22)       # favicon.svg / favicon.png
    tile("apple-touch-icon", 180; radius = 0.0, exts = ("png",))
    social_preview("social-preview")
    for f in sort(readdir(ASSETS))
        println(rpad(f, 28), filesize(joinpath(ASSETS, f)), " bytes")
    end
end

main()
