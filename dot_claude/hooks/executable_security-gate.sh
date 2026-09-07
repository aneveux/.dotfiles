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
	# `--` because one pattern below starts with a hyphen (the PEM header), which
	# grep would otherwise read as a bundle of short options.
	LC_ALL=C grep -qE -- "$1" <<<"$CONTENT" || rc=$?
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
# The first pattern set was written against generic provider prefixes and missed
# the shapes THIS platform mints, which is the only kind of miss that matters
# here: a shape the gate does not know is not a warning, it is a write that lands
# while the kit's agentInstructions claim the gate "blocks a Write/Edit carrying a
# provider credential". Added, each with the caller it belongs to:
#   ASIA   the STS session keys the bedrock credential service issues — AKIA
#          alone covers only long-lived IAM keys, and the sandbox never sees one
#   gho_ ghr_ ghs_ ghu_   GH_TOKEN's own OAuth/refresh/server/user forms, next to
#          the ghp_ personal token that was already here (one rule now: the old
#          exact-36 form is a subset of {36,})
#   ATATT  Atlassian, behind jk-kit and cloudbees-jira-kit
#   squ_   SonarQube user tokens, behind sonar-kit
# The PEM header gets its own block below.
#
# Every addition is prefix-anchored and length-bounded, and that is not style: the
# hook BLOCKS, so a generic "32-or-more base62 characters" rule would reject a
# checksum, a git SHA or a minified line, and a gate that cries wolf gets switched
# off — which is exactly why the heuristic set named at the top of this file was
# removed. Class 9 of hook-contract-test.sh asserts the negative direction too.
#
# `gh[oprsu]_` also matches sbx's published GH_TOKEN placeholder (gho_ followed by
# 36 characters). Deliberately not exempted. Nothing should be writing a
# token-shaped constant into a source file, placeholder or not, and an exemption
# keyed on the literal placeholder is a hole that goes stale the moment sbx
# changes it. It costs nothing today: the placeholder appears in this repo only in
# Markdown, and md is not in SOURCE_EXTENSIONS.
if matches '(sk-[a-zA-Z0-9]{20,}|sk-ant-[a-zA-Z0-9]{20,}|gh[oprsu]_[A-Za-z0-9]{36,}|(AKIA|ASIA)[A-Z0-9]{16}|xox[bps]-[a-zA-Z0-9\-]{20,}|ATATT[A-Za-z0-9]{20,}|squ_[a-f0-9]{40})'; then
	echo "SECURITY-GATE: Provider API key pattern detected in $FILE_PATH" >&2
	echo "Move to .env and reference via environment variable." >&2
	exit 2
fi

# ── Private keys ─────────────────────────────────────────────────────────────
# Its own block rather than one more alternative above, because the remediation
# differs: "move it to .env" is wrong advice for a private key, and
# ~/.claude/rules/invariants.md forbids committing one at all. Matched on the PEM
# header only — the body is base64 and has no anchor worth trusting.
if matches '-----BEGIN [A-Z ]*PRIVATE KEY-----'; then
	echo "SECURITY-GATE: Private key material detected in $FILE_PATH" >&2
	echo "A private key does not belong in a repository. Reference it by path from outside the tree." >&2
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
