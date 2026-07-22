# Bash Safety

- Every script starts with `set -euo pipefail`.
- Quote all expansions: `"$var"`, `"${arr[@]}"`. Unquoted expansion is a bug.
- `[[ ]]` over `[ ]`; arithmetic in `(( ))`.
- Check commands exist before use; fail loudly with a message to stderr and a non-zero exit.
- No parsing `ls`; use globs or `find -print0` with `read -d ''`.
- Run shellcheck and shfmt before considering a script done.
