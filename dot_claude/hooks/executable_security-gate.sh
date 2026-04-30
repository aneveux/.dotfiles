#!/bin/bash
# Hook: PreToolUse - Security Gate
# Detects vulnerable code patterns before writing to source files.
# Complements dangerous-actions-blocker.sh (system-level) and security-check.sh (bash commands).
# This hook focuses on APPLICATION security anti-patterns in written code.
#
# Exit 0 = allow, Exit 2 = block (stderr message shown to Claude)

set -e

INPUT=$(cat)
TOOL_NAME=$(echo "$INPUT" | jq -r '.tool_name // empty')

if [[ "$TOOL_NAME" != "Write" && "$TOOL_NAME" != "Edit" ]]; then
    exit 0
fi

FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')

EXTENSION="${FILE_PATH##*.}"
SOURCE_EXTENSIONS="js ts jsx tsx py go java rb php cs sh"
is_source=false
for ext in $SOURCE_EXTENSIONS; do
    [[ "$EXTENSION" == "$ext" ]] && is_source=true && break
done

if [[ "$is_source" == "false" ]]; then
    exit 0
fi

if [[ "$TOOL_NAME" == "Write" ]]; then
    CONTENT=$(echo "$INPUT" | jq -r '.tool_input.content // empty')
else
    CONTENT=$(echo "$INPUT" | jq -r '.tool_input.new_string // empty')
fi

# ── Hardcoded secrets ────────────────────────────────────────────────────────
if echo "$CONTENT" | grep -qiE '(api[_-]?key|password|secret|token|bearer)\s*=\s*["'"'"'][^"'"'"'$\{][^"'"'"']{8,}["'"'"']'; then
    echo "SECURITY-GATE: Potential hardcoded secret detected in $FILE_PATH" >&2
    echo "Use environment variables instead." >&2
    exit 2
fi

if echo "$CONTENT" | grep -qE '(sk-[a-zA-Z0-9]{20,}|sk-ant-[a-zA-Z0-9]{20,}|ghp_[a-zA-Z0-9]{36}|AKIA[A-Z0-9]{16}|xox[bps]-[a-zA-Z0-9\-]{20,})'; then
    echo "SECURITY-GATE: Provider API key pattern detected in $FILE_PATH" >&2
    echo "Move to .env and reference via environment variable." >&2
    exit 2
fi

# ── SQL injection via string interpolation ───────────────────────────────────
if echo "$CONTENT" | grep -qiE '(SELECT|INSERT|UPDATE|DELETE|DROP).{0,60}(\$\{|'"'"'\s*\+\s*|"\s*\+\s*)'; then
    echo "SECURITY-GATE: Potential SQL injection pattern in $FILE_PATH" >&2
    echo "Use parameterized queries (PreparedStatement, $1 params, or ORM)." >&2
    exit 2
fi

# ── XSS via innerHTML / document.write ───────────────────────────────────────
if echo "$CONTENT" | grep -qE '\.innerHTML\s*=\s*[^"'"'"'`]|document\.write\s*\('; then
    echo "SECURITY-GATE: Potential XSS pattern in $FILE_PATH" >&2
    echo "Use textContent instead of innerHTML, or sanitize with DOMPurify." >&2
    exit 2
fi

# ── eval() with dynamic content (JS) ────────────────────────────────────────
if echo "$CONTENT" | grep -qE 'eval\s*\(\s*[^"'"'"'`]|new\s+Function\s*\(\s*[^"'"'"'`]'; then
    echo "SECURITY-GATE: eval() or new Function() with dynamic content in $FILE_PATH" >&2
    echo "Avoid eval() with user input. Use JSON.parse() for data." >&2
    exit 2
fi

# ── Weak hashing for passwords ───────────────────────────────────────────────
if echo "$CONTENT" | grep -qiE '(md5|sha1|sha256)\s*\(.*password|hashlib\.(md5|sha1)\s*\(.*password'; then
    echo "SECURITY-GATE: Weak hash algorithm for password in $FILE_PATH" >&2
    echo "Use bcrypt, argon2, or scrypt for password hashing." >&2
    exit 2
fi

# Java: MessageDigest with MD5/SHA-1
if echo "$CONTENT" | grep -qiE 'MessageDigest\.getInstance\s*\(\s*"(MD5|SHA-?1)"\s*\)'; then
    echo "SECURITY-GATE: Weak hash algorithm (MD5/SHA-1) via MessageDigest in $FILE_PATH" >&2
    echo "Use SHA-256 minimum, or bcrypt/argon2 for passwords." >&2
    exit 2
fi

# ── Command injection ────────────────────────────────────────────────────────
if echo "$CONTENT" | grep -qE '(exec|shell_exec|system|popen|subprocess\.call)\s*\([^"'"'"'`].*(\$\{|'"'"'\s*\+|"\s*\+)'; then
    echo "SECURITY-GATE: Potential command injection in $FILE_PATH" >&2
    echo "Use parameterized subprocess calls, never interpolate user input." >&2
    exit 2
fi

# Java: Runtime.exec with string concat
if echo "$CONTENT" | grep -qE 'Runtime\.getRuntime\(\)\.exec\s*\([^"]*\+'; then
    echo "SECURITY-GATE: Potential command injection via Runtime.exec() in $FILE_PATH" >&2
    echo "Use ProcessBuilder with explicit argument list." >&2
    exit 2
fi

# Java: ProcessBuilder with string concat
if echo "$CONTENT" | grep -qE 'new\s+ProcessBuilder\s*\([^)]*\+'; then
    echo "SECURITY-GATE: Potential command injection via ProcessBuilder in $FILE_PATH" >&2
    echo "Pass arguments as separate list elements, don't concatenate." >&2
    exit 2
fi

# Bash: eval with variable interpolation
if [[ "$EXTENSION" == "sh" ]] && echo "$CONTENT" | grep -qE 'eval\s+.*\$'; then
    echo "SECURITY-GATE: eval with variable interpolation in $FILE_PATH" >&2
    echo "Use arrays and direct execution instead of eval with variables." >&2
    exit 2
fi

# ── Path traversal via user input ────────────────────────────────────────────
if echo "$CONTENT" | grep -qE '(readFile|open|fopen|path\.join)\s*\([^)]*req\.(params|query|body)'; then
    echo "SECURITY-GATE: Potential path traversal in $FILE_PATH" >&2
    echo "Validate and sanitize file paths against an allowed base directory." >&2
    exit 2
fi

# Java: new File / Paths.get with request input
if echo "$CONTENT" | grep -qE '(new\s+File|Paths\.get)\s*\([^)]*request\.(getParameter|getAttribute|getHeader)'; then
    echo "SECURITY-GATE: Potential path traversal in $FILE_PATH" >&2
    echo "Validate and canonicalize file paths. Check against allowed base directory." >&2
    exit 2
fi

exit 0
