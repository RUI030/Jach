# Strong Model Decomposes, Small Model Executes Single-Step Jobs (Minions)

A method note based on the Minions paper [1].

- **Evidence:** B. Controlled comparisons and ablations across model sizes and families; single-group preprint, document QA only, costs modelled rather than billed.
- **Numbers checked against the source:** yes, 2026-11-11, against the arXiv HTML (v1).

## 1. Problem

A small local model can read a long document at no API cost; a cloud model is expensive per token. Can the two collaborate so the cloud model rarely reads the document, without losing much accuracy? Tasks are question answering over long financial, medical and scientific documents. [1, Abstract, §3]

## 2. Method

Two protocols are compared. [1, §4, §5]

- **Minion (free chat).** The local model holds the document, the remote model holds the question, and they talk until the remote model answers.
- **MinionS (decomposition).** A loop of three steps. [1, §5.1]
  1. The remote model, without seeing the document, writes code that produces a list of jobs, each a single instruction paired with one chunk.
  2. The local model runs the jobs in parallel. It may abstain; otherwise it returns JSON with explanation, citation and answer. Abstentions are discarded.
  3. The remote model reads the filtered outputs and either answers or starts another round.

### Key decisions

1. **Design around measured small-model weaknesses.** In free chat the remote model often gave complicated instructions over long contexts. Two micro-experiments on Llama-3.2-3B: going from 1 to 4 sub-tasks in one instruction cost 56.3 points, and growing the context from 512 to 65.5K tokens cost 13 points on a simple extraction. [1, §4, App. E.2]
2. **Abstain, then filter.** Many jobs are irrelevant to their chunk; abstention keeps noise and tokens away from the remote model. [1, §5.1]
3. **Cap the rounds.** After the maximum, the synthesis prompt forces a final answer. [1, §5.2]

### Implementation details that generalise

- Between rounds, carrying the whole conversation is costly. Carrying only the remote model's advice (retries) or a remote-written scratchpad are the cheaper options; scratchpad was slightly better on cost per accuracy. [1, §5.1, §6.4]
- More decomposition helps up to a point, and every knob raises remote cost: 1 to 16 jobs per round gave up to +14 points at twice the remote prefill, and more than 16 hurt; 1 to 32 samples per job gave +7.4 points at 5× prefill, and more than 16 hurt; smaller chunks (100 pages to 5) gave +11.7 points at 2.41× prefill. [1, §6.3]

## 3. Evidence

Remote model GPT-4o; local Llama and Qwen2.5 models from 1B to 8B; FinanceBench (64 problems), LongHealth (400) and QASPER (500 sampled). Cost is the per-query GPT-4o bill; local compute is treated as free. [1, §6.1, App. B, Table 1]

| Protocol | Local model | Macro accuracy | Cost per query |
|---|---|---|---|
| Remote only | none | 0.724 | $0.233 |
| Local only | Llama-8B | 0.444 | $0 |
| Minion | Llama-8B | 0.630 | $0.008 |
| MinionS | Llama-8B | 0.709 | $0.042 |
| MinionS | Llama-3B | 0.662 | $0.052 |
| MinionS | Qwen-3B | 0.676 | $0.039 |

[1, §6, Table 1]

- Minion cut remote cost 30.4× and recovered 87% of remote-only accuracy. [1, Abstract]
- MinionS with the 8B model recovered 97.9% at 18.0% of the cost (5.7× cheaper). [1, §1, §6]
- Model size: the text gives 49.5% at 1B, 93.4% at 3B and 97.9% at 8B of remote-only accuracy, and calls 3B the point where MinionS "starts being competitive". [1, §6.2]
- Raising Minion's maximum rounds from 1 to 5 gave +8.5 points. [1, §6.4]

## 4. Evidence boundaries

- Document question answering only. Nothing here involves editing code, tool use, or multi-step state that the small model must maintain.
- Latency is modelled, not measured, and local compute is assumed free. [1, App. C, Table 1]
- FinanceBench has 64 problems and all ablations use 128-problem subsets; no confidence intervals are given. [1, App. B]
- The 3B figures depend on family. The text's 93.4% matches Qwen-3B in Table 1; Llama-3B reached 91.4% at higher cost (our computation from Table 1).
- The "87%" for Minion is stated both as share of remote accuracy (abstract) and as share of the remote-local gap closed (§4); Table 1 supports the first.

## 5. What we take from it

Our interpretation, not the paper's claims.

- Supports the harness-owned task split: give the 9B model one single-step task with short, relevant context, and let something else decompose and aggregate.
- The admin can act as planner (task list and acceptance criteria) without reading the whole repository, keeping its cost low. That is a fourth intervention mode beside advice, rewrite and takeover.
- An acceptance criterion of the form "do A, then B, then verify C" should be split into separate tasks. The compound-instruction drop was measured on a 3B model, not on ours, so its size for our 9B model is unknown.
- An explicit "cannot do this" output, filtered by the harness, is preferable to forcing an answer and is itself an escalation signal.

## Reference

[1] Avanika Narayan, Dan Biderman, Sabri Eyuboglu, Avner May, Scott Linderman, James Zou, Christopher Ré (Stanford University; Together AI). *Minions: Cost-efficient Collaboration Between On-device and Cloud Language Models.* arXiv:2502.15964v1, February 2025. <https://arxiv.org/html/2502.15964>. Accessed 2026-11-11.
