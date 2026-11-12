# Trajectory data

How training data for agentic fine-tuning is built: making tasks with executable checks, collecting teacher trajectories, deciding which to keep, what to do with failures and error turns, how to format targets and mask the loss, and how to evaluate the result. Most sources are SWE-bench-style Python work with students from 7B to 32B. None trains a model near 9B inside a harness that owns the workflow, so every transfer to JacKnife is an inference. All notes were checked against the source text on 2026-11-11.

| Note | Grade | One-line takeaway |
|---|---|---|
| [swe-smith.md](swe-smith.md) | B | Bugs injected into shared per-repository environments; 5k trajectories took a 32B student to 40.2%, but it repeats actions far more than its teacher and scaffold nudges did not help. |
| [swe-gym.md](swe-gym.md) | B | 491 teacher trajectories lift 7B-32B from near zero; student-generated data hurt in a free scaffold and helped slightly in a fixed workflow. |
| [r2e-gym.md](r2e-gym.md) | B | Tasks mined from commits train as well as real issues; thoughts in the targets add 4 points; trajectory-reading verifiers can be fooled. |
| [swe-dev.md](swe-dev.md) | B | Unverified teacher runs keep helping a 7B model up to 16k; verified ones are worth more each; plain fine-tuning beat offline RL. |
| [trajectory-curation-lora.md](trajectory-curation-lora.md) | B | For a 7B LoRA, doubling data beats quality ranking up to 1,000 trajectories; a rare tool-call format was never learned. |
| [agent-flan.md](agent-flan.md) | B | Align targets with the chat template, weight slow-learned skills, and add "do not call a tool" examples. |
| [learning-from-failure-nat.md](learning-from-failure-nat.md) | B | Tagged failures from a strong teacher help when positives are scarce; a weak model's failures hurt; negatives raise tool errors. |
| [rome-error-masked-training.md](rome-error-masked-training.md) | D | Zero the loss on turns that errored or whose context was altered; described but not ablated. |
| [devstral.md](devstral.md) | D | Staged loose-then-strict filtering (undocumented); the turn limit alone moved the score 10 points. |

## Patterns across sources

- **The default filter is "tests pass", but its value is contested.** SWE-smith, SWE-Gym and R2E-Gym train only on resolved trajectories, and SWE-smith found resolved-only better than random at 100-1,600 trajectories, shown only in a figure (`swe-smith.md`). The LoRA curation study found no gain from resolved-only at 500, measured by loss: 0.4786 vs 0.4737, p = 0.78 (`trajectory-curation-lora.md`). SWE-Dev found unverified trajectories useful at volume (`swe-dev.md`). ROME warns that some passing trajectories are logically wrong; that rests on grade D evidence (`rome-error-masked-training.md`).
- **Plain fine-tuning on good teacher trajectories is the baseline to beat.** In SWE-Dev, RFT reached 18.0% with 2,000 trajectories. KTO reached 17.2% and OREO 17.0% with 1,800. Every RFT+OREO split was below RFT alone (`swe-dev.md`). NAT is the only positive result for adding negatives, on short QA and math tasks (`learning-from-failure-nat.md`).
- **Cap trajectories per task.** SWE-smith used 3 and SWE-Gym 2. The direct evidence is small: in SWE-Gym, cap 2 gave 9.7% and no cap 9.3% on 300 Lite tasks (`swe-gym.md`, `swe-smith.md`).
- **The training targets must be in the student's own output format, and that format must be frequent.** SWE-smith states that training on the teacher's function-calling format "does not work" without conversion to XML (`swe-smith.md`). Agent-FLAN's chat alignment raised T-Eval from 61.8 to 64.9 (`agent-flan.md`). In the LoRA study, tool-call turns were 0-3% of the data and no model emitted a well-formed tool call (`trajectory-curation-lora.md`). Devstral's move to several formats rests on grade D evidence (`devstral.md`).
- **Loss belongs on model-generated tokens only, and possibly not on every one of those.** Agent-FLAN, NAT and the LoRA study mask non-assistant tokens. ROME also masks errored turns and turns with altered context, but it is grade D and gives no ablation (`agent-flan.md`, `learning-from-failure-nat.md`, `trajectory-curation-lora.md`, `rome-error-masked-training.md`).
- **Students loop more than their teachers, and fine-tuning alone does not fix it.** In SWE-smith, over 25% of the 32B student's runs contained 10 or more repeats, against under 4% for the teacher. Warnings and resampling cut repetition but resolves fell from 40.2% to 38.4% (`swe-smith.md`). In SWE-Gym, fine-tuning lowered the 7B loop rate from 39.6% to 21.0% on Verified, but the 32B rate rose on Lite, from 16.7% to 18.1% (`swe-gym.md`).
- **Reported scores move with evaluation settings.** Devstral: 36.8% at 30 turns, 46.8% at 50; grade D (`devstral.md`). SWE-Dev: 34.0% at 30 rounds, 36.6% at 75 (`swe-dev.md`). The LoRA study uses held-out loss because 7B resolve rates are near 1% (`trajectory-curation-lora.md`).

### Where sources disagree

**How many trajectories are enough.** Settings differ in teacher, scaffold, verification and metric, so the numbers below do not locate one saturation point.

| Source | Student | Data | Result |
|---|---|---|---|
| R2E-Gym | 14B / 32B | 100-3,200 verified | 14B "begins to saturate" near 800; 32B still improving (figure only) |
| SWE-Gym | 32B | up to 491 verified | Still rising at 491 (figure only) |
| SWE-smith | 32B | 500 / 5,016 verified | 28.2% / 40.2% |
| SWE-Dev | 7B | 574 / 16,639 unverified | 13.0% / 22.8%, log-linear, no plateau |
| LoRA curation | 7B (LoRA) | 500 / 1,000 / 2,000 resolved | Loss −12.6% per doubling to 1,000, then −6.5% (random) and −9.1% (top-scored); no plateau |
| Agent-FLAN | 7B | 25-100% of 24.7k | "Most" of the gain at 25% (figure only) |
| NAT | 7B / 13B | 2k vs 5k positives | Gain from negatives shrinks: +8.74 vs +3.25 at 7B |

**Whether student-generated data helps.**

| Source | Setting | Result |
|---|---|---|
| SWE-Gym | OpenHands, 32B, add 868 own successes to 491 teacher | Lite 15.3% → 8.7% |
| SWE-Gym | Fixed workflow, own successes, 2 iterations | 7B 7.0 → 10.0%; 32B 19.0 → 19.7% |
| SWE-Gym | Verifier trained on teacher + student runs | Best mix; teacher-only plateaued near 22% |
| NAT | Negatives from a fine-tuned 7B vs GPT-3.5 | −3.16 vs +8.74 (2k positives); −6.20 vs +3.25 (5k) |
| SWE-Dev | Offline RL with partly on-policy negatives | 17.0-17.2% vs RFT 18.0% |
| Devstral | Late-stage own rollouts | Used; no numbers (grade D) |

## Gaps

- No source trains or evaluates a model near 9B in a harness that owns the phase workflow. SWE-Gym's fixed-workflow scaffold is the closest.
- None trains on trajectories rendered through context folding, or measures what happens when training and inference history policies differ. SWE-smith only keeps the same truncation in both.
- None isolates the value of recovery segments (error, then a fix, in a run that succeeds). NAT studies whole failed runs; ROME masks error turns but does not measure the effect.
- None tests data in which a stronger model intervenes mid-run, which is our planned recovery data.
- None covers a low-resource language. SWE-smith's only cross-language result is negative: 8.4% against a 6.5% base.
- Full fine-tuning and LoRA are never compared on the same data.
