# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added

- `brand/`: the JuliaGiac visual identity and its generator, moved from
  JuliaGiac/.github.
- `hugo/`: templates and styles shared by https://juliagiac.github.io/ and
  the giac and libgiac-julia-wrapper sites.
- `documenter/juliagiac.css`: the JuliaGiac palette for Documenter and
  DocumenterLandingPage.
- `sync.jl`: copies the shared files into a site (`hugo-home`,
  `hugo-project`, `documenter`), with `--check` for CI and `--keep-logo` for
  packages that have their own logo.
