# Neovim Cheatsheet

## Surround (mini.surround — gs prefix)
gsa{motion}{char}   Add surround (e.g. gsaiw" → surround word with ")
gsd{char}           Delete surround (gsd")
gsr{old}{new}       Replace surround (gsr"' )
gsf / gsF           Find surround right / left
gsh                 Highlight surround
gsn                 Update n lines for surround

## Textobjects (mini.ai + treesitter)
a / i               around / inside  (e.g. daf = delete a function)
af / if             function          ac / ic   class
aa / ia             argument          a) i) a] i] a} i}   brackets
g[ / g]             jump to prev / next textobject edge

## Flash (s)
s{chars}            Jump to match        S   Treesitter select
f/F/t/T             Enhanced f-motions   r (op-pending) remote flash

## Folds
za zA               toggle fold (recursive)     zR / zM   open / close all
zo zc               open / close                zj / zk   next / prev fold

## Comments (native)
gcc                 toggle line comment         gc{motion}  comment motion
gbc                 toggle block comment

## LSP (native 0.11+ defaults)
grn                 rename            gra   code action     grr   references
gri                 implementation    grt   type def        gd    definition
K                   hover             gO    document symbols

## Find / Search (snacks.picker)
<leader>ff          find files        <leader>fr   recent files
<leader>sg          live grep         <leader>ss   document symbols
<leader>sw          grep word         <leader><space>  smart find

## Git & Review
<leader>gg          lazygit           <leader>gb   blame line
<leader>ghs/ghr     stage / reset hunk   ]h / [h   next / prev hunk
<leader>gdo         Diffview open     <leader>gdm  diff vs default branch
<leader>gdf         file history      :Octo pr list / :Octo review   PR review

## Harpoon (harpoon2 extra defaults)
<leader>H           add file          <leader>h    quick menu (toggle)
<leader>1..9        jump to file 1..9
## (optional: to mirror IntelliJ M-hjkl, add binds — see plan Phase 8 note)

## Debug (dap)
<leader>db          breakpoint        <leader>dc   continue
<leader>di/do/dO    step into/over/out   <leader>du   toggle dap-ui

## Misc
<leader>mc          this cheatsheet   <leader>cf   format buffer (manual)
<C-h/j/k/l>         tmux/window nav    <C-d>/<C-u>  half-page + center
