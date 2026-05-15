---
name: delegate
description:
  Delegate heavy execution work to external CLI agents (Cursor, OpenCode,
  Claude Code) to reduce Codex token consumption. Use when the task involves
  large code generation, extensive file analysis, or test writing that would
  be cheaper on another platform.
---

# Delegate

## When to delegate

Delegate when the sub-task is **execution-heavy and context-light**:

| Signal | Example | Why delegate |
|--------|---------|--------------|
| Code generation > ~100 lines | "Implement the full CRUD module for X" | Token-intensive; Cursor/OpenCode handle this within subscription |
| Large file analysis | "Analyze this 2000-line file and summarize" | Long context read; Claude Code has 200K context |
| Test writing | "Write unit tests for module Y" | Mechanical work; any agent can do it cheaply |
| Repetitive transformations | "Convert all callbacks to async/await in these 5 files" | Bulk work, low decision density |

**Do NOT delegate** when the sub-task requires:
- Linear API access (ticket state, comments, workpad updates)
- Multi-step reasoning that depends on your session history
- Git operations that need your current branch state (commit, push, PR)
- Decisions about task scope or acceptance criteria

## How to delegate

Run `tools/delegate_agent.sh` from the workspace:

```bash
# Auto mode (cost-optimized: cursor → opencode → claude)
tools/delegate_agent.sh --prompt "Implement the UserProfile component with props: name, email, avatar. Include TypeScript types and a default export."

# Force a specific agent
tools/delegate_agent.sh --agent cursor --prompt "Write jest tests for src/utils/parser.ts covering edge cases"

# Use a specific model via OpenCode
tools/delegate_agent.sh --agent opencode --model "anthropic/claude-sonnet" --prompt "Analyze src/legacy/handler.js and produce a refactoring plan"

# Longer timeout for complex tasks
tools/delegate_agent.sh --timeout 600 --prompt "Implement the full data pipeline module described in SPEC.md section 3.2"
```

## Integrating delegate output

1. Capture the output into a variable or temp file.
2. Review the output before applying: check it makes sense for the current task.
3. Write the output to the appropriate files in the workspace.
4. Run validation/tests on the result.
5. Log the delegation in the workpad Notes section:
   `- Delegated <task summary> to <agent> (<elapsed>s, <output size>)`

```bash
# Example: delegate, capture, apply
output=$(tools/delegate_agent.sh --agent cursor --prompt "Implement X..." 2>&1)
echo "$output" > src/components/X.tsx
# Then validate and commit as normal
```

## Cost priority

1. **Cursor Agent** - included in Pro subscription, effectively free
2. **OpenCode** - flexible model routing, can use cheapest available models (glm-5, gemini-flash)
3. **Claude Code** - per-token Anthropic billing, use for tasks that need long context

## Options reference

| Flag | Default | Description |
|------|---------|-------------|
| `--agent` | `auto` | `cursor`, `opencode`, `claude`, or `auto` |
| `--model` | (none) | Model override for OpenCode (e.g., `glm-5`, `anthropic/claude-sonnet`) |
| `--timeout` | `300` | Max seconds |
| `--max-output` | `50000` | Truncate output beyond this many chars |
| `--prompt` | (required) | The task description |
| `--workdir` | current dir | Working directory for the agent |

## Failure handling

- If the chosen agent is unavailable, auto mode tries the next one.
- On timeout (exit code 3), partial output is returned with a `[TIMEOUT]` marker.
- On complete failure (exit code 1), fall back to doing the work yourself.
- Logs are written to `.delegate_log/` in the working directory.
