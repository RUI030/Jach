# Expert Takeover Mid-Trajectory as Training Data (On-Policy Expert Corrections)

A method note based on the OEC paper [1].

- **Evidence:** B. Controlled ablations at 7B and 32B with public code; single-group preprint, one domain, one round of collection, no variance reported.
- **Numbers checked against the source:** yes, 2026-11-11, against the arXiv HTML (v1).

## 1. Problem

Coding agents are commonly trained by imitating expert trajectories. The paper measures how far a student's histories drift from the expert's: comparing embedded histories turn by turn, the Fréchet distance dips until about turn 10, rises sharply until turn 30, then keeps rising, even for students already trained by imitation. [1, §4.3, Fig. 4] Training only on expert data never shows the student what to do from where it actually ends up.

## 2. Method

The student starts a task and runs for a number of turns drawn uniformly from 0 to 30. Then the expert takes over from that state and runs to the end. [1, §3.1, Algorithm 1; §4.1]

- The history is rewritten into the expert's format (system prompt, problem statement, tool-call syntax). The expert is not told another model produced the earlier turns. [1, §3.1]
- Only trajectories whose patch passes all unit tests are kept (rejection sampling). [1, §3.2]
- Loss is applied only to the expert's turns; the student prefix is context but masked. A trajectory that ends before the switch is discarded. [1, §3.2]
- Trajectories are discarded if the same action, arguments included, appears three times in a row, or if any file-reading command runs 20 or more times in a row. [1, §3.3]

### Key decisions

1. **Switch at a random turn** to cover as much of the student's state distribution as possible. [1, §3.1]
2. **Let the expert finish rather than label one step.** This lets the run be judged by unit tests, which per-step DAgger labels cannot be. [1, §3.1]
3. **Filter loops even among passing runs.** Some easy tasks are solved despite a loop, so test-passing alone admits loop data. [1, §4.2]

### Implementation details that generalise

- Mix correction data with ordinary expert trajectories. At 7B, 1,000 original expert trajectories were mixed into every run as regularisation; at 32B, equal OEC and expert counts worked best. [1, §4.2]
- Do not train on the student's own full trajectories: at 7B they gave little or no gain, at 32B they "severely decreased" performance, even after test filtering. [1, §4.2, Fig. 2]

## 3. Evidence

Students: Qwen2.5-Coder 7B and 32B, first fine-tuned on Claude 3.7 Sonnet trajectories. Expert: SWE-agent-LM-32B in the 7B setting, Claude 3.7 Sonnet in the 32B setting. SWE-agent scaffold, SWE-smith training tasks. [1, §4.1]

| Model | SWE-bench Verified |
|---|---|
| OEC 7B | 20.8% |
| SWE-smith-LM-7B (reported) | 15.2% |
| OEC 32B | 40.0% |
| SWE-smith-LM-32B (authors' re-evaluation / reported) | 36.4% / 40.2% |

[1, §4.1, Table 1] The abstract reports relative gains of 14% (7B) and 13% (32B) over standard imitation. At 32B, 961 OEC plus 961 expert trajectories resolved 23 more Verified tasks (4.6 points) than 2,000 expert trajectories. [1, §4.2]

Ablations (7B on SWE-bench Lite, 32B on Verified): [1, §4.2, Table 2]

| Student | No training | With OEC | No prefix masking | No repetition filter |
|---|---|---|---|---|
| 7B | 13.3% | 17% | 17% | 11% |
| 32B | 31.2% | 40% | 31.8% | 36.4% |

- The repetition filter removed 8.46% of samples at 7B and 3.63% at 32B. [1, §4.2]
- Switch point: training sets drawn from switches at turns 0-6, 7-15 and 16-30 gave 31%, 32.4% and 32.6%. [1, §4.2]
- Even the best model's no-submission failures were mostly loops: 53.7% of no-submission failures, against 58.0% for the untrained 32B student (LLM judge). [1, §4.4, Table 3]

## 4. Evidence boundaries

- One round of collection; not iterated as DAgger is.
- No seeds or error bars. The switch-point differences (31 to 32.6) and several ablation gaps are a few tasks.
- The 7B headline compares against a reported number, not a re-run; the authors' own re-evaluation of the 32B baseline came in 3.8 points below its reported value.
- Masking mattered only at 32B; at 7B it made no difference. The filter mattered more at 7B.
- The students were already decent SWE agents. A student that starts much weaker is not tested.

## 5. What we take from it

Our interpretation, not the paper's claims.

- An admin takeover in our harness produces this data shape directly: a small-model prefix, then an expert continuation, judged by checks the model cannot influence.
- Data rules to adopt: mask the small model's turns in the loss; keep only tasks that pass acceptance checks; drop trajectories with repeated identical calls or long read streaks. At 7B, skipping the filter made the model worse than no training.
- Their expert was not told it was taking over. Our admin is called because the model is stuck, so its first turns may be explicit recovery. That could make our data richer in recovery examples, which we lack (10 of 2,082 replies), but this is untested.
- Our 9B model keeps looping after a LOOP DETECTED message in 6 of 12 tasks. Takeover right after a loop signal would put the switch point exactly in the states we most need labelled.

## Reference

[1] Niklas Lauffer (UC Berkeley; work done at Scale AI), Xiang Deng, Srivatsa Kundurthy, Brad Kenstler, Jeff Da (Scale AI). *Imitation Learning for Multi-turn LM Agents via On-policy Expert Corrections.* arXiv:2512.14895v1, December 2025. <https://arxiv.org/html/2512.14895v1>. Code: <https://github.com/niklaslauffer/on-policy-expert-corrections>. Accessed 2026-11-11.
