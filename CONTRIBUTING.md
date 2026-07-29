# Contributing

This is a documentation repository. The most valuable contributions are small and boring: a fixed link, a corrected version number, a tool that should be in the catalogue.

## Ground rules

1. **No code.** No install scripts, no IOC templates, no Dockerfiles. Upstream maintains those better than we can. Inline commands in the how-to pages are fine — they are meant to be read, then typed.
2. **Link, don't copy.** If upstream documents something, link to upstream. Duplicated documentation goes stale silently and misleads people. Add just enough context that a reader knows *why* they should click.
3. **Say when you don't know.** "This is untested on RHEL" is more useful than confident guessing. Mark uncertainty with a `!!! warning` admonition.
4. **Every tool entry needs**: what it is, who maintains it, what problem it solves, and a link that resolves. Prefer the project's own docs site over its README, and the README over a conference slide deck.
5. **Keep the Helios Light Source consistent.** The [example facility](docs/example-facility/) is fictional but internally coherent — magnet counts, PV counts, and IOC counts are cross-referenced between pages. If you change a number on one page, grep for it and fix the others.
6. **Nothing safety-related.** Do not add guidance on designing interlocks, personnel protection, or machine protection logic. Point at standards (IEC 61508 / IEC 61511) and the vendors, and stop there.

## Repository layout

```text
docs/
  start-here/        Newcomer on-ramp: concepts, glossary, FAQ
  architecture/      How the pieces relate: protocols, database, naming, networking
  toolbox/           The catalogue — one page per category of tool
  build-install/     Practical how-tos, one page per component
  example-facility/  The Helios Light Source worked example
  reference/         Cheat sheets, official docs, training, community
mkdocs.yml           Site config and navigation
```

Adding a page means adding it to `nav:` in [`mkdocs.yml`](mkdocs.yml) — otherwise it builds but nobody can find it.

**Two kinds of landing page.** Each section uses `index.md` as its landing page on the built site. A section may *also* carry a `README.md`, which exists only so the directory is browsable on GitHub — mkdocs warns fatally under `--strict` when both live in one directory, so `exclude_docs` in `mkdocs.yml` keeps READMEs out of the build. Consequences for contributors:

- A `README.md` is never in `nav:` and its links are not checked by `mkdocs build --strict`. Check them by hand.
- Keep a README to an overview and a file map. Anything substantive belongs in a chapter, linked from both, so the two can't drift apart.

## Local preview

```bash
pip install -r requirements.txt
mkdocs serve          # http://127.0.0.1:8000
mkdocs build --strict # fails on broken internal links; run before opening a PR
```

Install from [`requirements.txt`](requirements.txt) rather than `pip install mkdocs-material` — the versions are pinned so local previews match CI, and the site uses a plugin (`git-revision-date-localized`, for the last-updated stamp on each page) that a bare install won't provide.

`--strict` catches broken *internal* links and nav entries pointing at files that don't exist; [`.github/workflows/build.yml`](.github/workflows/build.yml) runs it on every pull request. External links are checked monthly by [`.github/workflows/link-check.yml`](.github/workflows/link-check.yml).

## Style

- Sentence case for headings. American or British spelling, whichever the surrounding page uses.
- Relative links between pages (`../toolbox/archiving.md`), so both GitHub and the built site work.
- PV names in `code` formatting. Facility and product names in plain text.
- Tables for catalogues, prose for explanations. A table with one column of paragraphs is prose wearing a costume.
- Humour is allowed. The original README had jokes in it; they can stay.
