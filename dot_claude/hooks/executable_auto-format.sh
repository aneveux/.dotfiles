#!/bin/bash
# PostToolUse hook - Auto-format files after editing
# Event: PostToolUse (matcher: Write|Edit)
# Runs async — must never block, must always exit 0

INPUT=$(cat)
TOOL=$(echo "$INPUT" | jq -r '.tool_name')

if [[ "$TOOL" == "Write" || "$TOOL" == "Edit" ]]; then
    FILE=$(echo "$INPUT" | jq -r '.tool_input.file_path // .tool_input.path')

    if [[ -z "$FILE" || "$FILE" == "null" || ! -f "$FILE" ]]; then
        exit 0
    fi

    EXT="${FILE##*.}"

    case "$EXT" in
        js|jsx|ts|tsx|json|css|scss|md|html|vue)
            if command -v npx &> /dev/null && [[ -f "node_modules/.bin/prettier" ]]; then
                npx prettier --write "$FILE" 2>/dev/null || true
            fi
            ;;
        py)
            if command -v black &> /dev/null; then
                black --quiet "$FILE" 2>/dev/null || true
            fi
            ;;
        go)
            if command -v gofmt &> /dev/null; then
                gofmt -w "$FILE" 2>/dev/null || true
            fi
            ;;
        rs)
            if command -v rustfmt &> /dev/null; then
                rustfmt "$FILE" 2>/dev/null || true
            fi
            ;;
        java)
            dir=$(dirname "$FILE")
            while [[ "$dir" != "/" ]]; do
                if [[ -f "$dir/pom.xml" ]]; then
                    if grep -q 'spotless' "$dir/pom.xml" 2>/dev/null; then
                        (cd "$dir" && mvn spotless:apply -q 2>/dev/null) || true
                    fi
                    break
                fi
                dir=$(dirname "$dir")
            done
            ;;
        sh|bash)
            if command -v shfmt &> /dev/null; then
                shfmt -w "$FILE" 2>/dev/null || true
            fi
            ;;
        prisma)
            if command -v npx &> /dev/null; then
                npx prisma format --schema "$FILE" 2>/dev/null || true
            fi
            ;;
    esac
fi

exit 0
