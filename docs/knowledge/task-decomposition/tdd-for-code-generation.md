# Supplying Tests Before Generation, Then Repairing Against Failures

A method note based on "Test-Driven Development for Code Generation" [1].

- **Evidence:** B. Controlled staged pipeline on three datasets with a replication package; preprint; one run per setting (seed fixed, temperature 0); no error bars.
- **Numbers checked against the source:** yes, 2026-11-11, against the arXiv HTML (v2).

## 1. Problem

In test-driven development, tests come first and act as the specification. The paper asks whether putting human-written tests in the prompt helps LLM code generation, whether a repair loop driven by failing tests adds more, and how difficulty, test count and model change the answer. [1, §2]

## 2. Method

The pipeline (TGen) has a coder agent, a remediation agent that reads verifier failures and proposes fixes, and a PyTest verifier. Each problem moves through stages and stops at the first that succeeds. [1, §3.2]

1. Generate from the problem statement alone.
2. If that fails, generate again with all public tests in the prompt.
3. If that fails, run the remediation loop.
4. Otherwise mark the problem unsolved.

Correctness is then re-checked against private tests the model never saw: EvalPlus' extended suites for HumanEval (164 problems) and MBPP (399), and CodeChef's own judge for 1,100 file-level problems. [1, §3.1, §4.4]

### Key decisions

1. **Tests are part of the input, not only the check.** The model sees the public tests while writing code. [1, §3.2]
2. **The repair loop is bounded two ways**: at most five iterations, and an early stop after three repeated failures of the same tests. [1, §3.2]
3. **Repair advice comes from a separate agent** that reads stack traces and failing tests and writes advice for the coder. [1, §3.2]
4. **Success is judged on unseen tests**, so a solution that only fits the supplied tests is caught. [1, §4.4]

### Implementation details that generalise

- The remediation agent saw no history of its earlier attempts, to save context. The authors report that advice sometimes misled the coder and errors repeated. [1, §4.3]
- The first repair round usually fixed obvious faults (missing imports, type conversions); the second addressed deeper logic and edge cases. [1, §4.3]

## 3. Evidence

GPT-4 Turbo (1106), share solved on private tests, cumulative by stage. [1, §4.4, Table 1]

| Stage | MBPP (399) | HumanEval (164) | CodeChef (1,100) |
|---|---|---|---|
| Statement only | 69.67% | 78.66% | 23.00% |
| + tests in prompt | 82.45% (+12.78) | 87.81% (+9.15) | 26.09% (+3.09) |
| + remediation | 87.71% (+5.26) | 93.30% (+5.49) | 30.27% (+4.18) |
| Unsolved | 12.28% | 6.71% | 69.73% |

Llama 3 70B Instruct, same pipeline. [1, §5.3, Table 3]

| Stage | MBPP | HumanEval |
|---|---|---|
| Statement only | 46.37% | 62.20% |
| + tests in prompt | 75.94% (+29.57) | 75.61% (+13.41) |
| + remediation | 84.96% (+9.02) | 84.15% (+8.54) |

- Total improvement for Llama 3 was 38.60 points on MBPP and 21.95 on HumanEval, against 18.04 and 14.64 for GPT-4. [1, Tables 1, 3]
- Remediation by attempt, GPT-4 on public tests: on MBPP, 21 extra problems were solved, 11 on the first attempt, seven on the second, two on the third and one on the fourth. On HumanEval, nine, of which seven came on the first attempt. None were solved on the fifth. [1, §4.3]
- On CodeChef, public-test results were 35.72% from the statement, 7.72 points more with tests, and 9.36 more with remediation; remediation helped more than tests here, mainly on medium-difficulty problems. [1, §5.1.2]
- More tests in the prompt gave an upward trend, but some problems solved with fewer tests failed with more. With the first test alone, 75% of HumanEval and 92.4% of MBPP reference solutions already reached full line coverage. [1, §5.2, Fig. 7]

## 4. Evidence boundaries

- **The stages are cumulative, not separate ablations.** Remediation was only tried on problems that failed with tests, so the two gains cannot be compared as independent effects.
- **"Tests help more than repair" holds only for function-level problems.** On CodeChef, repair added more than tests did. [1, Table 1, §5.1.2]
- **The smallest model is 70B.** GPT-3.5 Turbo was run, and the authors say only that it showed similar trends; its numbers are not given. [1, §5.3]
- **Tests are human-written and correct.** The setting does not cover tests written by the model itself.
- **Single functions or single files.** No multi-file project was tested. [1, §7]

## 5. What we take from it

Our interpretation, not the paper's claims.

- Putting a task's tests, or at least their assertions, into the implement-phase context is cheap and was most helpful for the weaker model. That supports doing it for a 9B model, though it has not been measured there.
- A few diverse tests are likely better than the full test file, given the regressions seen with more tests and a tight context budget.
- The debug phase should keep a folded one-line record of earlier failed fixes. The paper's repair agent had none, and the authors saw repeated errors.
- A repair cap of three to five attempts matches where gains ran out here; past that, the harness should change approach (re-plan or escalate) instead of retrying.

## Reference

[1] Noble Saji Mathews, Meiyappan Nagappan (University of Waterloo). *Test-Driven Development for Code Generation.* arXiv:2402.13521v2, 11 Jun 2024. <https://arxiv.org/html/2402.13521>. Accessed 2026-11-11.
