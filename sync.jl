# Copy the JuliaGiac shared site files into a consuming repository.
#
#     julia sync.jl <kind> <target> [--keep-logo] [--check]
#
# <kind>     what <target> is:
#   hugo-home      the Hugo site of https://juliagiac.github.io/ (repository root)
#   hugo-project   a project's Hugo site (e.g. giac/site, libgiac-julia-wrapper/site)
#   documenter     a package's Documenter `docs/` directory
# --keep-logo  documenter only: keep the package's own logo.svg / logo-dark.svg
# --check      change nothing; exit with status 1 if any copy is missing or
#              differs from this kit (for CI)
#
# Text files (CSS, templates) get a header saying they are managed here, so
# nobody edits a copy by mistake. Only Julia's standard library is used.

const KIT = @__DIR__
const BRAND = joinpath(KIT, "brand", "assets")

# (source in the kit, destination relative to <target>)
const BRAND_IMAGES = [
    "favicon.svg", "favicon.png", "apple-touch-icon.png",
    "juliagiac-mark.svg", "juliagiac-mark-light.svg", "social-preview.png",
]

function files(kind::String, keep_logo::Bool)
    hugo_static = [
        (joinpath("hugo", "static", "style.css"), joinpath("static", "style.css")),
        (joinpath("hugo", "static", "syntax.css"), joinpath("static", "syntax.css")),
    ]
    hugo_images = [(joinpath("brand", "assets", f), joinpath("static", "img", f))
                   for f in BRAND_IMAGES]
    if kind == "hugo-home"
        return [hugo_static; hugo_images]
    elseif kind == "hugo-project"
        layouts = [(joinpath("hugo", "layouts", p), joinpath("layouts", p))
                   for p in (joinpath("_default", "baseof.html"),
                             joinpath("_default", "single.html"), "index.html")]
        return [hugo_static; hugo_images; layouts]
    elseif kind == "documenter"
        assets = joinpath("src", "assets")
        out = [(joinpath("documenter", "juliagiac.css"), joinpath(assets, "juliagiac.css")),
               (joinpath("brand", "assets", "favicon.png"), joinpath(assets, "favicon.png"))]
        keep_logo || append!(out, [
            (joinpath("brand", "assets", "juliagiac-mark.svg"), joinpath(assets, "logo.svg")),
            (joinpath("brand", "assets", "juliagiac-mark-light.svg"), joinpath(assets, "logo-dark.svg"))])
        return out
    end
    error("unknown kind `$kind`: use hugo-home, hugo-project or documenter")
end

function header(src::String)
    note = "Managed by JuliaGiac/site-kit ($src). Edit it there, then run sync.jl."
    endswith(src, ".css") && return "/* $note */\n"
    endswith(src, ".html") && return "{{/* $note */}}\n"
    return nothing
end

# The bytes a copy should contain.
function expected(src::String)
    bytes = read(joinpath(KIT, src))
    h = header(replace(src, '\\' => '/'))
    return h === nothing ? bytes : vcat(Vector{UInt8}(h), bytes)
end

function main(args)
    check = "--check" in args
    keep_logo = "--keep-logo" in args
    positional = filter(a -> !startswith(a, "--"), args)
    length(positional) == 2 || (println(stderr,
        "usage: julia sync.jl <hugo-home|hugo-project|documenter> <target> [--keep-logo] [--check]");
        exit(2))
    kind, target = positional
    isdir(target) || error("target directory not found: $target")
    stale = String[]
    for (src, dst) in files(kind, keep_logo)
        path = joinpath(target, dst)
        want = expected(src)
        isfile(path) && read(path) == want && continue
        if check
            push!(stale, dst)
        else
            mkpath(dirname(path))
            write(path, want)
            println("updated ", dst)
        end
    end
    if check
        isempty(stale) && (println("up to date"); return)
        println(stderr, "out of date with JuliaGiac/site-kit: ", join(stale, ", "))
        exit(1)
    end
end

main(ARGS)
