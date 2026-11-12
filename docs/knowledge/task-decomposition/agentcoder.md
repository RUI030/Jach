# Writing Tests Without Seeing the Code, Then Running Them with a Script

A method note based on AgentCoder [1].

- **Evidence:** B. Controlled ablations on four function-level benchmarks; single-group preprint; many baseline numbers copied from other papers; no error bars.
- **Numbers checked against the source:** yes, 2026-11-11, against the arXiv HTML (v3). The appendix with limitations is not in the HTML and was not read.

## 1. Problem

When one model writes both the code and its tests, the tests tend to share the code's misunderstandings. The paper asks whether moving test writing to a separate agent, and running the tests with a plain script, gives better code. [1, §1, §4.7]

## 2. Method

Three components run in a loop. [1, §3]

| Component | Implemented as | Input | Output |
|---|---|---|---|
| Programmer | LLM | Problem statement, later the execution feedback | Code |
| Test designer | LLM, separate conversation | Problem statement only | Basic, edge-case and large-input tests |
| Test executor | Python script | Code and tests | Pass, or the error output sent back to the programmer |

The loop ends when all tests pass or the iteration budget runs out. [1, §3, §4.4]

### Key decisions

1. **The test designer never sees the code.** Tests are written from the requirement, so they are not biased by incorrect code. [1, §3.2]
2. **Three kinds of test are asked for**: basic behaviour, edge cases (empty input, extreme values), and large inputs for performance. [1, §3.2]
3. **Execution is not an LLM.** A script runs the code and returns pass or the error text, so the feedback is not hallucinated. [1, §3.3]
4. **The programmer reasons in four fixed steps**: understand the problem, choose an algorithm, write pseudocode, write code. [1, §3.1]

### Implementation details that generalise

- Each agent must put its answer in a fenced Python block, so the executor can extract code and tests by stripping everything else. [1, App. A.1]
- The benchmark prompts already contain two or three example tests; the executor alone can use only those. [1, §4.3]

## 3. Evidence

End-to-end pass@1. [1, Table 1]

| Backbone | HumanEval | MBPP |
|---|---|---|
| GPT-4 | 96.3% | 91.8% |
| GPT-3.5-turbo | 79.9% | 89.9% |

Ablation, backbone not stated in the table; the full-system row matches the GPT-3.5-turbo results. [1, §4.3, Table 2]

| Configuration | HumanEval | HumanEval-ET | MBPP | MBPP-ET |
|---|---|---|---|---|
| Programmer only | 61.0 | 52.4 | 47.9 | 35.0 |
| + test designer (no execution) | 64.0 | 54.3 | 62.3 | 45.9 |
| + executor (prompt tests only) | 64.6 | 55.5 | 69.3 | 51.4 |
| All three | 79.9 | 77.4 | 89.9 | 89.1 |

One agent that writes code and then tests in the same conversation [1, §4.7, Tables 6–8]:

| | HumanEval pass@1 | MBPP pass@1 | Test accuracy (HE / MBPP) | Line coverage (HE / MBPP) |
|---|---|---|---|---|
| Single agent | 71.3 | 79.4 | 61.0 / 51.8 | 72.5 / 75.9 |
| Separate agents | 79.9 | 89.9 | 87.8 / 89.9 | 87.5 / 89.5 |

- Test accuracy (share of generated tests that pass the canonical solution), GPT-4: 89.6% HumanEval and 91.4% MBPP, against 79.3% and 84.4% for MetaGPT. [1, §4.5, Table 4]
- Pass@1 by refinement iteration, GPT-3.5-turbo, HumanEval: 74.4, 75.6, 76.2, 78.7, 79.9 for iterations 1 to 5. MBPP: 84.1 to 89.9. Only five iterations were tested. [1, §4.4, Table 3]
- Response tokens with GPT-4: 56.9K (HumanEval) and 66.3K (MBPP), against 138.2K and 206.5K for MetaGPT. [1, App. A.2, Table 9]

## 4. Evidence boundaries

- **Single functions only.** HumanEval and MBPP are short, self-contained Python problems. Nothing about multi-file or repository work is tested.
- **Only API models.** GPT-4, GPT-4-turbo, GPT-3.5-turbo, PaLM Coder and Claude-instant-1 were used [1, §4.1]. No small or fine-tuned open model appears.
- **Baselines are not rerun.** Table 1 baseline results are taken from the cited papers [1, Table 1 caption], so prompts and settings differ across rows.
- **About one generated test in ten is wrong** with GPT-4 [1, Table 4]. The paper does not measure how often a wrong test misleads the programmer.
- **No error bars or repeated runs** are reported.
- **The iteration curve has not flattened.** Pass@1 still rose 1.2 points between iterations 4 and 5 [1, Table 3], so the paper does not show where returns stop.

## 5. What we take from it

Our interpretation, not the paper's claims.

- In the unit-test phase, the model should see the task's acceptance criteria and interface, not the implementation body. The harness can enforce this through what it puts in context.
- Test execution and result parsing belong to the harness; the model should see only a compact failure report.
- Because some generated tests will be wrong, the debug phase needs a way to question a test, for example by showing the criterion next to the failing test after repeated failed fixes.
- The size of the single-agent gap (8.6 and 10.5 points) was measured on GPT-3.5-class models; whether it holds for a 9B model has to be measured in our harness.

## Reference

[1] Dong Huang, Jie M. Zhang, Michael Luck, Qingwen Bu, Yuhao Qing, Heming Cui. *AgentCoder: Multi-Agent Code Generation with Effective Testing and Self-optimisation.* arXiv:2312.13010v3, 24 May 2024. <https://arxiv.org/html/2312.13010>. Accessed 2026-11-11.
