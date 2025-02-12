alias fork='gh repo fork --remote-name aneveux --remote'
function ignore() { curl -L -s https://www.gitignore.io/api/\$@ ;}

function commit() {
  PROMPT_FILE=~/prompts/git-commit.prompt

  if [[ ! -f "$PROMPT_FILE" ]]; then
    echo "Error: Prompt file not found at $PROMPT_FILE"
    return 1
  fi

  git --no-pager diff --staged HEAD | mods $(cat "$PROMPT_FILE") > .git/gcommit
  git commit -F .git/gcommit -e
}
