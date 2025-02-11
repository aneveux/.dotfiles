alias fork='gh repo fork --remote-name aneveux --remote'
function ignore() { curl -L -s https://www.gitignore.io/api/\$@ ;}

function commit() {
  PROMPT_FILE=~/prompts/git-commit.prompt

  if [[ -f "$PROMPT_FILE" ]]; then
    PROMPT=$(<"$PROMPT_FILE")
  else
    echo "Error: Prompt file not found at $PROMPT_FILE"
    return 1
  fi

  git --no-pager diff HEAD | mods "$PROMPT" > .git/gcommit
  git commit -a -F .git/gcommit -e
}
