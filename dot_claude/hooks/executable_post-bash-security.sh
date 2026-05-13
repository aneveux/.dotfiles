#!/usr/bin/env bash
# PostToolUse security hook — secret leak detection in tool output
# Scans output for leaked credentials/keys and emits a warning.
# Exit 0 = allow (always, this is post-execution)
set -euo pipefail

INPUT=$(cat)
TOOL_NAME=$(jq -r '.tool_name // empty' <<<"$INPUT")
TOOL_OUTPUT=$(jq -r '.tool_output // .output // ""' <<<"$INPUT")

case "$TOOL_NAME" in
Bash | Write | Edit | WebFetch) ;;
*) exit 0 ;;
esac

[[ -z "$TOOL_OUTPUT" ]] && exit 0

declare -A SECRET_PATTERNS=(
	["OpenAI Key"]="sk-[a-zA-Z0-9]{20,}"
	["Anthropic Key"]="sk-ant-[a-zA-Z0-9]{20,}"
	["AWS Access Key"]="AKIA[0-9A-Z]{16}"
	["AWS Secret Key"]="[0-9a-zA-Z/+]{40}"
	["GCP Key"]="AIza[0-9A-Za-z_-]{35}"
	["Stripe Key"]="(sk|pk)_(live|test)_[0-9a-zA-Z]{24,}"
	["Twilio Key"]="SK[a-f0-9]{32}"
	["SendGrid Key"]='SG\.[a-zA-Z0-9_-]{22}\.[a-zA-Z0-9_-]{43}'
	["Slack Token"]="xox[baprs]-[0-9a-zA-Z-]{10,}"
	["Discord Token"]='[MN][A-Za-z0-9]{23,}\.[A-Za-z0-9-_]{6}\.[A-Za-z0-9-_]{27}'
	["GitHub Token"]="(ghp|gho|ghu|ghs|ghr)_[a-zA-Z0-9]{36,}"
	["GitLab Token"]="glpat-[a-zA-Z0-9_-]{20,}"
	["NPM Token"]="npm_[a-zA-Z0-9]{36}"
	["PyPI Token"]="pypi-[a-zA-Z0-9_-]{50,}"
	["JWT"]='eyJ[a-zA-Z0-9_-]*\.eyJ[a-zA-Z0-9_-]*\.[a-zA-Z0-9_-]*'
	["Private Key"]="-----BEGIN (RSA |EC |DSA |OPENSSH )?PRIVATE KEY-----"
	["PGP Private Key"]="-----BEGIN PGP PRIVATE KEY BLOCK-----"
	["DB URL w/ Creds"]="(postgres|mysql|mongodb)://[^:]+:[^@]+@"
	["Redis URL w/ Creds"]="redis://:[^@]+@"
	["Generic API Key"]="(api[_-]?key|apikey|api[_-]?secret)['\"]?\\s*[:=]\\s*['\"]?[a-zA-Z0-9_-]{20,}"
	["Generic Secret"]="(secret|password|passwd|pwd)['\"]?\\s*[:=]\\s*['\"]?[^\\s'\"]{8,}"
	["Generic Token"]="(auth[_-]?token|access[_-]?token|bearer)['\"]?\\s*[:=]\\s*['\"]?[a-zA-Z0-9_-]{20,}"
)

DETECTED_SECRETS=()
for secret_type in "${!SECRET_PATTERNS[@]}"; do
	pattern="${SECRET_PATTERNS[$secret_type]}"
	if echo "$TOOL_OUTPUT" | grep -qiE "$pattern" 2>/dev/null; then
		DETECTED_SECRETS+=("$secret_type")
	fi
done

if [[ ${#DETECTED_SECRETS[@]} -gt 0 ]]; then
	secrets_list=$(printf ", %s" "${DETECTED_SECRETS[@]}")
	secrets_list=${secrets_list:2}
	echo "{\"systemMessage\": \"SECRET LEAK WARNING: Potential secrets detected in output: $secrets_list. Do NOT commit or share this output.\"}"
fi

exit 0
