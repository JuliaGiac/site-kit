# JuliaGiac site kit.

# List recipes
default:
    @just --list

# Regenerate the visual identity into brand/assets/
brand:
    julia --project=brand -e 'using Pkg; Pkg.instantiate()'
    julia --project=brand brand/make_brand.jl

# Copy the shared files into a repository: just sync hugo-project ../giac/site
sync kind target *flags:
    julia sync.jl {{kind}} {{target}} {{flags}}

# Check that a repository's copies are up to date
check kind target *flags:
    julia sync.jl {{kind}} {{target}} {{flags}} --check
