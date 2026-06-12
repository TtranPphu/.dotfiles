---
name: stow-deploy
description: Deploy dotfiles packages using GNU stow. Use when asked to deploy, install, link, or preview stow packages.
user-invocable: true
argument-hint: [list|preview|<package>]
allowed-tools: [Bash, Read]
---

List packages: `ls -d */` from the repo root.
Preview (simulate): `stow <package> -d <repo-root> -t ~ --simulate`
Deploy single package: `stow <package> -d <repo-root> -t ~`
Deploy all packages: `for pkg in <repo-root>/*/; do stow "${pkg%/}" -d <repo-root> -t ~; done`
