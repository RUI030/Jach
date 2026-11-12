# AgentFold: Long-Horizon Web Agents with Proactive Context Management

- **Source:** https://arxiv.org/html/2510.24699v1
- **Authors / org:** Rui Ye, Zhongwang Zhang, Kuan Li, Huifeng Yin and co-authors (Tongyi Lab, Alibaba Group)
- **Date:** 2025-10-28
- **Type:** paper
- **Read:** full text

## Summary

AgentFold replaces the append-only ReAct history with a workspace that the model rewrites at every step. The context has four parts: the question, the tools, a list of "multi-scale state summaries" (ordered blocks, each covering a contiguous range of past steps), and the latest interaction in full (last explanation, action and observation).

At each step the model emits one response with four parts: thinking, a folding directive, a short explanation, and an action. The folding directive is a JSON object giving a step range and replacement text. Two modes exist. Granular condensation folds only the latest step into its own summary block. Deep consolidation merges the latest step with a run of earlier blocks into one coarser block, typically when a sub-task is finished or a line of work was a dead end.

Prompting did not produce this format reliably. The authors built a data pipeline (Fold-Generator) that used LLMs to generate trajectories and applied rejection sampling to drop malformed steps and trajectories with too many environment errors, then ran supervised fine-tuning on Qwen3-30B-A3B.

Reported scores: 36.2% on BrowseComp, 47.3% on BrowseComp-ZH, 62.1 item-F1 on WideSearch, 67.0% on GAIA (text-only), competitive with or above much larger open models; some baselines are taken from other papers. Context grew sub-linearly, from about 3.5k tokens to about 7k over 100 turns, which the authors estimate is 92% smaller than ReAct at turn 100. In a 500-turn run context mostly stayed under 20k tokens. The folding is not reversible: once a block is consolidated the detail is gone. Training was SFT only; the authors name RL as future work.

## Key points

- Every step carries a fold decision; the model chooses between a fine-grained and a coarse fold.
- Only the latest interaction is kept verbatim; everything else is summary blocks.
- The behaviour had to be fine-tuned in; prompt engineering was unreliable.
- Context stayed in the single-digit thousands of tokens for 100-turn tasks.
- Evaluated on web information-seeking tasks only, not coding.

## Relevance to JacKnife

(Our interpretation.)

- Two fold granularities map well onto JacKnife: one line per completed execution, then one block per completed task. The second can be produced by the harness at the task boundary.
- AgentFold's folds are lossy and permanent. JacKnife's unfold-by-id removes the main risk the authors acknowledge (irreversible loss), at the price of needing the model to know when to unfold.
- Keeping only the latest observation verbatim is aggressive; for code work the last few tool results (current file view, last test output) probably need to stay unfolded.
- The need for SFT here is direct evidence that fold directives must be in the training trajectories if the model, not the harness, writes them.
