# Cache-Stable, Restorable Context for a Production Agent

A method note based on the Manus context-engineering post [1].

- **Evidence:** D. Vendor experience report from one production agent; no controlled comparisons or measurements beyond two operating figures.
- **Numbers checked against the source:** yes, 2026-11-11, against the HTML page text.

## 1. Problem

Manus chose to build on in-context learning with frontier models rather than fine-tune its own model, so every improvement had to come from how the context is shaped. An agent's input grows every step while each output is a short function call, so prefill dominates latency and cost. The post shares six lessons from rebuilding the framework four times. [1, introduction, "Design Around the KV-Cache"]

## 2. Method

| Lesson | Practice |
|---|---|
| Design around the KV-cache | Stable prefix, append-only context, deterministic serialisation |
| Mask, don't remove | Keep all tool definitions; restrict choice by logit masking from a state machine |
| File system as context | Drop large content but keep a pointer that restores it |
| Recite the plan | Rewrite a todo file so goals sit at the end of the context |
| Keep the wrong stuff in | Leave failed actions and stack traces visible |
| Don't get few-shotted | Add small structured variation to break repetitive patterns |

### Key decisions

1. **KV-cache hit rate is the one metric the author would pick** for a production agent, because it drives both latency and cost. [1, "Design Around the KV-Cache"]
2. **No timestamps in the prefix, no edits to past turns, stable key order.** A single changed token invalidates the cache from that point on. [1, "Design Around the KV-Cache"]
3. **Do not add or remove tools mid-task.** Tool definitions sit near the front, so a change invalidates everything after them; and earlier turns that mention a missing tool confuse the model, leading to schema violations or invented actions without constrained decoding. [1, "Mask, Don't Remove"]
4. **Compression must be restorable.** A web page body can be dropped if its URL stays; a document if its path stays. The author argues any irreversible compression is risky because one cannot predict which observation matters ten steps later. [1, "Use the File System as Context"]
5. **Errors stay in context**, so the model shifts away from repeating the failed action. [1, "Keep the Wrong Stuff In"]

### Implementation details that generalise

- Response prefill gives three function-calling modes without touching tool definitions: auto (prefill to the assistant start), required (prefill to the tool-call token), and specified (prefill to the start of the function name). [1, "Mask, Don't Remove"]
- Consistent tool-name prefixes (`browser_`, `shell_`) let a group of tools be enforced by prefilling a prefix, without a stateful logits processor. [1, "Mask, Don't Remove"]
- When a provider needs manual cache breakpoints, place one at least at the end of the system prompt. When self-hosting, enable prefix caching and route a session to the same worker. [1, "Design Around the KV-Cache"]
- Repetitive action-observation pairs make the model imitate the pattern; the example is a batch of 20 resumes. Manus varies templates, phrasing and order slightly. [1, "Don't Get Few-Shotted"]

## 3. Evidence

- Average input-to-output token ratio in Manus: about 100:1. [1, "Design Around the KV-Cache"]
- Claude Sonnet pricing cited: $0.30 per million cached input tokens vs $3 uncached, a 10× difference. [1, "Design Around the KV-Cache"]
- A typical task takes about 50 tool calls. [1, "Manipulate Attention Through Recitation"]

No other numbers are given. Each lesson is supported by the team's experience only.

## 4. Evidence boundaries

- **No measured effect for any lesson.** The author says none of it is universal truth, only what worked for Manus. [1, Conclusion]
- **Frontier API models**, not small or fine-tuned ones. A fine-tuned model may react differently to tool masking and to repetitive context.
- **Prices are as stated in July 2025** for one provider.
- The claim that visible errors reduce repeats is asserted, not measured. Our own model repeats after a LOOP DETECTED message in 6 of 12 tasks, so visible failure alone was not enough there.

## 5. What we take from it

Our interpretation, not the paper's claims.

- Each fold rewrites earlier tokens and invalidates llama.cpp's prefix cache from that point. Folding in batches at task or phase boundaries limits re-prefill.
- The per-phase tool set can be enforced by grammar or prefill while keeping the tool definitions in the prompt constant. Changing the tool list per phase costs a cache rebuild and risks mentions of missing tools.
- A folded line with an id is restorable compression; the full message must always be stored before folding.
- A fold line for a failed execution must still say that it failed and why.

## Reference

[1] Yichao "Peak" Ji (Manus). *Context Engineering for AI Agents: Lessons from Building Manus.* Blog post, 2025-07-18. <https://manus.im/blog/Context-Engineering-for-AI-Agents-Lessons-from-Building-Manus>. Accessed 2026-11-11.
