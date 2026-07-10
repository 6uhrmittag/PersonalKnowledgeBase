# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this is

A personal knowledge base published at https://slashlog.org — Markdown notes rendered client-side by [docsify](https://docsify.js.org). There is no build step, no tests, and no lint: GitHub Pages serves the `docs/` directory as-is (`docs/CNAME` sets the custom domain, `docs/.nojekyll` disables Jekyll). Content is public.

## Commands

```bash
npm i docsify-cli -g   # one-time install
docsify serve docs     # local preview at http://localhost:3000
```

Link checking runs monthly in CI (lychee, `.github/workflows/check-links.yml`) and opens a GitHub issue on failures. URL exclusions live in `docs/.lychee.toml`.

## Structure & conventions

- All content lives in `docs/`, one directory per topic. Each directory's `README.md` is its index page (docsify maps `dir/` → `dir/README.md`).
- **Navigation is manual.** `docs/_sidebar.md` is the single global sidebar for the entire site (every subdirectory aliases to it via the config in `index.html`). A new page is unreachable until it is linked from `_sidebar.md` or from another page.
- All docsify configuration is in `docs/index.html`. Plugins (search, TOC, pagination, copy-code, image zoom, flexible alerts, word count, glossary, last-modified timestamp) are vendored locally under `docs/assets/js/` and `docs/assets/css/` — not loaded from CDNs.
- Pages may use docsify-specific syntax, e.g. file embedding (`[filename](blog/til/README.md ':include')`) and flexible-alert blocks — plain-Markdown renderers won't show these correctly, so verify such pages with `docsify serve`.
- Notes are a mix of English and German; match the language and informal tone of the page being edited.
- Commit messages follow the existing short style: `add: <what>` / `fix: <what>`.

## Nested projects

Some subdirectories are self-contained projects with their own `CLAUDE.md` (e.g. `docs/gaming/recording/FragPunk/`). When working inside one, that file's instructions take precedence for that directory.
