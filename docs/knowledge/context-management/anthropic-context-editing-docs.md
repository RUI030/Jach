# Context editing (Claude API documentation)

- **Source:** https://platform.claude.com/docs/en/build-with-claude/context-editing
- **Authors / org:** Anthropic
- **Date:** undated living documentation (beta header dated 2025-06-27; fetched 2026-11-11)
- **Type:** docs
- **Read:** first ~100k characters of the page (the final ~8k were not read)

## Summary

This page documents a production implementation of tool result clearing, the technique named in Anthropic's context engineering article. Clearing happens on the server before the prompt reaches the model; the client keeps the full, unmodified history.

The tool-result strategy (`clear_tool_uses_20250919`) removes the oldest tool results in chronological order once the prompt passes a threshold, and replaces each with placeholder text telling the model the content was removed. Parameters:

- `trigger`: when clearing starts; default 100,000 input tokens, or a count of tool uses.
- `keep`: how many recent tool use/result pairs to leave intact; default 3.
- `clear_at_least`: minimum tokens to free per clearing event; if it cannot be met, nothing is cleared. This exists because clearing invalidates the prompt cache, so each clearing should be worth the cache rewrite.
- `exclude_tools`: tools whose results are never cleared.
- `clear_tool_inputs`: whether the tool call arguments are cleared too; default false, so the model still sees what it called.

A second strategy clears old thinking blocks, by default keeping only the most recent turn's thinking.

The page describes pairing clearing with a file-based memory tool: as the context nears the clearing threshold the model receives an automatic warning to write important information to memory files first, and it can read them back later. The API response reports which edits were applied.

The page gives the mechanism and defaults but no effectiveness measurements.

## Key points

- Clearing is threshold-triggered and oldest-first, with a protected tail of recent results.
- By default the tool call stays visible and only the result is removed.
- A minimum-freed-tokens setting batches clearing to limit cache invalidation.
- Some tools can be exempted from clearing.
- A warning before clearing gives the model a chance to save state.

## Relevance to JacKnife

(Our interpretation.)

- A concrete parameter set to copy for the fold policy: a protected tail (`keep`), a batch minimum (`clear_at_least`), and a never-fold list (`exclude_tools`, e.g. the task brief or the current file view).
- JacKnife differs by folding every completed execution instead of waiting for a threshold. The batching argument still applies: several folds applied together at a boundary cost one cache rebuild instead of many.
- Keeping the tool call visible and replacing only the result matches the JetBrains finding that actions and reasoning should be kept.
- Because JacKnife's placeholder is a short summary with an id, the pre-clearing warning is less necessary; nothing is lost.
