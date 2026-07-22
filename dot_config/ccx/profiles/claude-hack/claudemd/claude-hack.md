# Claude Code Plugin Development

Building and distributing my own Claude Code plugins (skills, commands, agents, hooks, MCP servers).

## Plugin structure

- A plugin is a directory with a `plugin.json` manifest (name, version, description) at its root.
- Ships any of: `skills/<name>/SKILL.md` (model-invocable + `/name`), `commands/*.md` (slash commands),
  `agents/*.md` (subagent definitions), `hooks/`, and MCP server config.
- Prefer `skills/<name>/SKILL.md` over `commands/*.md` for new work — skills support both `/name`
  invocation and autonomous use. Use `disable-model-invocation: true` to make a skill CLI-only.
- Use the `skill-creator` plugin (enabled here) to scaffold new skills.

## Distribution — multiple marketplaces

My plugins are published across several marketplaces (claude-garden, claude-secret-garden,
cloudbees-marketplace, etc.). A release is only done when ALL of these are in lockstep:

- **Version** bumped in `plugin.json` (semver).
- **Marketplace catalog** entry updated (the marketplace's `plugin-catalog`/manifest) to the new version.
- **Metadata** (description, keywords, category) consistent between `plugin.json` and the catalog.
- **README** reflects new commands/skills/flags — no drift from actual behavior.
- **CHANGELOG** entry for the version.

Before shipping, cross-check that plugin.json version, catalog version, and README all agree. A version
bump that misses the catalog leaves users on the old version.
