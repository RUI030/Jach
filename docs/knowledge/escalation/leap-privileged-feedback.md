# Offline Correction by a Teacher with Privileged Information (LEAP)

A method note based on the LEAP paper [1].

- **Evidence:** B. Controlled comparisons and ablations on three benchmarks; single-group preprint, no variance reported.
- **Numbers checked against the source:** yes, 2026-11-11, against the arXiv HTML (v1).

## 1. Problem

A teacher that corrects a student's trajectory step by step is solving a harder problem than the task itself, because it must reason under the same partial observability. Its feedback is then often poor. Giving the teacher information the student will not have at test time makes correction easier, but corrections that rely on that information may be impossible for the student to imitate. [1, §1, §3.1]

## 2. Method

LEAP is an iterative DAgger-style loop. [1, §3.2, Algorithm 1]

1. Train a behaviour-cloning policy π₀ on teacher demonstrations.
2. Roll out the current student. On trajectories where it fails, give the teacher the student's history and its stated reason and action at each step, plus a privileged state.
3. The teacher writes a corrected reason and action for each step. It does not act in the environment.
4. Add the corrections to the dataset and retrain (SFT on the aggregate, or a preference update).
5. Return the best iteration on validation.

Privileged state per domain: object locations, essential objects and optimal actions (ALFWorld); target product attributes, options, price and an example matching product (WebShop); the ground-truth command (InterCode Bash). [1, §3.1, §4.2-4.4]

### Key decisions

1. **The teacher must not reveal privileged facts.** It is prompted to give reasons and actions the student could have reached from what it observed. [1, §3.1]
2. **Correct offline, after the fact.** Collection and correction are separate steps; the teacher never drives a live run.
3. **Correct reasons as well as actions**, so the student learns why, in its own ReAct format.

### Implementation details that generalise

- How much privileged information the teacher may use is a tuning knob with an optimum. Five teacher prompts with increasing permission were compared; success rose up to the middle setting, then fell sharply, and the most permissive teacher produced a worse student than the least permissive one. [1, §4.5, Fig. 5]
- Plain SFT on corrections beat preference optimisation. In-distribution ALFWorld after one iteration from π₀ at 68.6%: SFT 96.4%, KTO 87.1%, DPO 74.3%. [1, §1, §4.7, Table 3]
- Gains were not monotonic across iterations, so pick the iteration on validation. [1, §4.2]

## 3. Evidence

Students: Llama3-8B with LoRA (all domains) and Llama-3.1-70B (InterCode). Teacher: GPT-4o. Four iterations on ALFWorld and WebShop, two on InterCode. [1, §4.2-4.4]

| Benchmark | Student π₀ | Best LEAP student | GPT-4o as ReAct agent |
|---|---|---|---|
| ALFWorld, out-of-distribution success | 65.7% | 91.0% (π₁), 83.6% (π₂), 91.8% (π₃) | 65.7% |
| WebShop score | 29.4 | 51.8 (π₁), 61.8 (π₂) | 58.4 |
| InterCode Bash, 8B student | 41.4% | 49.9% (π₁) | 71.3% |
| InterCode Bash, 70B student | 60.3% | 71.8% (π₁) | 71.3% |

[1, §4.2, Table 1; §4.3, Fig. 3; §4.4, Table 2]

- Most of the gain came in iteration 1 on ALFWorld and WebShop. [1, §4.2, §4.3]
- Using Llama3-8B as its own privileged teacher on ALFWorld gave 65.7% → 82.1% → 91.8% over two iterations. The authors conclude the privileged state "does the heavy lifting" there, and say this need not hold elsewhere. [1, §4.6, Fig. 6]
- On InterCode the 8B student improved but stayed far below GPT-4o. The authors note that when the teacher is already strong, the student may not surpass it. [1, §4.4]

## 4. Evidence boundaries

- No seeds or confidence intervals. The ALFWorld OOD set is about 134 games, so a 1-point difference is 1 to 2 games.
- The paper is internally inconsistent in places: the ALFWorld test sizes are 134/139 in the text and 136/140 in the Table 1 caption; the best WebShop score is given as both 61.4 and 61.8. [1, §4.2, §4.3]
- The coding task is short Bash commands with a ground-truth answer, capped at 10 actions. Multi-file code changes are not tested.
- "Better than the teacher" compares against the teacher without privileged information. On the code-like task the 8B student did not get there.
- The authors list long rollouts and verbose teacher feedback as limitations. [1, §6]

## 5. What we take from it

Our interpretation, not the paper's claims.

- In our harness privileged information exists after the fact: the eventually accepted solution, the checker output, the passing test. The admin can relabel failed small-model trajectories offline with it, separate from live rescue.
- The realisability rule applies to admin prompts: a correction should cite what the small model could see (file contents, checker message), not the final answer. Otherwise it teaches nothing it can reuse.
- The self-teacher result suggests a cheap experiment: the 9B model, shown the accepted solution, relabels its own failed steps. Whether it helps on Jac code, where our model cannot write the fix, is open; the InterCode 8B result warns against expecting much.
- Keep a validation set and select the iteration; do not assume later rounds are better.

## Reference

[1] Sanjiban Choudhury (Cornell University), Paloma Sodhi (ASAPP Research). *Better than Your Teacher: LLM Agents that Learn from Privileged AI Feedback.* arXiv:2410.05434v1, October 2024. <https://arxiv.org/html/2410.05434>. Accessed 2026-11-11.
