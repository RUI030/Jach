# Staged Trajectory Filtering and Evaluation Settings for a Small Coding-Agent Model

A method note based on the Devstral technical report [1].

- **Evidence:** D. Vendor technical report. The training recipe is described without data sizes, filter definitions or ablations; the only measured comparisons are of evaluation settings.
- **Numbers checked against the source:** yes, 2026-11-11, against the arXiv HTML (v1).

## 1. Problem

How should a mid-size open model (24B) be post-trained to work inside a coding-agent scaffold? How much do evaluation settings (turn limit, retries, temperature) move the reported score? [1, §1, §3]

## 2. Method

Devstral-Small is a 24B dense model based on Mistral Small 3, with 128k context. [1, §2.1]

**Data.** An agent runs in SWE-Gym environments with the OpenHands CodeAct scaffold, alternating reasoning and actions. Unit tests decide final patch quality. Some natural-language data is mixed in to keep general ability. [1, §2.2]

**Post-training.** [1, §2.3]

1. Train on a larger set of rollouts that pass a first, heuristic quality filter.
2. Fine-tune only on trajectories that pass the strictest filters.
3. Generate new rollouts with the fine-tuned model and train further with policy optimisation (algorithm not named).

**Second version (Devstral-Small-2507).** The data generation and filtering were refined through ablations (not reported). "Pseudo-scaffolds" were added for generalisation across scaffolds, and training used both XML and native function-calling prompt formats. The authors credit data quality for the improvement. [1, §4]

### Key decisions

1. **Broad data first, strict data last.** The loosely filtered pool supplies coverage; the strict pool sets final behaviour. [1, §2.3]
2. **Format diversity in version 2,** aimed at working in many scaffolds. [1, §4]
3. **A fixed evaluation harness:** OpenHands at a pinned commit, bash and file-edit tools only, built-in function-calling template, browsing off. [1, §3.1]

### Implementation details that generalise

- Even at temperature 0, agent runs are not deterministic, because of backend arithmetic and file-system state such as modification times. [1, §3.1]
- The "iterative evaluation protocol" allows up to 3 attempts per task, at temperature 0, then 0.1, then 0.1, preferring later solutions. [1, §3.1]

## 3. Evidence

All on SWE-bench Verified (500 tasks), with no error bars.

| Setting | Resolve rate | Source |
|---|---|---|
| Max 30 / 50 / 100 iterations (with retries) | 36.8% / 46.8% / 46.8% | [1, §3.3.1, Table 1] |
| Attempt 1 / up to 2 / up to 3 | 43.0% / 45.8% / 46.8% | [1, §3.4.1, Table 3] |
| Empty patches after attempt 1 / 2 / 3 | 7.6% / 0.0% / 0.0% | [1, Table 3] |
| Pass@1 at T = 0.1 / 0.4 / 0.7 / 1.0 (100 iterations, no retries) | 43.2 / 42.4 / 43.2 / 43.6% | [1, §3.4, Table 2] |
| Pass@4 at the same temperatures | 62.0 / 62.2 / 59.4 / 60.4% | [1, Table 2] |

- Attempts 2 and 3 ran on 191 and 121 instances. [1, Table 3]
- The authors found it "counter-intuitive" that lower temperatures scaled better with *k* than higher ones. [1, §3.4]
- Results for version 2 are shown only in a figure. [1, §4, Fig. 4]

## 4. Evidence boundaries

- **No trajectory counts, filter definitions, mixture ratios or training hyperparameters are given.** The staged recipe cannot be reproduced or checked from the report.
- **No ablation shows that staging helps.** The claim that data quality drove version 2's gain is not backed by a reported comparison.
- **The headline protocol is not pass@1.** It allows up to three attempts.
- **The comparison figures against other models** use reported numbers from different scaffolds. [1, §3.2, Fig. 2]
- **The model is 24B.**

## 5. What we take from it

Our interpretation, not the paper's claims.

- The most reliable content is about evaluation. A 10-point swing from the turn limit alone means our evaluation protocol (turn budget per phase, retries, temperature, harness version, fold settings) must be fixed and recorded with every result.
- Staged filtering is a reasonable default for mixing loosely and strictly verified trajectories. It is plausible, not demonstrated, and is consistent with SWE-Dev's finding that unverified data helps at volume ([swe-dev.md](swe-dev.md)).
- Devstral trained on several formats so the model would work in many scaffolds. We have one harness and one format, so format diversity is not a goal for us. A stable, versioned format is.
- Plain Jac data should be mixed in so harness training does not erode the existing Jac fine-tune. This report only states the practice; the evidence for it is in Agent-FLAN ([agent-flan.md](agent-flan.md)).

## Reference

[1] Baptiste Rozière, Graham Neubig, Gauthier Guinet, Guillaume Lample, Joachim Studnia, Kush Jain, Luyu Gao, Siddharth Gandhi, Wen-Ding Li, Xingyao Wang, and contributors (Mistral AI; All Hands AI). *Devstral: Fine-tuning Language Models for Coding Agent Applications.* arXiv:2509.25193 (v1). <https://arxiv.org/html/2509.25193v1>. Accessed 2026-11-11.
