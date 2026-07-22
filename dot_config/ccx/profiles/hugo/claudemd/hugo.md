# Hugo Conventions

## Structure

- `content/` markdown + page bundles · `layouts/` templates · `themes/` themes ·
  `static/` copied verbatim · `assets/` pipeline-processed · `data/` · `archetypes/`.
- Config: root `hugo.toml`, or `config/_default/` for split/environment config.
- Never hand-edit `public/` or `resources/` — regenerated on every build.
- Override a theme file by copying it to the same relative path in the project.

## Dev Loop

- `hugo server` serves on :1313 with LiveReload. Use `-D` / `-F` / `-E` to preview
  drafts / future / expired content — leave these OFF for production.
- Hugo does not clear `public/` before building; purge it before a production build to
  drop stale draft/future/expired files.

## Docs

- Hugo docs: https://gohugo.io/documentation/
