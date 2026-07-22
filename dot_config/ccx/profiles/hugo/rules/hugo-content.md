---
description: "Hugo content authoring — frontmatter, page bundles, markdown rendering"
globs: "content/**/*.md"
---

# Hugo Content Authoring

## Frontmatter

- The delimiter picks the format: `---` YAML, `+++` TOML. Pick one and stay consistent.
- Use parsable dates (`2023-10-15` or full RFC 3339). Reserved names (e.g. `type`) can't
  be reused for custom fields — put custom fields under `params`.

## Page Bundles

- Leaf bundle `index.md` = a self-contained page that owns its assets (a post with images).
- Branch bundle `_index.md` = a section / list page (home, section, taxonomy).
- Don't confuse the two. Filenames become URL slugs — keep them URL-friendly.

## Markdown (Goldmark / CommonMark)

- Raw HTML is sandboxed and silently dropped unless
  `markup.goldmark.renderer.unsafe: true` is set.
- Shortcodes are called from content (`{{< name >}}`); partials from templates. Don't mix.
