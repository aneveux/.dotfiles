#!/bin/bash
# Hook: PreToolUse - Security Gate
# Blocks writes carrying a provider credential or an invisible-character payload.
# Deliberately narrow: only checks with no false-positive history. Heuristic
# pattern-matching (SQL interpolation, eval, innerHTML, weak hashes, traversal)
# was removed after it blocked legitimate code, and a gate that cries wolf gets
# ignored. Command-level safety is cc-safety-net's job; this covers file content.
#
# Exit 0 = allow, Exit 2 = block (stderr message shown to Claude)

set -euo pipefail

INPUT=$(cat)

# Unparseable input is not a safe write: jq would yield empty for every field,
# the tool-name test would fall through, and the content would never be scanned.
if ! jq -e . >/dev/null 2>&1 <<<"$INPUT"; then
	echo "SECURITY-GATE: unparseable hook input, refusing to pass an unscanned write" >&2
	exit 2
fi

TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // empty')

if [[ "$TOOL_NAME" != "Write" && "$TOOL_NAME" != "Edit" ]]; then
	exit 0
fi

FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')

FILENAME="${FILE_PATH##*/}"
EXTENSION="${FILE_PATH##*.}"
SOURCE_EXTENSIONS="js ts jsx tsx mjs cjs py go java kt kts rs rb php cs sh tf tfvars yaml yml json gradle xml properties ini conf cfg npmrc scala sql toml"
# Extensionless build files matched by name: "${FILE_PATH##*.}" yields the whole
# path for them, so Dockerfile, Makefile and Jenkinsfile skipped the gate. `.env`
# is deliberately absent — permissions.deny already covers it.
SOURCE_BASENAMES="dockerfile containerfile makefile jenkinsfile vagrantfile justfile"
is_source=false
for ext in $SOURCE_EXTENSIONS; do
	[[ "${EXTENSION,,}" == "$ext" ]] && is_source=true && break
done
if [[ "$is_source" == "false" ]]; then
	for base in $SOURCE_BASENAMES; do
		[[ "${FILENAME,,}" == "$base" ]] && is_source=true && break
	done
fi

if [[ "$is_source" == "false" ]]; then
	exit 0
fi

if [[ "$TOOL_NAME" == "Write" ]]; then
	CONTENT=$(echo "$INPUT" | jq -r '.tool_input.content // empty')
else
	CONTENT=$(echo "$INPUT" | jq -r '.tool_input.new_string // empty')
fi

# Match CONTENT against an ERE. A here-string, never a pipe: with
# `echo "$CONTENT" | grep -q`, grep exits on first match before echo finishes
# writing, and under pipefail the resulting SIGPIPE reads as "no match". That is
# a race, not a threshold: the earliest induced failure measured was 72 KB,
# roughly even odds at 100 KB, and deterministic above ~1 MB. Locale is pinned so
# the byte-level patterns behave the same wherever this runs — under C.UTF-8 they
# silently miss, under en_US.UTF-8 they error. A grep exit >= 1 that is not a
# clean "no match" means the detector itself broke, which is not evidence the
# file is safe: block instead of waving it through.
matches() {
	local rc=0
	LC_ALL=C grep -qE "$1" <<<"$CONTENT" || rc=$?
	case $rc in
	0) return 0 ;;
	1) return 1 ;;
	*)
		echo "SECURITY-GATE: detector failed (grep rc=$rc) on $FILE_PATH" >&2
		echo "Refusing the write rather than passing an unscanned file." >&2
		exit 2
		;;
	esac
}

# ── Provider credentials ─────────────────────────────────────────────────────
if matches '(sk-[a-zA-Z0-9]{20,}|sk-ant-[a-zA-Z0-9]{20,}|ghp_[a-zA-Z0-9]{36}|AKIA[A-Z0-9]{16}|xox[bps]-[a-zA-Z0-9\-]{20,})'; then
	echo "SECURITY-GATE: Provider API key pattern detected in $FILE_PATH" >&2
	echo "Move to .env and reference via environment variable." >&2
	exit 2
fi

# ── Invisible characters in source code ──────────────────────────────────────
# Matched as raw UTF-8 bytes rather than with grep -P '[\x{200B}-...]': the Perl
# form errors out under a non-UTF-8 locale, and that failure used to be hidden
# by a 2>/dev/null, silently opening the gate.
if matches $'\xe2\x80[\x8b-\x8d]|\xef\xbb\xbf'; then # U+200B-U+200D, U+FEFF
	echo "SECURITY-GATE: Zero-width characters detected in $FILE_PATH" >&2
	echo "These can hide malicious content. Remove zero-width chars." >&2
	exit 2
fi

if matches $'\xe2\x80[\xaa-\xae]|\xe2\x81[\xa6-\xa9]'; then # U+202A-U+202E, U+2066-U+2069
	echo "SECURITY-GATE: Bidirectional text override detected in $FILE_PATH" >&2
	echo "Bidi overrides can disguise malicious code (CVE-2021-42574)." >&2
	exit 2
fi

# Any ESC byte, not just CSI/OSC/charset introducers: DCS, APC, PM and SOS have
# the same terminal-spoofing reach. The 8-bit C1 forms are deliberately absent —
# 0x9b and 0x9d are ordinary UTF-8 continuation bytes (U+065B, most CJK), so
# matching them raw would block legitimate non-Latin source.
if matches $'\x1b'; then
	echo "SECURITY-GATE: ANSI escape sequence detected in $FILE_PATH" >&2
	echo "Escape sequences don't belong in source files." >&2
	exit 2
fi

# A null-byte check used to live here. It was unreachable: CONTENT comes from a
# command substitution, and bash strips NUL from those.

exit 0
