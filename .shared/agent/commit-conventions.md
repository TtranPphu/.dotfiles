# Commit Message Conventions

## Component grouping

- For files under a top-level directory, use the first path segment as the component owner.
  - Examples: `hypr/...` -> `Hypr`, `tmux/...` -> `Tmux`, `nvim/...` -> `Nvim`, `opencode/...` -> `OpenCode`.
- For `.github/...`, use `GitHub`.
- For changes to agent configuration or documentation files (e.g., `.claude/`, `.github/skills/`, `.github/copilot-instructions.md`), use `Agent`.
- For root-level files that are not inside a component directory, use `Repo`.
- Prefer a human-readable component label in title case inside the commit subject.
- When changes span multiple tightly-coupled components (e.g., removing an old file in one component
  and updating references in another), combine them with `/`: `[Zsh/Nu]`.

## Subject line format

```
[Component] - Summary
```

Examples:

```
[Hypr] - Increase scrolling column width
[Tmux] - Set default shell to zsh
[GitHub] - Consolidate repository instructions
[OpenCode] - Add stow package for opencode config
[Zsh/Nu] - Update install-deps and reference
```

## Subject line rules

- Put the component name in square brackets.
- Use a space, a dash, and a space after the closing bracket.
- Write the summary in sentence style, not title case.
- Capitalize the first letter of the sentence, proper names, and short all-caps terms when needed.
- Keep the summary concise and specific.

## Body rules

- Add detail lines after a blank line.
- Use short sentences or wrapped prose that explains the meaningful changes in the commit.
- Capitalize the first letter of each sentence, proper names, and short all-caps terms when appropriate.
- Mention the key files or behavior changes when that helps explain the commit.
- If the commit is trivial, keep the body brief rather than omitting it entirely.
- End the body with a blank line followed by an agent signature matching the system prompt exactly
  (e.g., `OpenCode - deepseek-v4-flash-free`, `Claude - deepseek-v4-flash[1m]`, or `Copilot - <model>`).
- Do NOT use `Co-Authored-By` or other signatures.
