# Quality Scoring versus More Data When Curating Trajectories for a 7B LoRA

A method note based on Han, "A Systematic Evaluation of Trajectory Data Curation for LoRA Fine-Tuning of Code Agents" [1].

- **Evidence:** B. Controlled comparison of 16 fine-tunes with public code; single-author preprint; one base model, one trajectory corpus, and a loss proxy instead of task success.
- **Numbers checked against the source:** yes, 2026-11-11, against the arXiv PDF (no HTML version exists).

## 1. Problem

A pool of teacher trajectories is larger than the training budget. Should a small model be trained on the "best" trajectories by some quality score, or simply on more of them? End-to-end success cannot answer this at 7B, because the resolve rate is near 1% and a 1-point difference would need over 3,000 tasks per arm to detect. [1, §3.3]

## 2. Method

Qwen2.5-Coder-7B-Instruct is QLoRA-tuned on subsets of a public corpus of 67,074 SWE-agent-style trajectories, 32,161 of them resolved. [1, Abstract, §4.1]

Trajectories first pass three gates: resolved, not truncated, and a parseable thought-action-observation structure. Survivors get a composite score. [1, §3.1]

| Sub-score | Measures |
|---|---|
| B2 error-retry | Action, then an error ("Traceback", "Error", "failed"), then a similar action with the same tool. Capped at 10, inverted. |
| B3 step ratio | Steps relative to the median for the same task |
| C2 action diversity | Normalised entropy over action types |
| C3 observation use | Share of file and error names from observations that later actions mention |

Selection arms are Random, ResolvedOnly, TopQ and BottomQ at 500, 1,000 and 2,000 trajectories, plus ablations that drop one sub-score. [1, §3.2]

### Key decisions

1. **Use held-out loss as the metric.** Cross-entropy on assistant tokens over three 200-trajectory test sets (top 10%, random, bottom 10% by score). Each set holds about 9.4M assistant tokens, far more signal than a few hundred pass/fail outcomes. [1, §3.3]
2. **Check the proxy against generation.** Four checkpoints are asked for the first action on 100 held-out tasks; loss and ROUGE-L rank them identically. [1, §4.2, Table 1]
3. **Keep binary gates separate from the continuous score,** so pass/fail and quality are never averaged together. [1, §3.1]

### Implementation details that generalise

- Drop candidate sub-scores that barely vary across the pool. Two were dropped here (median above 0.96). [1, §3.1]
- Loss is masked to assistant tokens. [1, §3.4]
- Count how often the target tool-call format appears in the training targets. Here `<tool_call>` turns were 0-3% of assistant turns; bash and edit actions dominated. [1, §5.2]

## 3. Evidence

Gold-set cross-entropy, lower is better. [1, §4.3, Tables 2-3]

| Arm | 500 | 1,000 | 2,000 |
|---|---|---|---|
| No fine-tuning | 0.910 | | |
| Random | 0.4737 | 0.4140 | 0.3871 |
| TopQ | 0.4704 | 0.4106 | 0.3732 |
| ResolvedOnly | 0.4786 | 0.4175 | not run |
| BottomQ | 0.4869 | | |

- Doubling from 500 to 1,000 cut loss by 12.6-12.8% in every arm. [1, §4.4, Table 3]
- TopQ beat Random by 0.7% at 500 and 0.8% at 1,000, neither significant. At 2,000 the gap was 3.6% (Mann-Whitney p = 0.016). [1, §4.4]
- Restricting to resolved trajectories did not beat random sampling at 500 (0.4786 vs 0.4737, p = 0.78). [1, §4.3]
- TopQ beat BottomQ at 500 (p = 0.013), so the score does separate something. [1, §4.3]
- B2 alone was within 0.2% of the full composite (p = 0.88). No single-component ablation reached significance (all p > 0.25). [1, §4.5, Table 4]
- No fine-tuned model emitted a well-formed `<tool_call>` tag, whatever the data selection. The author attributes this to the 0-3% share of such turns in the data. [1, §5.2]
- First-action ROUGE-L rose from 0.137 untuned to 0.248 at 1,000 trajectories. [1, §4.2, Table 1]

## 4. Evidence boundaries

- **No task success was measured.** Loss is the outcome. The proxy check uses n = 4 checkpoints; the author notes the smallest possible p-value at that n is about 0.083. [1, §4.2, §5.4]
- **The quality null results are underpowered.** About 2,800 test trajectories per split would be needed to detect a 0.7% effect; the splits have 200. [1, §5.4]
- **Three scale points, one model, one corpus.** The author calls the 2,000-trajectory result an emerging signal, not a confirmed crossover. [1, §1, §5.4]
- **LoRA, not full fine-tuning.** Other notes in this folder use full fine-tuning.
- **The score counts error-retry loops as low quality.** The study does not separate harmful thrashing from useful recovery.
- **"B2 dominates" is directional only.** Removing B2 gave the largest drop among sub-scores, but that drop was not significant either (p = 0.46). [1, §4.5]

## 5. What we take from it

Our interpretation, not the paper's claims.

- Below about 1,000 trajectories, more verified data is worth more than finer ranking of the data we have. Quality scoring is worth revisiting once the pool passes a few thousand.
- The tool-call failure is the most relevant result for us. If our target format is rare in the training targets, the model will not learn it. Every assistant turn in our data should be a tool call in the exact Qwen XML format that llama.cpp parses, and we should measure that share.
- Held-out loss per phase is a usable metric while end-to-end success on Jac apps stays near zero (currently 0 of 13).
- Before using an error-retry score as a filter, separate retry-then-fix (which we want) from retrying the same failing action (which we do not).

## Reference

[1] Yunze Han (Vdynamics GmbH). *A Systematic Evaluation of Trajectory Data Curation for LoRA Fine-Tuning of Code Agents.* arXiv:2607.17205. <https://arxiv.org/pdf/2607.17205>. Code: <https://github.com/hanzunye/swe-trajectory-quality-study>. Accessed 2026-11-11.
