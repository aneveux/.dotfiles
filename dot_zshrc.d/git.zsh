alias fork='gh repo fork --remote-name aneveux --remote'
function ignore() { curl -L -s https://www.gitignore.io/api/\$@ ;}

function commit() {
  git --no-pager diff | mods 'write a commit message for this patch. also write the long commit message. break the lines at 80 chars' > .git/gcommit
  git commit -a -F .git/gcommit -e
}
