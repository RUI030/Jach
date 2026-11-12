# An Empirical Study on Failures in Automated Issue Solving

- **Source:** https://arxiv.org/html/2509.13941v1
- **Authors / org:** Simiao Liu, Fang Liu, Liehao Li, Xin Tan, Yinghao Zhu, Xiaoli Lian, Li Zhang (Beihang University; University of Hong Kong)
- **Date:** 17 September 2025
- **Type:** paper
- **Read:** full text (per-subcategory percentages are in figures and were not available as text)

## Summary

The authors analyse why coding agents fail on SWE-Bench-Verified, comparing two agentic tools (OpenHands CodeAct 2.1 and a tools-plus-Claude agent) with one fixed pipeline (Agentless 1.5), all on Claude 3.5 Sonnet. They hand-annotated 150 sampled failing issues (about 720 person-hours, kappa 0.72-0.77), found 342 failure instances, and organised them into three phases, nine categories and 25 subcategories: Localization, Repair, and Iteration & Validation.

The architectures fail differently. The pipeline fails early: 51.3% of its failed issues have a localization error. The agents fail late: about half of their failed issues (49.1% and 51.7%) show an Iteration & Validation error, and for OpenHands this share rises from 27% on easy tasks to 64% on hard ones. The iteration category contains the loop-like modes: non-progressive iteration, blind strategy switching, validation retreat (dropping a check that fails), misreading reproduction output, and context amnesia. Failed runs use about 3.5 times as many steps as successful ones; most successes come within roughly 25 rounds, followed by a long unproductive tail. The authors attribute about 65% of failures to flawed reasoning, 25% to missing knowledge and 10% to environment friction.

As mitigation they build an Expert-Executor design on OpenHands: the executor must consult an expert agent at key points, and the expert also reviews the session history every 25 rounds and intervenes. The expert prompt is organised around the failure taxonomy. On the 108 issues the baseline failed, this resolved 24 (22.2%). The comparison is not fully controlled (both roles use the same model, and the reference baseline uses a different one).

## Key points

- Agentic tools mostly fail in the iterate/validate phase, not in localization.
- Named loop variants: non-progressive iteration, blind strategy switching, validation retreat.
- Failed runs are about 3.5x longer; success after ~25 rounds is rare.
- A second agent that reviews periodically and on request recovered 22% of previously failed issues, even with the same underlying model.
- Most frequently fixed by the expert: misread reproduction output, evasive repair, control-flow defects.

## Relevance to JacKnife

(Our interpretation, not the source's claims.)

- A step budget per task is justified: beyond a modest number of rounds the chance of success falls sharply, so escalating early is cheaper than letting the task run.
- "Validation retreat" and "evasive repair" are reasons to keep acceptance criteria harness-owned and immutable from the model's side.
- The Expert-Executor design is close to our admin mechanism. Two triggers are worth having: on-demand (stuck detector) and periodic review at a fixed step count.
- Giving the admin model a failure taxonomy as a checklist is a concrete prompt-design idea for the admin role.
- "Misreading checker output" was the most fixable failure; our checker output format for the small model deserves attention.
