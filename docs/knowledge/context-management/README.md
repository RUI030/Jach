# Context management

How agent harnesses decide what the model sees at each step. The notes cover evidence that long inputs degrade output, and the techniques used to keep the working context small: masking or clearing old tool results, threshold-triggered summarisation, folding at sub-task boundaries, paging to external memory with recovery, and loading documentation on demand. The strongest evidence is grade B and comes from models of 30B and up; nothing here is measured on a model near 9B. All notes were checked against their sources on 2026-11-11.

| Note | Grade | One-line takeaway |
|---|---|---|
| [jetbrains-complexity-trap.md](jetbrains-complexity-trap.md) | B | Hiding old observations matched LLM summarisation on solve rate (within ±4 points) at about half the cost of raw history. |
| [context-folding-foldgrpo.md](context-folding-foldgrpo.md) | B | Folding branches to their return message works with RL (0.620 / 0.580) but untrained it is worse than a 327K ReAct (0.420 / 0.492 vs 0.478 / 0.552). |
| [agentfold.md](agentfold.md) | B | Model-written folds at two granularities kept context near 7k tokens at 100 turns after SFT; no ablation of folding itself. |
| [memgpt.md](memgpt.md) | B | Tiered memory with lossless eviction, pressure warnings and paged recall; self-directed paging broke down with the weakest model. |
| [chroma-context-rot.md](chroma-context-rot.md) | B | All 18 models degrade with length on fixed-difficulty tasks; distractors and low query-target similarity make it worse; Qwen3-8B included. |
| [manus-context-engineering.md](manus-context-engineering.md) | D | Keep the prefix cache-stable, constrain tools by masking not removal, compress only restorably, keep errors visible. |
| [anthropic-agent-skills.md](anthropic-agent-skills.md) | D | Progressive disclosure: one-line index always loaded, body and linked files read on demand. |
| [context-folding-for-coding-agent-harnesses.md](context-folding-for-coding-agent-harnesses.md) | D | Fold completed ranges into blocks with recoverable source lineage; in its pilot agents never unfolded unprompted, and the measured gain came mostly from doctrine, not compression. |
