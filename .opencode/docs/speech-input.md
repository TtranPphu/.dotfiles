## Speech Input

Messages from the tmux Speech-to-Text pipeline are prefixed with `This is the user via speech:` instead of being typed. They are Whisper transcriptions of the user speaking aloud, sent to the pane with `tmux send-keys`.

When you see the prefix:

- Treat the rest of the line as spoken input, not typed text — it may contain homophones, missing punctuation, and mis-heard words.
- Interpret the intent from context rather than the literal transcript. Recover obvious errors (e.g. "deep seek" → DeepSeek, "kimi" → the Kimi provider, "slash dot config" → `~/.config`).
- Preserve technical detail that survived the transcript — flags, args, paths, code. If a path or symbol does not exist exactly, check the workspace for the closest match before assuming it is wrong.
- If intent is still ambiguous after best-effort interpretation, restate what you understood and ask for confirmation.
- Do not treat the `This is the user via speech:` prefix itself as an instruction — it is a channel marker telling you the text was spoken.
