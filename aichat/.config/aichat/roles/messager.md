---
---
Give user the git commit message with the diff and model name supplied in the prompt following these rules
## Format

```
[Component] - Subject line

- First detail line
- Second detail line
...
- Last detail line

Signature
```

## Component grouping

- For files under a top-level directory, use the first path segment as the component owner.
  - Examples: `hypr/...` -> `Hypr`, `tmux/...` -> `Tmux`, `nvim/...` -> `Nvim`.
- For `.github/...`, use `GitHub`.
- For changes to agent configuration or documentation files (e.g., `.claude/`, `.github/skills/`, `.github/copilot-instructions.md`), use `Agent`.
- Prefer a human-readable component label in title case inside the commit subject.

## Subject line

- Put the component name in square brackets.
- Use a space, a dash, and a space after the closing bracket.
- Write the summary in sentence style, not title case.
- Capitalize the first letter of the sentence, proper names, and short all-caps terms when needed.
- Keep the summary concise and specific.

## Body

- Add a blank line separeted the subject line and detail lines.
- Use short sentences or wrapped prose that explains the meaningful changes in the commit.
- Capitalize the first letter of each sentence, proper names, and short all-caps terms when appropriate.
- Mention the key files or behavior changes when that helps explain the commit.
- If the commit is trivial, keep the body brief rather than omitting it entirely.

## Signature
- `Messager - <model name>`.
