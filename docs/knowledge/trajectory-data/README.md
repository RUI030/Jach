# Trajectory data

How training data for agentic fine-tuning is built: generating tasks with executable checks, collecting teacher trajectories, deciding which to keep, how to treat failures and error turns, how to format the data and mask the loss, and how small fine-tuned agents are evaluated. All files were written from sources fetched and read on 2026-11-11.

| File | One-line takeaway |
|---|---|
| [swe-smith.md](swe-smith.md) | Inject bugs into repositories with shared environments; 5k verified teacher trajectories took a 32B model to 40.2%, but the student loops far more than the teacher. |
| [swe-gym.md](swe-gym.md) | 491 successful trajectories already give large gains; cap per task; self-generated data hurt in a free scaffold and helped in a constrained one. |
| [r2e-gym.md](r2e-gym.md) | Tasks mined from commits; training with thoughts adds about 4 points; a 14B model saturated near 800 trajectories. |
| [swe-dev.md](swe-dev.md) | LLM patch-similarity filtering when tests are missing; a 7B model improved log-linearly up to 16k trajectories. |
| [devstral.md](devstral.md) | Staged training: loosely filtered data first, strictly filtered data last; results depend on scaffold and template. |
| [agent-flan.md](agent-flan.md) | Models overfit the output template first; use the native chat format, assistant-only loss, capability balancing and negative samples. |
| [learning-from-failure-nat.md](learning-from-failure-nat.md) | Tagged failed trajectories help when positives are scarce and the failures come from a strong teacher. |
| [rome-error-masked-training.md](rome-error-masked-training.md) | Keep error turns in context but zero their loss; also mask turns whose context was pruned. |
| [trajectory-curation-lora.md](trajectory-curation-lora.md) | (Abstract only.) For a 7B model, quantity beats quality filtering below about 1k trajectories; error-retry rate is the key quality signal. |

## Patterns across sources

- **Agreement: the base filter is execution.** SWE-smith, SWE-Gym, R2E-Gym and Devstral keep only trajectories whose final patch passes tests. SWE-Dev falls back to LLM-judged similarity with a reference patch when tests are missing. ROME warns that passing tests does not rule out a logically wrong trajectory.
- **Agreement: plain supervised fine-tuning on successful teacher trajectories is the strong baseline.** SWE-Dev found it beat offline RL with negatives; SWE-smith, SWE-Gym and R2E-Gym use nothing else.
- **Agreement: cap trajectories per task.** SWE-smith uses three, SWE-Gym found two best. Uncapped sampling over-represents easy tasks.
- **Agreement: loss only on model-generated tokens.** Agent-FLAN, NAT, ROME and FoldGRPO (see `../context-management/context-folding-foldgrpo.md`) all mask tool outputs and other inputs.
- **Disagreement: how much data a small model can use.** R2E-Gym's 14B model saturated near 800 trajectories; SWE-Dev's 7B model kept improving to 16k; Agent-FLAN got most of its gain from 25% of its data; the LoRA curation study says quantity dominates below 1k. Scaffolds, teachers and metrics differ, so the saturation point for a 9B model in a new harness has to be measured.
- **Disagreement: what to do with failures.** Most pipelines discard failed trajectories. NAT keeps them with an outcome tag and gains when positives are scarce. ROME keeps error turns as context and zeroes their loss. SWE-Gym uses failures only to train a verifier. These are compatible if separated: whole failed runs (tag or drop) versus error turns inside successful runs (keep, mask loss).
- **Disagreement: on-policy data.** SWE-Gym saw a drop when adding student trajectories in an open-ended scaffold and a gain in a constrained workflow; NAT found weak-model failures harmful; Devstral uses its own rollouts in a late stage without giving details.
- **Evaluation is fragile for small models.** SWE-smith and SWE-Gym track loop rate and empty patches next to resolve rate; Devstral shows several points of movement from turn limit and retry protocol; the LoRA study falls back to held-out loss because 7B resolve rates are near zero.
- **Gap.** No source trains on trajectories rendered with a context-folding harness for a small model, and none isolates the value of recovery segments in coding trajectories. Nothing specific to Nemotron or to a Qwen tool-use fine-tuning report was read in this session.
