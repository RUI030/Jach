# Context management

How agent harnesses decide what the model sees at each step: evidence that long contexts degrade output, and the techniques used to keep the working context small (masking or clearing old tool results, summarisation, folding at sub-task boundaries, paging to external memory, and loading documentation on demand). All files were written from sources fetched and read on 2026-11-11.

| File | One-line takeaway |
|---|---|
| [anthropic-effective-context-engineering.md](anthropic-effective-context-engineering.md) | Context is a budget; tool result clearing is the lightest compaction, notes and sub-agents carry long tasks. |
| [manus-context-engineering.md](manus-context-engineering.md) | Keep the prefix stable for the KV-cache, mask tools instead of removing them, compress only restorably, keep errors visible. |
| [jetbrains-complexity-trap.md](jetbrains-complexity-trap.md) | Hiding old observations matches LLM summarisation on solve rate and is cheaper in most tested settings. |
| [context-folding-foldgrpo.md](context-folding-foldgrpo.md) | Branch into a sub-task and fold it to its result on return; a 32K working context matched a 327K one, but only after RL. |
| [agentfold.md](agentfold.md) | The model rewrites its own history each step at two granularities; context stayed near 7k tokens at 100 turns after SFT. |
| [memgpt.md](memgpt.md) | Tiered memory with eviction to a searchable full history, pressure warnings and paginated retrieval. |
| [chroma-context-rot.md](chroma-context-rot.md) | All 18 tested models degrade as input grows; distractors and low query-target similarity make it worse. |
| [anthropic-agent-skills.md](anthropic-agent-skills.md) | Progressive disclosure: one-line metadata always loaded, body and linked files read on demand. |
| [anthropic-context-editing-docs.md](anthropic-context-editing-docs.md) | Concrete parameters for tool result clearing: trigger, protected tail, batch minimum, exempt tools. |
| [openhands-context-condenser.md](openhands-context-condenser.md) | Threshold-triggered structured summary in an open harness; halves per-turn cost with solve rate unchanged within noise. |

## Patterns across sources

- **Agreement: shorter, focused context works better.** Chroma measures it directly; Anthropic, Manus and OpenHands report it from practice. No source argues for filling a large window.
- **Agreement: tool observations are the bulk and the first thing to cut.** JetBrains measures about 84% of a SWE-agent turn as observation. Anthropic's clearing API, JetBrains' masking and Context-Folding all remove observations while keeping the agent's own actions visible.
- **Agreement: removed content should stay reachable.** Manus (keep the URL or path), MemGPT (recall storage), Anthropic (memory files, references). AgentFold is the exception: its folds are permanent, and its authors name information loss as the risk.
- **Disagreement: who decides what to fold.** Harness-side rules (JetBrains masking, Anthropic clearing, OpenHands threshold) versus model-side decisions (Context-Folding `branch`/`return`, AgentFold directives, MemGPT functions). Every model-side design needed training (RL or SFT) or a strong model to work; MemGPT did poorly with GPT-3.5.
- **Disagreement: is LLM summarisation worth it.** OpenHands reports cost savings at equal solve rate; JetBrains finds no advantage over plain masking and longer trajectories; Context-Folding finds summarise-when-full worse than folding at sub-task boundaries. The sources agree that when to compress matters: sub-task boundaries beat "window is full".
- **Tension: cache stability versus context editing.** Manus wants an append-only context; any fold or clear rewrites earlier tokens. Anthropic's `clear_at_least` and OpenHands' threshold trigger are both ways to batch edits. Context-Folding avoids the issue by rolling back to an unchanged prefix.
- **Errors should survive compression.** Manus argues it explicitly; JetBrains observes longer runs with summaries, which is consistent with summaries hiding failure signals (our reading, not their tested claim).
- **Gap.** No source evaluates fold-with-unfold-by-id on a small model with a short trained context. The closest are Context-Folding (36B, 32K) and AgentFold (30B MoE); both are larger and neither offers unfold.
