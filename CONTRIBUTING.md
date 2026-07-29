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

## Local preview

```bash
pip install mkdocs-material
mkdocs serve          # http://127.0.0.1:8000
mkdocs build --strict # fails on broken internal links; run before opening a PR
```

`--strict` catches broken *internal* links and nav entries pointing at files that don't exist. External links are checked monthly by [`.github/workflows/link-check.yml`](.github/workflows/link-check.yml).

## Style

- Sentence case for headings. American or British spelling, whichever the surrounding page uses.
- Relative links between pages (`../toolbox/archiving.md`), so both GitHub and the built site work.
- PV names in `code` formatting. Facility and product names in plain text.
- Tables for catalogues, prose for explanations. A table with one column of paragraphs is prose wearing a costume.
- Humour is allowed. The original README had jokes in it; they can stay.
