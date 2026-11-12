# Where Coding Agents Fail on SWE-bench, and Whether a Reviewer Agent Helps

A method note based on "An Empirical Study on Failures in Automated Issue Solving" [1].

- **Evidence:** B. Hand-annotated failure taxonomy with reported agreement, plus one mitigation experiment; preprint, one backbone model, Python only, mitigation compared against a baseline that uses a different model.
- **Numbers checked against the source:** yes, 2026-11-11, against the arXiv HTML (v1). Per-subcategory shares appear only in figures and are not used here.

## 1. Problem

SWE-bench reports one solve rate per tool, which hides why the failures happen. The paper asks where pipeline tools and agentic tools fail, how failures change with task difficulty, and whether an overseeing agent can recover failed issues.

## 2. Method

This is a failure taxonomy, so this section holds the classification and the findings a design can act on.

The authors used the official SWE-bench Verified logs of three tools, all on Claude 3.5 Sonnet: OpenHands CodeAct 2.1 (agentic), Tools + Claude 3.5 Sonnet (agentic, standard scaffolding) and Agentless 1.5 (pipeline) [1, §3.2.1]. From the 329 issues that at least one tool failed, they sampled 150 [1, §3.2.2]. Four annotators double-coded each case over about 720 person-hours, with pairwise Cohen's kappa of 0.72 to 0.77 [1, §5.1]. They found 342 failure instances in 3 phases, 9 categories and 25 subcategories [1, §5.2].

The Iteration & Validation phase holds the loop-like modes [1, §5.2.C]:

| Code | Mode | What it looks like |
|---|---|---|
| C1.1 | Reproduction run failure | Test setup broken for environment reasons |
| C1.2 | Insufficient verification | Checks only that code runs, not that output is right |
| C1.3 | Reproduction output misreading | Concludes success when output shows failure |
| C2.1 | Non-progressive iteration | Near-identical patches regenerated with cosmetic changes |
| C2.2 | Blind strategy switching | Drops an approach for an unrelated one, fixes fragment |
| C2.3 | Validation retreat | Edits the test to pass instead of fixing the code |
| C3 | Context amnesia | Loses the goal, or edits with strings from the original file |

### Findings a design can act on

1. **Architecture sets the failure profile.** 51.3% of Agentless's failed issues contain a localization error. 49.1% (OpenHands) and 51.7% (Tools Claude) of the agentic tools' failed issues contain an Iteration & Validation error [1, §6.1].
2. **Harder tasks shift failures into iteration.** For OpenHands, the Iteration & Validation share rises from 27% on easy tasks to 64% on hard ones [1, §6.1].
3. **Success comes early; failure runs long.** 80% of successes take at most 19 rounds for Tools Claude (median 11) and 25 for OpenHands (median 16). OpenHands needs 54 rounds to cover 80% of its failures [1, §4.3, Fig. 5]. Failed issues average 3.5 times more interaction steps than successful ones [1, §6.2.2].
4. **Causes are mostly reasoning.** About 65% of failures trace to flawed reasoning, 25% to missing knowledge and 10% to environment friction [1, §6.2.1].
5. **An overseer recovers some failures.** The Expert-Executor design on OpenHands has the executor consult an expert at fixed points and when stuck. The expert also reviews the history passively. Its prompt lists every failure mode in the taxonomy with an explanation [1, §7.1].

## 3. Evidence

- On the full 500 issues, OpenHands solved 53.0%, Agentless 50.8% and Tools Claude 49.0% [1, §4.1].
- Expert-Executor, both roles Claude 3.5 Sonnet, passive review interval 25, round limit 40: 24 of the 108 issues the OpenHands baseline had failed were solved (22.2%) [1, §7.2].
- A single-agent OpenHands with Claude 4 Sonnet solved 7 of the same 108 [1, §7.2].
- The expert's fixes most often addressed reproduction output misreading (6 of the 24), evasive repair (5) and control-flow defects (5) [1, §7.2].

## 4. Evidence boundaries

- One backbone model (Claude 3.5 Sonnet), Python only, 12 repositories [1, §8.2]. No small or fine-tuned model is studied.
- The mitigation has no same-model, same-round-limit single-agent control. Its comparison baseline uses a different model, Claude 4 Sonnet, with no stated round limit. The 22.2% therefore mixes the effect of oversight with the effect of a second model call budget.
- With a 40-round limit and a 25-round interval, passive review can fire at most once per run. That is our reading of the settings; the paper does not say how often it fired.
- The replication package is on an anonymous host [1, Abstract], which may not stay available.
- Category shares count issues containing at least one error of a kind, so they overlap and do not sum to 100%.

## 5. What we take from it

Our interpretation, not the paper's claims.

- A per-task step budget is justified. Past a modest number of rounds, success is rare, so escalating early is cheaper than letting the task run.
- Validation retreat and evasive repair are reasons to keep acceptance checks owned by the harness and out of the model's reach.
- The Expert-Executor design is close to our admin mechanism. Both triggers fit: on demand from a stuck detector, and a periodic review at a fixed step count.
- Misread checker output was the most fixable failure. Our checker output for the small model should be short and unambiguous about pass or fail.

## Reference

[1] Simiao Liu, Fang Liu, Liehao Li, Xin Tan, Yinghao Zhu, Xiaoli Lian, Li Zhang (Beihang University; University of Hong Kong). *An Empirical Study on Failures in Automated Issue Solving.* arXiv:2509.13941v1, 17 September 2025. <https://arxiv.org/html/2509.13941v1>. Accessed 2026-11-11.
