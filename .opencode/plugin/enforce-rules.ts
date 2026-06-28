import type { Plugin } from "@opencode-ai/plugin"

const RULES = `
- Execute exactly what the user asked. Do not add, change, or assume beyond the literal instruction.
- Before taking any action not explicitly requested, ask first.
- Track what the user has changed during the session and respect those changes.
`

export default (async () => {
  return {
    "chat.message": (msg) => {
      if (msg.role === "assistant" && !msg.content?.includes("Repeat these rules in every response")) {
        msg.content = `${msg.content?.trim() ?? ""}\n\n${RULES}`
      }
    },
  }
}) satisfies Plugin
