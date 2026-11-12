# Tool Result Clearing: A Production Parameter Set

A method note based on the Claude API context-editing documentation [1].

- **Evidence:** C. Official product documentation; reliable for what the feature does, silent on whether it helps.
- **Numbers checked against the source:** yes, 2026-11-11, against the page's Markdown source (beta header `context-management-2025-06-27`).

## 1. Problem

In tool-heavy agent runs, old tool results (file contents, search results) stay in the history long after the model has used them. They cost tokens and, the page says, irrelevant content degrades focus. Context editing removes selected content before the prompt reaches the model, without the client changing its stored history. [1, Overview]

## 2. Method

The page documents two server-side strategies and one deprecated client-side one [1, Overview]:

| Strategy | What it removes |
|---|---|
| Tool result clearing (`clear_tool_uses_20250919`) | Oldest tool results first, each replaced by placeholder text saying it was removed |
| Thinking block clearing (`clear_thinking_20251015`) | Thinking blocks from earlier assistant turns |
| Client-side SDK compaction | Whole history, replaced by a model-written summary |

The page now states that server-side compaction, documented on a separate page, is the primary strategy for most long conversations, and that these strategies are for finer-grained control. [1, Overview]

### Key decisions

Parameters for tool result clearing [1, "Configuration options for tool result clearing"]:

| Parameter | Default | Purpose |
|---|---|---|
| `trigger` | 100,000 input tokens | When clearing starts; may instead be a count of tool uses |
| `keep` | 3 tool uses | Recent tool use/result pairs left intact |
| `clear_at_least` | none | Minimum tokens freed per event; if not reachable, nothing is cleared |
| `exclude_tools` | none | Tools whose uses and results are never cleared |
| `clear_tool_inputs` | `false` | Whether the call arguments are cleared too |

1. **Keep the call, drop the result.** By default the model still sees what it called. [1, "Tool result clearing"]
2. **Batch to protect the cache.** Clearing invalidates the cached prefix, so `clear_at_least` exists to make each invalidation worth its cache-write cost. [1, "Context editing and prompt caching"]
3. **Edit server-side only.** The client keeps the full, unmodified history and does not sync to the edited view. [1, "Context editing occurs server-side"]

### Implementation details that generalise

- Combined with a file-based memory tool, the model gets an automatic warning as the context nears the clearing threshold, so it can write important results to memory before they are cleared. [1, "Using with the memory tool"]
- The response reports which edits were applied and how many tokens and tool uses were cleared. [1, "Context editing response"]
- Thinking-clearing `keep` counts assistant turns, including the one in progress; a user message containing only tool results continues the current turn. The default when the strategy is omitted now differs by model generation. [1, "Thinking block clearing", "Configuration options for thinking block clearing"]
- The SDK compaction summary prompt has five slots: task overview, current state, important discoveries (including failed approaches), next steps, and context to preserve. [1, "Default summary prompt"]
- SDK compaction counted cache-read tokens from server-side tools as context and could trigger too early; the page advises using the token-counting endpoint. [1, "Limitations"]

## 3. Evidence

The page gives mechanism and defaults only. Its one worked example shows a history of about 100k tokens reduced to about 2 to 3k after compaction, as an illustration. [1, "What occurs during compaction"]

## 4. Evidence boundaries

- **No effectiveness data.** Nothing shows that clearing preserves task success, or which `keep` value works.
- **Defaults are tuned for large-window frontier models** (100k trigger). They do not transfer to a 16k budget.
- **Living documentation.** Defaults and recommendations have changed since the beta began; the thinking-clearing default and the deprecation of SDK compaction are recent changes.

## 5. What we take from it

Our interpretation, not the paper's claims.

- A parameter set to copy for the fold policy: a protected tail (`keep`), a batch minimum (`clear_at_least`), and a never-fold list (task brief, current file view, last check output).
- We fold each completed execution rather than waiting for a threshold, but the batching argument still holds for llama.cpp's prefix cache: apply folds together at a boundary.
- Keeping the call and replacing only the result matches the JetBrains finding that actions should stay visible.
- The compaction slots, with "failed approaches" made explicit, are a checklist for the harness-written task handover record.

## Reference

[1] Anthropic. *Context editing.* Claude API documentation (living page). <https://platform.claude.com/docs/en/build-with-claude/context-editing> (Markdown source at the same URL with `.md`). Accessed 2026-11-11.
