# Test-Driven Development for Code Generation

- **Source:** https://arxiv.org/html/2402.13521
- **Authors / org:** Noble Saji Mathews, Meiyappan Nagappan (University of Waterloo)
- **Date:** 2024-02 (arXiv v2 dated 2024-06-11)
- **Type:** paper
- **Read:** full text

## Summary

The paper measures how much it helps to give an LLM tests together with the problem statement, and then to let it repair its code against failing tests. The pipeline (TGen) has a coder agent, a remediation agent and a PyTest-based verifier. Each problem moves through stages: attempt from the statement alone; if that fails, attempt again with the public tests included in the prompt; if that fails, enter a remediation loop of at most five iterations that stops early after three repeated failures.

Datasets are MBPP and HumanEval in their EvalPlus versions (with many extra private tests) and 1,100 CodeChef problems. Primary model GPT-4 Turbo; GPT-3.5 and Llama 3 70B as checks.

GPT-4, measured against private tests: MBPP 69.67% from the statement alone, 82.45% with tests supplied, 87.71% after remediation. HumanEval 78.66%, 87.81%, 93.30%. On CodeChef 23.00%, 26.09%, 30.27%, so about 70% of the harder problems stayed unsolved. Llama 3 70B gained more: MBPP 46.37% to 75.94% to 84.96%; HumanEval 62.20% to 75.61% to 84.15%, roughly double GPT-4's total improvement.

Further findings: more tests generally helped with no plateau on HumanEval, but some previously solved problems regressed when more tests were added, which the authors relate to long-prompt effects. Most reference solutions reached full line coverage with the first test, so variety of tests mattered more than count. Remediation shows diminishing returns after three or four iterations. The remediation agent had no access to its own earlier attempts because of context limits, which the authors list as a limitation.

## Key points

- Supplying tests up front gives the larger gain; the repair loop adds a smaller one.
- The weaker model benefited about twice as much as the stronger one.
- Returns from repair iterations flatten after three or four.
- Test quality and diversity matter more than number.
- Adding many tests to the prompt can cause regressions.
- Gains shrink sharply on harder, file-level problems.

## Relevance to JacKnife

(Our interpretation.)

- Put the task's tests (or at least their names and assertions) in the implement-state context. The evidence that weaker models gain most supports doing this for a 9B model.
- Order the states so tests exist before implementation where feasible, or generate tests from acceptance criteria in the plan state.
- Show a few diverse tests, not all of them; with a 16k budget and the regression finding, a full test file in context may hurt.
- The debug state should keep folded one-line records of earlier failed fixes so the model does not retry them; the paper's agent lacked this and the authors saw it as a weakness.
- Cap debug iterations at three to five per failing test before re-planning.
