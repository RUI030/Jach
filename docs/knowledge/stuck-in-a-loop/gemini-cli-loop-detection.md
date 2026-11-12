# Gemini CLI LoopDetectionService

- **Source:** https://raw.githubusercontent.com/google-gemini/gemini-cli/main/packages/core/src/services/loopDetectionService.ts
- **Authors / org:** Google (gemini-cli)
- **Date:** main branch as fetched on 2026-11-11
- **Type:** source code
- **Read:** full text

## Summary

The service combines three detectors of increasing cost.

Tool-call repetition. Each call is keyed by a SHA-256 hash of the tool name plus JSON-serialised arguments. The last 25 keys are kept. For cycle lengths 1 to 5, the check asks whether the most recent cycle has repeated 5 times. So it catches five identical consecutive calls, and also a cycle of up to five different calls repeated five times.

Content "chanting". Streamed text is hashed in sliding 50-character chunks. A loop is declared when the same chunk occurs 10 times, the occurrences are close together (average gap at most 250 characters), and the text between occurrences takes few distinct values. Code blocks are excluded, and tables, lists, headings and tool calls reset the tracker, because these legitimately repeat.

LLM-based check. After 30 turns within one user prompt, a separate model is asked, with the last 20 history entries and the original user request, whether the agent is in an unproductive state. It returns an analysis and a confidence between 0 and 1. A loop needs confidence of at least 0.9, confirmed by a second "double-check" model when one is available. The check interval adapts between 5 and 15 turns: higher confidence means the next check comes sooner. The judge prompt defines an unproductive state as at least 5 consecutive actions with no net progress, and explicitly excludes batch work across files, incremental edits to one file, sequential reads, and retries with changed arguments.

The service only reports (type, count, detail); the caller chooses the response. `clearDetection` allows one recovery turn while keeping the detection count, so a second detection is known to be a repeat.

## Key points

- Cheap deterministic checks run always; the LLM judge runs only on long turns (30+) and needs 0.9 confidence twice.
- Cycle detection covers period 1 to 5, not only identical consecutive calls.
- Exact-argument hashing: any changed argument breaks the match.
- Explicit false-positive handling: code blocks, tables, lists, batch operations.
- The detection count persists across a recovery turn, which enables escalating responses.

## Relevance to JacKnife

(Our interpretation, not the source's claims.)

- Period-k cycle detection is worth copying; a small model can alternate edit / check / edit / check with identical content, which a "same call N times" rule misses.
- A threshold of 5 identical calls is tuned for a frontier model with a human watching. For our model, which does not self-correct, a lower threshold is likely appropriate.
- Exact hashing will miss our hallucinated-path case if the model varies the path each time; we need a second key, such as (tool, error class), alongside the exact one.
- The admin model can double as the "LLM judge", but only after the deterministic detectors have fired, to keep large-model calls rare.
- Keep a per-task detection counter so the second detection triggers a stronger response than the first.
