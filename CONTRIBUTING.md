# Contributing

## Commit Message Convention

Commit messages follow a structured format to maintain clarity and consistency:

```
<Component>: <Brief description>

<Optional detailed explanation>

Co-authored-by: <Agent Name> <Model Name with Version>
```

### Format Rules

- **Component prefix**: Use title case for the component name (e.g., `Tmux`, `Nvim`, `Zsh`)
- **First line**: Start with capitalized sentences and proper names only (not title case for the whole line)
- **First line length**: Keep it concise
- **Body**: Optional detailed explanation on separate lines
- **Co-authored-by**: Include agent name and model version

### Examples

```
Tmux: Dim hint box borders

Use dim blue foreground with no background for box-drawing borders
instead of bold bright blue on black background. This is less
distracting while keeping the hints readable.

Co-authored-by: Copilot claude-haiku-4.5
```

```
Nvim: Disable mouse support

Explicitly set mouse mode to empty string to disable all mouse
functionality in Neovim.

Co-authored-by: Copilot claude-haiku-4.5
```
