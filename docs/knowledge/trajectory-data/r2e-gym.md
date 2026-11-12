# Mining Coding Tasks From Commits, and Training on Thoughts as Well as Actions

A method note based on R2E-Gym [1].

- **Evidence:** B. Controlled ablations with public data; preprint; Python repositories, one teacher, one minimal scaffold.
- **Numbers checked against the source:** yes, 2026-11-11, against the arXiv HTML.

## 1. Problem

Executable training tasks are usually built from human-written issues and their tests, which limits how many can be made. The paper builds tasks from ordinary commits instead, and asks how far supervised fine-tuning on such tasks takes a small model, and how to choose among several attempts at test time. [1, §1, §2]

## 2. Method

**Task construction ("SweGen").** [1, §2]

1. Select Python repositories with many commits; filter commits with rules and an LLM for interesting code changes.
2. Use the commit's own fail-to-pass tests where they exist; otherwise generate them.
3. Back-translate a problem statement from the commit with an LLM, giving it the failing tests and their execution output so the statement is specific.

This yields 8,135 tasks; 4,578 from repositories that do not overlap SWE-bench are used for training. [1, §2, Table 1]

**Training.** Claude 3.5 Sonnet (v2) runs in a minimal ReAct scaffold with four tools: file editor, search, bash and submit. Only successful runs are kept: 3,321 trajectories from 2,048 tasks. Qwen2.5-Coder 7B, 14B and 32B are fully fine-tuned on thoughts and actions. [1, §3; App. B]

**Test-time selection.** Up to 26 attempts per task are ranked by an execution-based verifier (agent-written reproduction tests plus regression tests), an execution-free verifier (a model that reads the trajectory), or a hybrid of the two. [1, §4]

### Key decisions

1. **Problem statements written with the failing test in view.** The authors found naive back-translation from the diff alone gave generic statements. [1, §2]
2. **Thoughts are training targets.** [1, §3.1]
3. **No specialised workflow.** The agent writes its own reproduction script, localises, fixes and tests. [1, App. B]

### Implementation details that generalise

- Teacher runs were capped at 40 steps and 32k tokens, with a 90-second timeout per action. [1, App. B]
- The training context was 20k tokens. [1, App. B]
- The execution-free verifier works better with the whole trajectory than with the patch alone. That is also its weakness (see §4). [1, §4.2, Fig. 7]

## 3. Evidence

SWE-bench Verified pass@1, mean ± as given. [1, §3.1, Table 3]

| Size | Base | Trained on SWE-Gym (491) | Trained on R2E-Gym (3,321) |
|---|---|---|---|
| 7B | 1.8 (±1.3) | 10.6 (±2.1) | 19.0 (±1.0) |
| 14B | 4.0 (±1.6) | 16.4 (±2.0) | 26.8 (±1.4) |
| 32B | 7.0 (±1.3) | 20.6 (±2.1) | 34.4 (±1.2) |

- **Thoughts:** 34.4% with thoughts in the targets, 30.4% without. [1, §3.1, Fig. 3] The text also gives 34.2 for the same comparison.
- **Synthetic vs real issues**, 400 trajectories each: 27.8% vs 28.0%. [1, §3.1, Fig. 3]
- **Data scaling**, 100 to 3,200 trajectories: diminishing returns for both sizes tested; the 14B model "begins to saturate" near 800, while 32B keeps improving. Values are only in a figure. [1, §3.1, Fig. 2]
- **Verifiers**, best-of-26 on Verified: execution-based and execution-free each plateau near 43.7% and 42.8%; the hybrid reaches 51.0%. The best possible (pass@26) is 64.4%. [1, §4.2-4.3]
- For most tasks, fewer than 20% of generated tests separate correct from incorrect patches. For a small subset, up to 10% of tests are "toxic": they pass wrong patches and fail right ones. [1, §4.2, Fig. 5]
- With patch only, the execution-free verifier fell from 42.8% to 37.6%. Attention analysis shows it weighting the agent's own upbeat summary ("Great! The fix works"). [1, §4.2, Fig. 7]

## 4. Evidence boundaries

- **Smallest model is 7B, and the scaling curve covers only 14B and 32B.** There is no saturation measurement at 7B or near 9B.
- **The 7B and 14B gains over SWE-Gym mix two changes:** about seven times more trajectories and a different scaffold.
- **The thoughts ablation is one comparison** with no error bar given; the model size is not stated in the text read.
- **Teacher and tasks are Python-only**, from 10 repositories in the training subset.
- **The 51% figure needs 26 attempts plus test generation.** It is not comparable to single-attempt results.

## 5. What we take from it

Our interpretation, not the paper's claims.

- Keep the model's reasoning in the training targets, short enough to fit our context budget.
- Mining Jac commits and back-translating task briefs from the failing test is a second route to tasks, alongside bug injection.
- How many trajectories a 9B model can absorb is not settled by this paper. The 14B plateau near 800 is one data point in one scaffold. We need our own data-size ablation.
- A verifier that reads the trajectory can be fooled by the model saying it succeeded. Our harness's "done" checks are run by the harness and cannot be influenced by the model, and that should stay so. Model-written tests should never be the only acceptance gate.

## Reference

[1] Naman Jain, Jaskirat Singh, Manish Shetty, Liang Zheng, Koushik Sen, Ion Stoica (UC Berkeley; ANU). *R2E-Gym: Procedural Environments and Hybrid Verifiers for Scaling Open-Weights SWE Agents.* arXiv:2504.07164. <https://arxiv.org/html/2504.07164>. Project: <https://r2e-gym.github.io>. Accessed 2026-11-11.
