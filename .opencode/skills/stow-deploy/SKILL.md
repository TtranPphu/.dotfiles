---
name: stow-deploy
description: Deploy dotfiles packages using GNU stow. Use when asked to deploy, install, link, or preview stow packages.
user-invocable: true
argument-hint: [list|preview|<package>]
allowed-tools: [Bash, Read]
---

List packages: `ls -d */` from the repo root.

## Worktree stow (temporary)

When stowing from a worktree (e.g. `.dotfiles-worktree/agent`), the target may
already be stow'd from the original `~/.dotfiles`. Remove the conflicting
symlink, stow from the worktree, then re-stow from the OG source when the task
is complete (per maintainer's signal):

```bash
# Remove existing symlink and stow from worktree
rm ~/.config/<package> 2>/dev/null
stow <package> -d <repo-root> -t ~

# ... test/develop here ...

# When maintainer signals task is done, re-stow from OG source
rm ~/.config/<package> 2>/dev/null
stow <package> -d ~/.dotfiles -t ~
```

Preview (simulate): `stow <package> -d <repo-root> -t ~ --simulate`
Deploy single package: `stow <package> -d <repo-root> -t ~`
Deploy all packages: `for pkg in <repo-root>/*/; do stow "${pkg%/}" -d <repo-root> -t ~; done`
