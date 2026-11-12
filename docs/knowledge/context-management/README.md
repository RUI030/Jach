# Context management

How agent harnesses decide what the model sees at each step. The notes cover evidence that long inputs degrade output, and the techniques used to keep the working context small: masking or clearing old tool results, threshold-triggered summarisation, folding at sub-task boundaries, paging to external memory with recovery, and loading documentation on demand. The strongest evidence is grade B and comes from models of 30B and up; nothing here is measured on a model near 9B. All notes were checked against their sources on 2026-11-11.

| Note | Grade | One-line takeaway |
|---|---|---|
| [jetbrains-complexity-trap.md](jetbrains-complexity-trap.md) | B | Hiding old observations matched LLM summarisation on solve rate (within ±4 points) at about half the cost of raw history. |
| [context-folding-foldgrpo.md](context-folding-foldgrpo.md) | B | Folding branches to their return message works with RL (0.620 / 0.580) but untrained it is worse than a 327K ReAct (0.420 / 0.492 vs 0.478 / 0.552). |
| [agentfold.md](agentfold.md) | B | Model-written folds at two granularities kept context near 7k tokens at 100 turns after SFT; no ablation of folding itself. |
| [memgpt.md](memgpt.md) | B | Tiered memory with lossless eviction, pressure warnings and paged recall; self-directed paging broke down with the weakest model. |
| [chroma-context-rot.md](chroma-context-rot.md) | B | All 18 models degrade with length on fixed-difficulty tasks; distractors and low query-target similarity make it worse; Qwen3-8B included. |
| [anthropic-context-editing-docs.md](anthropic-context-editing-docs.md) | C | Concrete clearing parameters: trigger, protected tail of 3, batch minimum, exempt tools, calls kept visible. |
| [openhands-context-condenser.md](openhands-context-condenser.md) | D (C for mechanism) | Threshold-triggered slot-based summary; per-turn cost under half, solve rate 54% vs 53% on an unnamed subset. |
| [manus-context-engineering.md](manus-context-engineering.md) | D | Keep the prefix cache-stable, constrain tools by masking not removal, compress only restorably, keep errors visible. |
| [anthropic-effective-context-engineering.md](anthropic-effective-context-engineering.md) | D | Context is a budget; tool result clearing is the lightest compaction; notes and sub-agents carry long tasks. |
| [anthropic-agent-skills.md](anthropic-agent-skills.md) | D | Progressive disclosure: one-line index always loaded, body and linked files read on demand. |
| [context-folding-for-coding-agent-harnesses.md](context-folding-for-coding-agent-harnesses.md) | D | Fold completed ranges into blocks with recoverable source lineage; in its pilot agents never unfolded unprompted, and the measured gain came mostly from doctrine, not compression. |

## Patterns across sources

- **Longer input degrades output even when the task stays easy.** Chroma measures it directly (B), including LongMemEval at ~113k vs ~300 tokens and an 8B model. Anthropic, Manus and OpenHands report the same from practice (D). No source argues for filling a large window.
- **Tool observations are the first thing to cut; whether the model's own actions survive differs.** JetBrains masks only observations (B) and the Anthropic clearing API keeps calls by default (C). Context-Folding and AgentFold fold actions and reasoning too (B). No source compares the two at the same model.
- **Removed content should stay recoverable, but no source shows a model recovering it unprompted.** Manus (D), MemGPT recall storage (B), the Anthropic memory-tool pairing (C) and the owner's folding note (D) all keep the source. AgentFold, Context-Folding and OpenHands discard it. MemGPT agents stopped paging early, and the owner's pilot saw no spontaneous recovery.
- **Model-driven context management needed training or a strong model in every case.** Context-Folding without RL lost to long-context ReAct; plain GRPO made it worse (finish rate 0.781 to 0.612 on SWE-bench) until process rewards were added. AgentFold found prompting unreliable even for strong models. MemGPT degraded with GPT-3.5. All grade B; none tested below 30B.
- **LLM summarisation shows no clear gain over simpler methods.** OpenHands reports 54% vs 53% with lower cost (D). JetBrains finds masking within error bars of summarising, with summaries making Qwen3-Coder 480B runs about 15% longer (B). Context-Folding finds summarise-when-full below folding after RL (0.527 vs 0.620 on BrowseComp-Plus, 0.550 vs 0.580 on SWE-bench) (B). But on SWE-bench the RL-trained 327K ReAct (0.574) is within a point of folding (0.580), from single runs.
- **Edits to history cost the prefix cache, so batch them.** Manus argues for append-only context (D). The Anthropic `clear_at_least` (C) and OpenHands threshold with a 10% minimum (C, source code) batch edits. Context-Folding avoids the cost by rolling back to an unchanged prefix (B).
- **Failures should survive compression.** This rests mainly on Manus (D) and on the JetBrains authors' explanation for longer summary runs, which they did not test (B). AgentFold folds a failed sub-trajectory into one conclusion line rather than deleting it (B).
- **On-demand documentation loading is untested.** Skills and the context-engineering article describe progressive disclosure and just-in-time retrieval (both D); neither measures how reliably a model triggers a load.

## Gaps

- No source evaluates fold-with-unfold-by-id on a model at or below 9B, or on a model fine-tuned to a 16k context.
- No source measures how often an agent unfolds or loads documentation on its own, beyond the owner's pilot (none) and MemGPT's early stopping.
- No source compares harness-driven and model-driven folding on the same model and task.
- No source covers coding with frequent compiler or syntax errors, where the latest error output is the critical observation.
- No source gives fold thresholds, protected-tail sizes or batch minimums tuned for a 16k budget.
- No source measures what a fold line must contain for a small model to later find the right id.
