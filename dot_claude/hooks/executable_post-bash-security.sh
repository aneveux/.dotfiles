#!/usr/bin/env bash
# Consolidated PostToolUse security hook
# Merges: output-secrets-scanner.sh, output-validator.sh
# Run on: Bash, Write, Edit, WebFetch (via matcher)
set -euo pipefail

INPUT=$(cat)
TOOL_NAME=$(jq -r '.tool_name // empty' <<<"$INPUT")
TOOL_OUTPUT=$(jq -r '.tool_output // .output // ""' <<<"$INPUT")

case "$TOOL_NAME" in
Bash | Write | Edit | WebFetch) ;;
*) exit 0 ;;
esac

[[ -z "$TOOL_OUTPUT" ]] && exit 0

WARNINGS=()

# --- Secret scanning (from output-secrets-scanner.sh) ---

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
	["Heroku Key"]="[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{4}-[0-9a-fA-F]{12}"
	["Private Key"]="-----BEGIN (RSA |EC |DSA |OPENSSH )?PRIVATE KEY-----"
	["PGP Private Key"]="-----BEGIN PGP PRIVATE KEY BLOCK-----"
	["DB URL w/ Creds"]="(postgres|mysql|mongodb)://[^:]+:[^@]+@"
	["Redis URL w/ Creds"]="redis://:[^@]+@"
	["Generic API Key"]="(api[_-]?key|apikey|api[_-]?secret)['\"]?\\s*[:=]\\s*['\"]?[a-zA-Z0-9_-]{20,}"
	["Generic Secret"]="(secret|password|passwd|pwd)['\"]?\\s*[:=]\\s*['\"]?[^\\s'\"]{8,}"
	["Generic Token"]="(auth[_-]?token|access[_-]?token|bearer)['\"]?\\s*[:=]\\s*['\"]?[a-zA-Z0-9_-]{20,}"
	["Private Key Inline"]="['\"]?-----BEGIN[^-]+PRIVATE KEY-----"
	["Env Dump"]="^(env|printenv|set)$"
	["Proc Environ"]=".proc.self.environ|.proc.[0-9]+.environ"
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
	WARNINGS+=("SECRET LEAK WARNING: Potential secrets detected: $secrets_list. Do NOT commit or share this output.")
fi

# --- Placeholder detection (from output-validator.sh) ---

SUSPICIOUS_PATHS=(
	"/path/to/"
	"/your/project/"
	"/example/"
	"/foo/bar/"
	"/my/app/"
	"/user/project/"
	'C:\Users\User\'
	'C:\path\to\'
)
for pattern in "${SUSPICIOUS_PATHS[@]}"; do
	if [[ "$TOOL_OUTPUT" == *"$pattern"* ]]; then
		WARNINGS+=("Suspicious placeholder path: '$pattern'")
		break
	fi
done

PLACEHOLDER_PATTERNS=(
	"TODO:"
	"FIXME:"
	"XXX:"
	"HACK:"
	"your-api-key"
	"your_api_key"
	"YOUR_API_KEY"
	"sk-..."
	"pk_test_"
	"pk_live_"
	"api_key_here"
	"replace_with"
	"insert_your"
	"placeholder"
	"example.com"
	"foo@bar.com"
	"test@test.com"
)
for pattern in "${PLACEHOLDER_PATTERNS[@]}"; do
	if [[ "$TOOL_OUTPUT" == *"$pattern"* ]]; then
		WARNINGS+=("Placeholder content detected: '$pattern'")
		break
	fi
done

# --- Incomplete implementation detection ---

INCOMPLETE_PATTERNS=(
	"not implemented"
	"NotImplementedError"
	"throw new Error.*implement"
	"// TODO"
	"# TODO"
	"pass  # "
	"raise NotImplemented"
	"undefined"
)
for pattern in "${INCOMPLETE_PATTERNS[@]}"; do
	if echo "$TOOL_OUTPUT" | grep -qiE "$pattern" 2>/dev/null; then
		WARNINGS+=("Incomplete implementation detected: '$pattern'")
		break
	fi
done

# --- Hallucination detection ---

HALLUCINATION_PATTERNS=(
	"According to the documentation"
	"As stated in"
	"The official guide says"
	"Based on the API reference"
)
for pattern in "${HALLUCINATION_PATTERNS[@]}"; do
	if [[ "$TOOL_OUTPUT" == *"$pattern"* ]]; then
		WARNINGS+=("Unverified reference claim: '$pattern' - verify source")
		break
	fi
done

# --- Uncertainty detection ---

UNCERTAINTY_PATTERNS=(
	"i'm not sure"
	"i think it might"
	"probably"
	"possibly"
	"might be"
	"could be"
	"i believe"
	"i assume"
	"i guess"
	"if i recall"
	"from memory"
	"i don't have access"
	"i cannot verify"
)
UNCERTAINTY_COUNT=0
OUTPUT_LOWER=$(echo "$TOOL_OUTPUT" | tr '[:upper:]' '[:lower:]')
for pattern in "${UNCERTAINTY_PATTERNS[@]}"; do
	if [[ "$OUTPUT_LOWER" == *"$pattern"* ]]; then
		((UNCERTAINTY_COUNT++))
	fi
done
if [[ $UNCERTAINTY_COUNT -ge 3 ]]; then
	WARNINGS+=("High uncertainty detected ($UNCERTAINTY_COUNT indicators) - verify output accuracy")
fi

# --- Emit warnings ---

if [[ ${#WARNINGS[@]} -gt 0 ]]; then
	WARNING_MSG="Output validation warnings:\\n"
	for warn in "${WARNINGS[@]}"; do
		WARNING_MSG+="  - $warn\\n"
	done
	WARNING_MSG+="\\nReview output carefully before accepting."
	echo "{\"systemMessage\": \"$WARNING_MSG\"}"
fi

exit 0
