# Context Engineering for AI Agents: Lessons from Building Manus

- **Source:** https://manus.im/blog/Context-Engineering-for-AI-Agents-Lessons-from-Building-Manus
- **Authors / org:** Yichao "Peak" Ji (Manus)
- **Date:** 2025-07-18
- **Type:** engineering blog
- **Read:** full text

## Summary

A practitioner's account of six lessons from rebuilding the Manus agent framework four times. The team chose in-context learning on frontier models over fine-tuning, so every lesson is about shaping the prompt.

1. KV-cache hit rate is treated as the most important production metric. Manus sees roughly a 100:1 input-to-output token ratio, and cached input on Claude Sonnet was priced at a tenth of uncached input ($0.30 vs $3 per million tokens). To keep the cache valid: keep the prompt prefix stable (no second-level timestamps), make the context append-only, and serialise deterministically.
2. Do not add or remove tools mid-task. It invalidates the cache and confuses the model when earlier turns mention tools that are gone. Instead, a state machine masks token logits at decode time to allow or forbid tool groups; consistent name prefixes (`browser_`, `shell_`) make group masks simple.
3. Use the file system as unlimited external memory. Compression must be restorable: drop a web page's body but keep its URL, drop a document but keep its path.
4. Recite the plan. A typical task takes about 50 tool calls; rewriting a todo file pushes the goals into the most recent part of the context.
5. Keep errors in context. Failed actions and stack traces let the model avoid repeating them; hiding them removes that evidence.
6. Avoid few-shot ruts. Repetitive action-observation pairs make the model imitate the pattern; small structured variation in serialisation breaks this.

The author presents these as patterns that worked for Manus, not general laws.

## Key points

- Append-only, deterministic context protects the KV-cache; any edit to earlier tokens invalidates everything after it.
- Constrain actions by masking logits from a state machine, not by editing the tool list.
- Compression should always leave a pointer that lets the content be restored.
- Reciting the todo list at the end of context counters goal drift.
- Leave failures visible; error recovery is treated as a core agent skill.

## Relevance to JacKnife

(Our interpretation.)

- Folding rewrites earlier tokens, so each fold invalidates the KV-cache from that point. On a local 9B model this costs latency, not money; fold in batches at phase or task boundaries instead of after every turn if prefill time matters.
- The harness-owned state machine can enforce the allowed tools per phase by constrained decoding (grammar or logit mask) while keeping the tool definitions in the prompt constant.
- A folded line with an id is exactly "restorable compression"; never fold without storing the full message.
- Do not fold away the fact that a step failed. The one-line summary of a failed execution should still say that it failed and why.
- Have the harness re-inject the current task and its acceptance criteria near the end of the context each turn.
