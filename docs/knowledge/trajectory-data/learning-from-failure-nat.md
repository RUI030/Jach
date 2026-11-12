# Training on Failed Trajectories with an Outcome Tag (Negative-Aware Training)

A method note based on "Learning From Failure" [1].

- **Evidence:** B. Controlled comparisons with public code and data; preprint; short tool-use tasks (math, QA), Llama-2 7B and 13B.
- **Numbers checked against the source:** yes, 2026-11-11, against the arXiv HTML.

## 1. Problem

Agent fine-tuning data is usually built by running a strong model and keeping only the trajectories that reach the right answer. The rest are discarded. When successful trajectories are scarce, that throws away most of what was paid for. Can failed trajectories be used, and how? [1, Abstract, §1]

## 2. Method

GPT-3.5 runs as a ReAct agent three times per task at temperatures 0.2, 0.5 and 0.7. Each trajectory is labelled positive or negative by comparing its final answer with the ground truth. [1, §3.3]

Three training regimes are compared. [1, §4.1]

| Regime | Training data |
|---|---|
| Vanilla | Positives only |
| NUT (negative-unaware) | Positives and negatives, no distinction |
| NAT (negative-aware) | Positives and negatives, each with a suffix on the query saying whether the solution answers correctly or incorrectly |

At inference the "correct" suffix is always used. Loss is computed only on model-generated text. [1, §3.3]

### Key decisions

1. **Label, do not filter.** The tag lets the model use the reasoning in failed runs without being told to reproduce them. [1, §3.1]
2. **The tag only has to separate the two sets.** Meaningful wording and random strings gave averages between 63.15 and 64.04. [1, §5.4, Table 7]
3. **Finer tags can help.** NAT-2 splits HotpotQA negatives into two quality bands by F1 with separate tags. [1, §6.1]

### Implementation details that generalise

- Negatives must come from a strong model. Negatives from a fine-tuned 7B model made results worse. [1, §5.2, Table 5]
- The useful number of negatives depends on the number of positives. It is not a fixed ratio. [1, §5.1]
- The method needs a ground-truth outcome for every trajectory. [1, §8]

## 3. Evidence

Math average over GSM8K, ASDiv, SVAMP and MultiArith. [1, §4.2, Table 2]

| Model, positives | Vanilla | NUT | NAT |
|---|---|---|---|
| 7B, 2k | 55.90 | 63.39 | 64.64 |
| 7B, 5k | 64.17 | 64.95 | 67.42 |
| 13B, 2k | 65.18 | 66.53 | 67.74 |
| 13B, 5k | 70.76 | 69.10 | 71.28 |

- The gain shrinks as positives grow: +8.74 points at 7B/2k, +0.52 at 13B/5k. Untagged mixing fell below Vanilla at 13B/5k. [1, §4.2, Table 2]
- StrategyQA (1k positives, 500 negatives): 55.40 → 62.40 (NUT) → 65.80 (NAT) at 7B. [1, Table 4]
- HotpotQA (mean of 5 runs), 7B EM: 27.44 Vanilla, 28.80 NAT, 29.76 NAT-2. [1, Table 3]
- **Negative quality decides the sign.** 10k negatives from a fine-tuned Llama-2-7B gave −3.16 points at 2k positives and −6.20 at 5k, against +8.74 and +3.25 for GPT-3.5 negatives. [1, §5.2, Table 5]
- **More negatives help up to a point.** With 2k or 5k positives, math accuracy rose until about 11k negatives and then levelled off. [1, §5.1, Fig. 2] On HotpotQA with 500 positives, NAT peaked at 500 negatives and fell after; NAT-2 peaked at 1k. [1, §6.1, Fig. 5]
- **Negatives raise tool-call errors, tagged or not.** On GSM8K at 7B/2k the action error rate was 3.58% (Vanilla), 10.47% (NUT) and 7.90% (NAT). The training data had 4.01% action errors in positives only and 15.33% with negatives. [1, §5.3, Table 6]
- Runs also got longer: 3.12, 3.92 and 3.71 turns on average. [1, Table 6]
- The authors conclude negatives mainly improve reasoning, not acting, and that NAT trades better thoughts against fewer added action errors than NUT. [1, §5.3]

## 4. Evidence boundaries

- **Tasks are short.** About three to four turns, one tool each (calculator or search). No coding, no long sessions.
- **"Negative" means a wrong final answer.** It is not an error turn inside a run that later succeeds.
- **Error bars are given only for HotpotQA**, as a 5-run mean; the math tables are single numbers.
- **Models are Llama-2-Chat 7B and 13B**, with a GPT-3.5 teacher.
- **The analysis of quantity, quality and errors is on math only.** [1, §5]

## 5. What we take from it

Our interpretation, not the paper's claims.

- Do not put the 9B model's own failed runs into its training data, tagged or not. The low-quality-negatives result is the direct evidence against it.
- Failed runs from the admin model are a different case. While verified Jac trajectories are few, they may add value with an outcome tag (acceptance criteria met or not) in the task message. They should be dropped once positives are plentiful.
- Tool-call correctness is our weak point, and negatives more than doubled the action error rate here even with the tag. Any trial must report tool-error rate per phase, not only task success.
- Recovery data (an error followed by a fix in a run that succeeds) is a positive example and is not what this paper tests.

## Reference

[1] Renxi Wang, Haonan Li, Xudong Han, Yixuan Zhang, Timothy Baldwin (LibrAI; MBZUAI; University of Melbourne). *Learning From Failure: Integrating Negative Examples when Fine-tuning Large Language Models as Agents.* arXiv:2402.11651 (v2). <https://arxiv.org/html/2402.11651>. Code: <https://github.com/Reason-Wang/NAT>. Accessed 2026-11-11.
