# Model-Written Multi-Scale History Folding at Every Step

A method note based on AgentFold [1].

- **Evidence:** B. Single-group preprint with an SFT-trained model; context-size measurements are direct, but accuracy is compared against other papers' systems, not against the same model without folding.
- **Numbers checked against the source:** yes, 2026-11-11, against the arXiv HTML (v1).

## 1. Problem

An append-only ReAct history fills the context with noisy raw observations. Re-summarising the whole history at every step loses details irreversibly, and the loss compounds over steps. The paper asks whether an agent can curate its own history at several levels of detail. [1, Abstract, §3.5]

## 2. Method

The context at step *t* has four parts: the question, the tool schemas, a sequence of summary blocks, and the latest interaction in full (last explanation, action and observation). Each summary block covers a contiguous range of past steps, and the ranges partition the whole history. [1, §3.2, Eq. 1–2]

Each response has four parts: thinking, a folding directive, a short explanation, and an action. The folding directive is a JSON object with a step range `[k, t−1]` and replacement text. All blocks in that range are replaced by the new text. [1, §3.3, Eq. 3]

### Key decisions

1. **Two fold granularities in one format.** *Granular condensation* (k = t−1) folds only the latest step into its own block. *Deep consolidation* (k < t−1) merges the latest step with earlier blocks into one coarser block, for example when a sub-task is finished or a line of inquiry failed. [1, §3.3]
2. **A fold decision on every step.** Folding is part of each response, not a separate trigger. [1, §3.1]
3. **Only the latest interaction is verbatim.** Everything older is a summary block. [1, §3.2]
4. **Trained, not prompted.** The authors found that even the strongest LLMs could not reliably produce the format by prompting alone. [1, §3.4]

### Implementation details that generalise

- Training data came from a generator pipeline built on open-source LLMs. Rejection sampling dropped any step that broke the format and any trajectory with too many environment errors; the result was used for plain SFT. [1, §3.4]
- Delaying consolidation until a sub-task's outcome is known lets the fold record the conclusion, not the attempts. [1, §3.5]
- The authors' illustrative arithmetic: a 1% loss per full re-summary leaves a step-1 detail with about 36.6% survival after 100 steps and 0.66% after 500. This is an assumption, not a measurement. [1, §3.5]

## 3. Evidence

Model: Qwen3-30B-A3B-Instruct-2507 (30B total, 3B active), SFT only. Tool calls capped at 100. Benchmarks under 200 items are averaged over 3 trials. Some baseline numbers are taken from other papers or leaderboards. [1, §4]

| Benchmark | AgentFold-30B-A3B | Comparison |
|---|---|---|
| BrowseComp | 36.2 | DeepSeek-V3.1-671B 30.0; o4-mini 28.3; o3 49.7 |
| BrowseComp-ZH | 47.3 | DeepSeek-V3.1 49.2 |
| WideSearch (Item-F1) | 62.1 | Claude-4-Sonnet 62.0; o3 60.0 |
| GAIA (text-only) | 67.0 | o3 70.5 |

[1, §4.1, Table 1]

Context size, 200 BrowseComp trajectories [1, §4.1, Fig. 1, Fig. 3]:

- Average context grew from about 3.5k to about 7k tokens over 100 turns.
- At turn 100 the context was on average over 84k tokens (92%) smaller than ReAct's on the same trajectories.
- Over 20% of tasks hit the 100-turn limit and were counted as failures.
- In a 500-turn run the context mostly stayed under 20k tokens and did not grow monotonically, because failed sub-trajectories were consolidated.

Turn scaling on BrowseComp: accuracy kept rising up to a 256-turn limit, while a GLM-4.5-355B ReAct baseline saturated beyond 64 turns. [1, §4.1, Fig. 4]

## 4. Evidence boundaries

- **No ablation of folding.** There is no run of the same model, trained on the same questions, without folding. The accuracy table mixes systems with different training data.
- **No error bars**, and only 3 trials on the small benchmarks.
- **Web information seeking only.** Observations are search results and pages, not code, test logs or compiler errors.
- **Smallest model 30B MoE (3B active).** Nothing at 9B dense, and no fine-tuned domain model.
- **Folds are permanent.** There is no way to recover detail once consolidated, and no measurement of how often lost detail caused a failure.
- SFT only; the authors name RL as future work. [1, §5]

## 5. What we take from it

Our interpretation, not the paper's claims.

- Two granularities fit our state machine: one line per completed execution, and one block per completed task written at the task boundary by the harness.
- Keeping only the latest observation verbatim is too aggressive for code work. The current file view and the last test or compiler output should stay unfolded.
- Consolidating a failed approach into one conclusive line is worth copying, but the line must say that it failed and why, so a repeat is visible.
- If the model ever writes fold directives, they must be in the training data in our exact format; the paper found prompting unreliable even for strong models.

## Reference

[1] Rui Ye, Zhongwang Zhang, Kuan Li, Huifeng Yin, Zhengwei Tao, Yida Zhao, Liangcai Su, Liwen Zhang, Zile Qiao, Xinyu Wang, Pengjun Xie, Fei Huang, Siheng Chen, Jingren Zhou, Yong Jiang (Tongyi Lab, Alibaba Group). *AgentFold: Long-Horizon Web Agents with Proactive Context Management.* arXiv:2510.24699v1, 2025-10-28. <https://arxiv.org/html/2510.24699v1>. Accessed 2026-11-11.
