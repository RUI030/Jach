# pi coding agent 1.0.4: what can be customised

Surveyed 2026-11-11 from the local install at `~/.local/lib/node_modules/@earendil-works/pi-coding-agent` (called PCA below). Paths such as `docs/extensions.md` are relative to PCA.

## Packages

All MIT, TypeScript compiled to ESM, Node >= 22.19.

| Package | Role | Size |
|---|---|---|
| `pi-ai` | LLM provider layer (openai-completions, openai-responses, anthropic-messages, google, mistral, bedrock) | 6.3M |
| `pi-agent-core` | Agent loop: `Agent`, `agentLoop()`, `agentLoopContinue()` | 340K |
| `pi-tui` | Terminal UI | 2.9M |
| `pi-coding-agent` | The `pi` CLI, sessions, extensions, tools | `dist` 21M |
| `pi-mcp`, `pi-codemode`, `pi-telemetry`, `chord` | MCP client, QuickJS sandbox, telemetry, app-composition runtime | |

PCA has 22 direct dependencies and a 141M `node_modules`. Install telemetry is on by default; `PI_TELEMETRY=0` turns it off.

## Extension API

Reference: `docs/extensions.md`; types in `dist/core/extensions/types.d.ts`. An extension is `export default function (pi: ExtensionAPI)`, loaded from `~/.pi/agent/extensions/`, `.pi/extensions/`, or `-e path`.

**Methods:** `registerTool`, `registerCommand`, `registerShortcut`, `registerFlag`, `registerProvider`, `registerMcpServer`, `registerVirtualModel`, `registerToolRenderer`, `registerEntryRenderer`, `sendUserMessage`, `sendMessage`, `appendEntry`, `setActiveTools`, `getActiveTools`, `getAllTools`, `setModel`, `setThinkingLevel`, `exec`, `events`.

**Events:**

| Group | Events |
|---|---|
| Session | `session_start`, `session_before_switch`, `session_before_fork`, `session_before_compact`, `session_compact`, `session_compact_failed`, `session_shutdown`, `session_before_tree`, `session_tree` |
| Context | `context`, `context_with_system`, `cache_warming_decision` |
| Provider | `before_provider_request` (can replace the payload), `before_provider_headers`, `after_provider_response`, `provider_stream_event` |
| Agent | `before_agent_start`, `agent_start`, `agent_end`, `agent_before_settle`, `agent_settled` |
| Turn and message | `turn_start`, `turn_end`, `message_start`, `message_update`, `message_end` (can replace the final message) |
| Tools | `tool_call` (mutate input, or block with a reason), `tool_result` (replace the result), `tool_execution_start`, `tool_execution_update`, `tool_execution_end` |
| Input | `input`, `user_bash` |

`turn_end` and `agent_before_settle` can append entries and return `continue: true` to keep the agent running.

### Tools

```ts
ToolDefinition { name, description, parameters /* TypeBox */, execute(toolCallId, params, signal, onUpdate, ctx),
                 promptSnippet?, promptGuidelines?, exposure?, executionMode? }
```

- Built-in tools can be disabled: CLI `--no-builtin-tools`, `--no-tools`, `--tools a,b`, `--exclude-tools`; setting `"defaultTools": []`; SDK `noTools: "builtin" | "all"`, `tools`, `customTools`.
- Registering a tool under a built-in's name overrides it.
- Tools cannot be unregistered, only re-registered with `exposure: "hidden"`. `setActiveTools` changes the active set at run time.

### System prompt

- `before_agent_start` exposes mutable `systemPromptOptions`; returning `systemPrompt` replaces the whole prompt for that run.
- Also: `--system-prompt`, `--append-system-prompt`, `SYSTEM.md`, `APPEND_SYSTEM.md`.
- A prompt set through `--system-prompt` or `SYSTEM.md` still gets `<cwd>`, `<project_context>` and `<skills>` appended. Only `forceSystemPrompt` or the `before_agent_start` return is fully opaque.

## Context control

- **`context` event:** receives `{ messages }` (no system messages) before every model call and returns a replacement list.
- **`context_with_system`:** the full transcript including the system message at index 0.
- **`context_edit` entries:** persistently omit or replace an earlier message in model context.
- **Compaction** (`docs/compaction.md`): triggers when `contextTokens > contextWindow - reserveTokens` (reserve 16384, keep-recent 20000). An LLM writes the summary. Disable with `compaction.enabled: false`; replace through `session_before_compact`.
- **Sessions** (`docs/session-format.md`): JSONL v3, a tree linked by `id` and `parentId`. Entry types include `message`, `compaction`, `context_edit`, `custom` (not in context) and `custom_message` (in context). The system prompt and tool declarations are stored as `role: "system"` messages with `toolsAdded` / `toolsRemoved` patches.

## Model configuration

`~/.pi/agent/models.json` (`docs/models.md`):

```json
{"providers":{"local":{"baseUrl":"http://localhost:8000/v1","api":"openai-completions","apiKey":"x",
  "models":[{"id":"my-9b","contextWindow":32768,"maxTokens":8192,"samplingParams":{"temperature":0.6}}]}}}
```

- Per-model `compat` options cover thinking format (`qwen`, `qwen-chat-template` and others), `chatTemplateKwargs`, and whether the endpoint accepts mid-conversation system messages and tool additions.
- There is a dedicated llama.cpp integration (`docs/llama-cpp.md`).
- **Native tool calling is required.** `openai-completions.js` sends `tools` and there is no parser for text or XML tool calls. A text format needs a custom provider (`docs/custom-provider.md`).

## Headless use

- `pi -p "..."`: print mode.
- `pi --mode json "..."`: JSONL event stream (`docs/json.md`).
- `pi --mode rpc`: JSONL commands such as `prompt`, `steer`, `abort`, `new_session`, `get_messages`, `set_auto_compaction` (`docs/rpc-commands.md`).
- SDK: `createAgentSession({ cwd, model, resourceLoader, tools, noTools, customTools, sessionManager, settingsManager })`, then `session.subscribe(cb)` and `session.prompt(text)`. A custom `ResourceLoader` supplies its own system prompt and skills (`examples/sdk/12-full-control.ts`).

## Skills and context files

- Skills are `SKILL.md` directories. Only name, description and path go into the prompt, in an `<available_skills>` block; the model reads the file itself. `--no-skills` disables them.
- `AGENTS.md` and `CLAUDE.md` are loaded into a `project_context` section. `-nc` disables that.

## Defaults

- System prompt: `dist/core/system-prompt.js`, about 2.5 to 3.5 KB rendered.
- Tools: `read{path, offset?, limit?}`, `bash{command, timeout?}`, `edit{path, edits:[{oldText,newText}]}`, `write{path, content}`; optional `grep`, `find`, `ls`.
- Output truncation: 2000 lines or 50 KB.
- Sub-agents and plan mode are deliberately not in core. They exist as examples: `examples/extensions/subagent/`, `plan-mode/`, `todo.ts`, `handoff.ts`.
- MCP is a built-in extension; `--no-mcp` disables it.

## Friction points for heavy customisation

- When tools or the prompt change, pi inserts mid-conversation system messages. A fine-tuned chat template may never have seen that shape.
- Some tool names are hard-coded: the default list falls back to `read, bash, edit, write`, and prompt rules check for `bash` and `grep` by name.
- Tool-call arguments must be valid JSON when the call ends. There is no repair or retry.
- The agent loop runs tool calls in parallel by default (`executionMode` overrides this).
- Flow control is not a core concept. A phase state machine has to be written across event callbacks.
- The codebase is large and changes quickly; the README says outside PRs and issues are closed automatically.
