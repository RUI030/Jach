# Rejection-Sampling Fine-Tuning on Real Coding Tasks, Self-Improvement, and Verifiers

A method note based on SWE-Gym [1].

- **Evidence:** B. Controlled experiments with public environments, trajectories and models; preprint (venue not checked); 11 Python repositories.
- **Numbers checked against the source:** yes, 2026-11-11, against the arXiv HTML (v2).

## 1. Problem

Open models in a general coding-agent scaffold solve almost no SWE-bench tasks. Can a few hundred teacher trajectories from real, executable tasks change that, can the student then improve on its own rollouts, and can failed rollouts be put to use? [1, §1, §4]

## 2. Method

SWE-Gym is 2,438 tasks from 11 Python repositories not in SWE-bench, each with an issue, a repository snapshot, unit tests and a Docker image. Building it took about 200 annotation hours. [1, §3.1]

Training is rejection-sampling fine-tuning in two scaffolds: [1, §4.1-4.3]

| Scaffold | Character | Data |
|---|---|---|
| OpenHands CodeAct | General ReAct agent, bash and file editor, plans for itself | 491 successful trajectories from GPT-4o and Claude 3.5 Sonnet; about 19 turns and 19k tokens on average |
| MoatlessTools | Fixed workflow, short horizon | Student's own rollouts: 30 per task at temperature 1.0, successes kept, two iterations |

A separate outcome verifier, a 32B model, reads a trajectory and outputs YES or NO. It is used to pick one of *k* attempts. [1, §5.1]

### Key decisions

1. **Keep only test-passing trajectories.** [1, §4.1]
2. **Cap successes per task.** Repeated sampling over-represents easy tasks; a cap of 2 was chosen, preferring trajectories with fewer rounds. [1, §4.3]
3. **Use failures for the verifier, not the policy.** The verifier is trained on equal numbers of successes and failures. [1, §5.1.1]

### Implementation details that generalise

- Track "stuck in loop" (same action three times in a row) and "empty patch" (no edit made) next to resolve rate. [1, §4.1-4.2]
- Mixing teacher and student trajectories gave a better verifier than either alone. [1, §5.1.1, Fig. 8]

## 3. Evidence

OpenHands, Qwen2.5-Coder-Instruct, 491 trajectories, SWE-bench Verified (500 tasks). [1, §4.2, Table 3]

| Size | Resolve, zero-shot → tuned | Stuck in loop | Empty patch |
|---|---|---|---|
| 7B | 1.8 (±1.1) → 10.6 (±2.1) | 39.6 → 21.0 | 45.8 → 33.8 |
| 14B | 4.0 (±1.6) → 16.4 (±2.0) | 32.1 → 21.3 | 44.9 → 14.5 |
| 32B | 7.0 (±1.3) → 20.6 (±2.1) | 29.4 → 23.8 | 9.5 → 13.8 |

- On SWE-bench Lite the 32B model went from 3.0 to 15.3. Its loop rate rose slightly there (16.7 → 18.1), and its empty-patch rate rose on Verified. [1, Table 3]
- Performance was still rising at 491 trajectories for the 32B model (figure only). [1, §5.2, Fig. 5]

**Self-improvement depends on the scaffold.** [1, §4.2-4.3, Table 4]

- OpenHands: adding 868 of the 32B student's own successes to the 491 teacher trajectories dropped Lite from 15.3% to 8.7%.
- MoatlessTools, Lite: 7B went 7.0 → 9.0 → 10.0% over two iterations; 32B (LoRA) went 19.0 → 19.7 → 19.7%. The 7B empty-patch rate fell from 56.3% to 23.3%.
- Zero-shot, the fixed workflow was far ahead: 7% and 19% on Lite for 7B and 32B, against 1.0% and 3.0% in OpenHands.

**Per-task cap**, 7B on Lite (cap 1/2/3/none): 36/62/82/172 trajectories, resolve 9.0/9.7/7.7/9.3%. [1, App., Table 6]

**Verifier.** Trained on 2,636 trajectories (1,318 successes, 1,318 failures). With 16 attempts, the best-possible rate was 42.8% and the verifier-picked rate 32.0% (20.6% with one attempt). A LoRA-trained verifier beat a fully fine-tuned one at *k* = 8 (29.8 vs 27.2). [1, §5.1.1, Fig. 3]

## 4. Evidence boundaries

- **11 repositories, about a third of tasks from pandas.** [1, §3.3]
- **The self-improvement comparison crosses scaffolds, sizes and training methods.** The OpenHands result is one run on Lite; the 32B MoatlessTools model used LoRA. It is not a clean ablation of on-policy data.
- **The cap result is small.** The spread across caps is 2 points on 300 tasks, from 36-172 trajectories, with no error bars.
- **Inference allowed 100 turns and 32k context.** [1, App. B.2]
- **The smallest model is 7B**, fully fine-tuned.

## 5. What we take from it

Our interpretation, not the paper's claims.

- A few hundred verified trajectories in our format are enough to test whether the format is learnable before collecting thousands.
- Student-generated data helped only in the constrained workflow here. Our harness owns the phase machine, which is closer to MoatlessTools than to OpenHands. That favours trying on-policy data, but it must be checked against a held-out set before it is mixed in.
- Keep failed trajectories. They are not policy data, but they can train a success predictor that ranks retries or flags when to call the admin model.
- Report loop rate and empty-edit rate with every fine-tune, per phase. Fine-tuning moved both here, not always downward.

## Reference

[1] Jiayi Pan, Xingyao Wang, Graham Neubig, Navdeep Jaitly, Heng Ji, Alane Suhr, Yizhe Zhang (UC Berkeley; UIUC; CMU; Apple). *Training Software Engineering Agents and Verifiers with SWE-Gym.* arXiv:2412.21139 (v2). <https://arxiv.org/html/2412.21139>. Accessed 2026-11-11.
