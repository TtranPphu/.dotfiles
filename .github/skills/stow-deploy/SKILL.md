---
name: stow-deploy
description: Deploy dotfiles packages with GNU stow.
---

List packages: `ls -d */` from repo root
Preview: `stow <package> -d <repo-root> -t ~ --simulate`
Deploy: `stow <package> -d <repo-root> -t ~`
Deploy all: `for pkg in <repo-root>/*/; do stow "${pkg%/}" -d <repo-root> -t ~; done`
