# zsh-vi-mode clipboard integration
#
# This makes yank commands in vi mode copy to the system clipboard using xclip.

# Override the default yank behavior to copy to clipboard
function zvm_vi_yank() {
  zvm_yank
  # Copy the yanked text to system clipboard
  echo -en "${CUTBUFFER}" | xclip -selection clipboard
  zvm_exit_visual_mode
}

# Optional: also make it work with the primary selection (middle-click paste)
# Uncomment if you want yanked text available for middle-click paste as well
# function zvm_vi_yank() {
#   zvm_yank
#   echo -en "${CUTBUFFER}" | xclip -selection clipboard
#   echo -en "${CUTBUFFER}" | xclip -selection primary
#   zvm_exit_visual_mode
# }
