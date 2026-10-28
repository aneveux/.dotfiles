# Antoine's dotfiles

Hello World :wave:

This repository is a replacement of [my former dotfiles](https://github.com/aneveux/dotfiles) that were provisioned with [Ansible](https://www.ansible.com/).

I am now using [chezmoi](https://www.chezmoi.io/) as a dotfiles manager, and I am very happy with it so far.

Obviously these are my personal dotfiles, and I wouldn't recommend you to use them without customization. I am sharing them publicly as it is sometimes interesting to get a little inspiration from others' environments though.

## Setup

On a new machine, install `git`, `zsh` and `mise` first (system packages are listed in `packages.txt`,
installed by hand), then:

```sh
sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply aneveux/.dotfiles
```

CLI tools come from mise: `run_onchange_after_mise-install.sh.tmpl` runs `mise install` on apply.

cc-safety-net 2.6+ reads rulebooks live, so there is nothing to sync (`rule sync` is deprecated). After
`chezmoi apply` on a new machine, confirm with `npx -y cc-safety-net rule list` that it prints
"Active sources (1)" and "Active rules (10)".
