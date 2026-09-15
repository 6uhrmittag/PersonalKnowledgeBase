# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repo is

The repo owner's personal knowledge base — the "persistent knowledge" they want available on every machine without looking it up elsewhere. Content is Markdown under `docs/`, rendered client-side by [docsify](https://docsify.js.org/) and published via GitHub Pages at **slashlog.org** (`docs/CNAME`, `docs/.nojekyll`).

There is no build step, no package.json, no tests. `docs/` *is* the site — what is committed is what is served.

## Commands

```bash
npm i docsify-cli -g      # one-time
docsify serve docs        # local preview at http://localhost:3000
```

Link checking runs in CI only (monthly). To reproduce locally with [lychee](https://github.com/lycheeverse/lychee) installed:

```bash
lychee --verbose "docs/**/*.md" --insecure --config docs/.lychee.toml
```

## Architecture

**`docs/index.html` is the entire application.** It holds the docsify config block and every `<script>`/`<link>` tag. Points that matter when editing content:

- **Single global sidebar.** `loadSidebar: true` plus the alias `'/.*/_sidebar.md': '/_sidebar.md'` means *every* route renders `docs/_sidebar.md`. A new page is unreachable through navigation unless it is added there — it will only turn up via search or a direct URL.
- **`maxLevel: 2`** — the auto-generated per-page TOC in the sidebar covers `h1`/`h2` only; `subMaxLevel: 0` disables nested sidebar entries. The separate `docsify-plugin-toc` renders a full `h1`–`h6` table of contents in the page body.
- **Plugins are vendored, not CDN-loaded.** Everything lives in `docs/assets/js/` and `docs/assets/css/`. Adding a plugin means downloading the dist file into `assets/js/` and adding a `<script>` tag — do not introduce CDN URLs (the site works offline and CDN links would also be hit by the link checker).
- **Alias `/_glossary` → `/booknotes/books`** feeds `docsify-glossary.js`.
- A service-worker unregister shim runs on load; the old PWA (`assets/js/sw.js`) is intentionally disabled.

## Content conventions

Follow these when adding or editing notes:

- **Folder index pages are `README.md`.** Sidebar links to a directory (`[Tools](tools/)`) resolve to that folder's `README.md`.
- **Register every new page in `docs/_sidebar.md`** under the matching top-level group, using paths relative to `docs/`.
- **Aggregation via docsify includes:** a folder README can pull in sibling files with `[filename](./LogitechBrio.md ':include')` — see `docs/things/README.md`. Files included this way still get their own sidebar entry only if you add one.
- **Callouts** come from `docsify-plugin-flexible-alerts`: `!>` for important/warning, `?>` for tip/note. Used heavily as a "this is stale / this is my personal caveat" marker.
- **Code fences use four backticks, not three**, almost everywhere, with a language hint (`powershell`, `bash`, `text`). Match that.
- **Binary assets** sit next to the note: either a `images/` folder (`docs/blog/dev/images/`) or a Typora-style `<notename>.assets/` folder (`docs/tools/bsi.assets/`, `docs/things/Waschmaschine-….assets/`). Reference them with relative paths.
- **Language is mixed.** Most notes are English; the `docs/trans/` section is German. Keep a page in the language it is already written in.
- `.editorconfig` enforces LF endings and a final newline.

## Adding new project ideas and drafts

Coding projects normally get their own GitHub repo. Early-stage project ideas and drafts belong here instead, so they are readable from any PC:

- Put them in **`docs/in-progress/`** (create the folder with a `README.md` index if it does not exist yet).
- Add a top-level **`In Progress`** group to `docs/_sidebar.md` linking `in-progress/` plus each draft page.
- Once a draft graduates into a real project, it typically moves out to its own repo — leave a stub or link behind rather than deleting the history.

## CI

- `.github/workflows/check-links.yml` — lychee over `docs/**/*.md` on the 1st of each month; a failure opens a "Link Checker Report" issue. Known-bad or unverifiable URLs are allow-listed in `docs/.lychee.toml`, so add exclusions there rather than deleting a useful link.
- `.github/workflows/archive-github-pages.yml` — pushes slashlog.org to the Wayback Machine on published releases (or manual dispatch).

## Git

Commit subjects follow a loose `add: <thing>` / `fix: <thing>` style. Work happens on topic branches (`fix-synthriderz`, `feature-recording-fragpunk`) merged into `master`.

**On any branch other than `master`, commit your changes without being asked** — a short one-line summary of what changed is enough, no body needed. On `master`, ask first.
