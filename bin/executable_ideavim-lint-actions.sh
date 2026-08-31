#!/usr/bin/env bash
#
# Lint .ideavimrc against the installed IDE.
#
# IdeaVim silently no-ops a mapping whose <Action>(id) does not exist: no error,
# no notification. That makes the rc rot invisibly at every IDE upgrade. This
# harvests the real action-ID registry out of the installed jars and reports any
# mapping that points at nothing, plus two structural traps that also fail
# silently.
#
# Run after an IDE upgrade, or let chezmoi run it when the rc changes.

set -euo pipefail

RC="${1:-$HOME/.ideavimrc}"

die() {
	printf '✗ %s\n' "$1" >&2
	exit 2
}

find_ide_home() {
	local candidate
	for candidate in "$HOME"/.local/share/JetBrains/Toolbox/apps/*/; do
		[[ -f "${candidate}build.txt" ]] && {
			printf '%s' "${candidate%/}"
			return 0
		}
	done
	return 1
}

[[ -r "$RC" ]] || die "cannot read $RC"

IDE_HOME="$(find_ide_home)" || die "no JetBrains Toolbox IDE found under ~/.local/share/JetBrains/Toolbox/apps"
IDE_BUILD="$(<"$IDE_HOME/build.txt")"

# Pin to the version this build actually reads. Globbing IntelliJIdea* instead
# unions every past version's plugin directory, so a plugin uninstalled from the
# current version keeps on validating.
DATA_DIR="$(grep -oP '"dataDirectoryName"\s*:\s*"\K[^"]+' "$IDE_HOME/product-info.json" | head -1)"
[[ -n "$DATA_DIR" ]] || die "no dataDirectoryName in $IDE_HOME/product-info.json"

USER_PLUGIN_DIR="$HOME/.local/share/JetBrains/$DATA_DIR"
DISABLED_FILE="$HOME/.config/JetBrains/$DATA_DIR/disabled_plugins.txt"

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

ACTION_IDS="$WORK/action-ids"
TOOL_WINDOW_IDS="$WORK/tool-window-ids"
: >"$ACTION_IDS"
: >"$TOOL_WINDOW_IDS"

# disabled_plugins.txt holds plugin IDs, one per line. Entries under
# com.intellij.modules.* are platform module aliases rather than installable
# plugins, so they are ignored: treating one as a disabled plugin would discard
# a large slice of the core action registry.
DISABLED_IDS="$WORK/disabled-ids"
: >"$DISABLED_IDS"
if [[ -r "$DISABLED_FILE" ]]; then
	grep -vE '^\s*$|^com\.intellij\.modules\.' "$DISABLED_FILE" >"$DISABLED_IDS" || true
fi

# Every *.xml in the jar is read, not just META-INF: plenty of IDs (Run, Debug,
# Coverage…) are registered in code and only ever appear as <action id="…"> in
# keymaps/$default.xml. Descriptors are streamed rather than extracted to disk —
# extracting collides on filename (every plugin ships META-INF/plugin.xml) and
# silently loses registries.
jar_count=0
skipped=()

# Harvested per plugin, not per jar, because whether an ID counts depends on the
# owning plugin being enabled — and that is only knowable once the whole plugin
# has been read. Registries land in a staging file and are promoted only if the
# plugin is enabled.
#
# Every *.xml in the jar is read, not just META-INF: plenty of IDs (Run, Debug,
# RunCoverage…) are registered in code and only ever appear as <action id="…"> in
# keymaps/$default.xml. Descriptors are streamed rather than extracted to disk —
# extracting collides on filename (every plugin ships META-INF/plugin.xml) and
# silently loses registries.
harvest_plugin() {
	local dir="$1" jar xml
	local staged_actions="$WORK/staged-actions" staged_tw="$WORK/staged-tw" ids="$WORK/staged-ids"
	: >"$staged_actions"
	: >"$staged_tw"
	: >"$ids"

	while read -r jar; do
		xml="$(unzip -p "$jar" '*.xml' 2>/dev/null)" || continue
		jar_count=$((jar_count + 1))
		grep -oP '<(?:action|group|reference)\b[^>]*\bid="\K[^"]+' <<<"$xml" >>"$staged_actions" || true
		# Some tool windows (Maven) are registered in code and only appear in the
		# allowlist / extractor-mode extension points, never as <toolWindow>.
		grep -oP '<toolWindow(?:Allowlist|ExtractorMode)?\b[^>]*\bid="\K[^"]+' <<<"$xml" >>"$staged_tw" || true
		# <id> as a direct child of <idea-plugin>: the plugin's own identity.
		grep -oP '^\s{0,4}<id>\K[^<]+' <<<"$xml" >>"$ids" || true
	done < <(find -L "$dir" -maxdepth 2 -name '*.jar' -type f)

	if [[ -s "$DISABLED_IDS" ]] && grep -qxF -f "$DISABLED_IDS" "$ids" 2>/dev/null; then
		skipped+=("${dir##*/}")
		return 0
	fi

	cat "$staged_actions" >>"$ACTION_IDS"
	cat "$staged_tw" >>"$TOOL_WINDOW_IDS"
}

plugin_dirs() {
	local dir
	for dir in "$IDE_HOME/lib" "$IDE_HOME"/plugins/*/ "$USER_PLUGIN_DIR"/*/; do
		[[ -d "$dir" ]] || continue
		printf '%s\n' "${dir%/}"
	done
}

printf '→ IDE %s (%s), plugins for %s\n' "$IDE_BUILD" "$IDE_HOME" "$DATA_DIR"
printf '→ %d plugin(s) disabled and excluded from the registry\n' "$(wc -l <"$DISABLED_IDS")"
printf '→ harvesting action IDs from jars…\n'

while read -r dir; do
	harvest_plugin "$dir"
done < <(plugin_dirs)

# Single-jar plugins sit loose in the user plugin directory with no dir of their
# own. Each gets a scratch directory named after the jar so it is staged — and
# reported when skipped — as the individual plugin it is.
while read -r jar; do
	loose_dir="$WORK/loose/${jar##*/}"
	mkdir -p "$loose_dir"
	ln -s "$jar" "$loose_dir/"
	harvest_plugin "$loose_dir"
done < <(find "$USER_PLUGIN_DIR" -maxdepth 1 -name '*.jar' -type f 2>/dev/null)

if ((${#skipped[@]} > 0)); then
	printf '→ skipped disabled: %s\n' "${skipped[*]}"
fi

sort -u -o "$ACTION_IDS" "$ACTION_IDS"
sort -u -o "$TOOL_WINDOW_IDS" "$TOOL_WINDOW_IDS"

printf '→ %d jars, %d action IDs, %d tool windows\n' \
	"$jar_count" "$(wc -l <"$ACTION_IDS")" "$(wc -l <"$TOOL_WINDOW_IDS")"

[[ -s "$ACTION_IDS" ]] || die "harvested no action IDs at all — the jar layout has changed"

failures=0

# Activate<id>ToolWindow action IDs are generated at runtime from the declared
# tool windows and never appear in any XML, so they are resolved separately.
resolves() {
	local id="$1" tw
	grep -qxF "$id" "$ACTION_IDS" && return 0
	if [[ "$id" =~ ^Activate(.+)ToolWindow$ ]]; then
		tw="${BASH_REMATCH[1]}"
		grep -qxF "$tw" "$TOOL_WINDOW_IDS" && return 0
		# Declared IDs may contain spaces that the action ID strips.
		tr -d ' ' <"$TOOL_WINDOW_IDS" | grep -qxF "$tw" && return 0
	fi
	return 1
}

printf '→ checking <Action> IDs in %s…\n' "$RC"
while read -r id; do
	resolves "$id" || {
		printf '✗ missing action: %s\n' "$id"
		grep -n "<Action>($id)" "$RC" | sed 's/^/    /'
		failures=$((failures + 1))
	}
done < <(grep -oP '<Action>\(\K[^)]+' "$RC" | sort -u)

# `map <leader>x<Action>(Foo)` with no space is parsed as a list-mappings query,
# so the mapping silently does not exist.
printf '→ checking for <Action> abutting the lhs…\n'
if glued="$(grep -nP '^\s*[nxvoi]?(nore)?map\s+\S+<Action>\(' "$RC")"; then
	printf '✗ <Action> with no space before it (parsed as a list-mappings query):\n'
	sed 's/^/    /' <<<"$glued"
	failures=$((failures + 1))
fi

# A reused WhichKeyDesc_ variable name silently drops one of the two labels.
printf '→ checking for duplicate WhichKeyDesc variables…\n'
if dupes="$(grep -oP '^\s*let\s+g:\KWhichKeyDesc_\w+' "$RC" | sort | uniq -d)"; then
	if [[ -n "$dupes" ]]; then
		printf '✗ duplicate WhichKeyDesc variable names:\n'
		sed 's/^/    /' <<<"$dupes"
		failures=$((failures + 1))
	fi
fi

if ((failures > 0)); then
	printf '\n✗ %d problem(s) found in %s\n' "$failures" "$RC"
	exit 1
fi

printf '\n✓ %s is clean against %s\n' "$RC" "$IDE_BUILD"
