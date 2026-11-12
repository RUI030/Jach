# A Systematic Evaluation of Trajectory Data Curation for LoRA Fine-Tuning of Code Agents

- **Source:** https://arxiv.org/abs/2607.17205
- **Authors / org:** Yunze Han
- **Date:** 2026-07-19
- **Type:** paper
- **Read:** abstract only

## Summary

Read: abstract only. Details such as the exact scoring formula and thresholds are in the full paper and were not checked.

The paper studies how filtering teacher trajectories affects LoRA fine-tuning of a small coding model, Qwen2.5-Coder-7B-Instruct. The data source is a public trajectory set of 67,074 trajectories of which 32,161 resolved their task. The author defines a quality score with two axes, Efficiency and Style, and runs 16 controlled experiments that vary the selection strategy, the dataset size, and which components of the score are used.

Because 7B models resolve close to zero SWE-bench tasks, the study does not use resolve rate. Its main metric is cross-entropy loss on held-out trajectories, checked against a first-action generation test; the abstract reports a perfect rank correlation (Spearman -1.00) between that loss and ROUGE-L and says this validation rests on a limited sample.

Findings as stated in the abstract. Quantity dominates at small scale: going from 500 to 1,000 trajectories lowers held-out loss by about 12.7%, while at those sizes choosing the top-scored trajectories instead of random ones changes loss by under 1% (not significant, p > 0.10). Quality selection starts to matter at larger scale: at 2,000 trajectories the top-quality subset is 3.6% better than random (p = 0.016). In the ablation, one component of the score, the error-retry rate of a trajectory, accounts for nearly all of the effect: using it alone is within 0.2% of the full composite score.

Scope is narrow: one base model, one trajectory source, a single author, and a proxy metric instead of task success. The findings should be treated as suggestive.

## Key points

- At a few hundred to a thousand trajectories, adding data beats filtering data.
- Quality-based selection gave a small but significant gain at 2,000 trajectories.
- Error-retry rate was the most informative single quality signal.
- Held-out loss is used as a proxy because small models score near zero on SWE-bench.
- Single-author study with a proxy metric; not independently confirmed.

## Relevance to JacKnife

(Our interpretation.)

- For the first dataset (hundreds of trajectories), do not spend effort on fine-grained quality ranking beyond pass/fail verification; add more verified data instead.
- Error-retry rate is cheap to compute and worth logging per trajectory from the start. Note the tension with recovery examples: trajectories with many retries score low here, yet some recovery is wanted. A workable reading is to keep a bounded number of retries and drop trajectories that thrash.
- The metric problem applies to JacKnife too: if end-to-end success is near zero early on, use per-state measures (valid tool call rate, next-action agreement with teacher, held-out loss) until task success becomes measurable.
