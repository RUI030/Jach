# AgentCoder: Multi-Agent Code Generation with Effective Testing and Self-optimisation

- **Source:** https://arxiv.org/html/2312.13010
- **Authors / org:** Dong Huang, Jie M. Zhang, Michael Luck, Qingwen Bu, Yuhao Qing, Heming Cui
- **Date:** 2023-12 (arXiv v3 dated 2024-05-24)
- **Type:** paper
- **Read:** main text (appendix with limitations not included in the fetched text)

## Summary

AgentCoder uses three components in a loop. The programmer agent (an LLM) writes code through a four-step chain of thought: understand the problem, choose an algorithm, write pseudocode, write code. The test designer agent (an LLM in a separate conversation) writes basic, edge-case and large-input tests from the problem statement only; it never sees the implementation. The test executor is a plain Python script that runs the code against the tests and returns error output to the programmer, repeating until tests pass or the iteration budget ends.

The reason for separating test writing from code writing is that tests produced in the same conversation as the code tend to inherit the code's misunderstandings and are less diverse.

On function-level benchmarks with GPT-4, pass@1 is 96.3% on HumanEval and 91.8% on MBPP; with GPT-3.5-turbo, 79.9% and 89.9%. Many baseline numbers are copied from other papers. The reported token overhead with GPT-4 is 56.9K (HumanEval) and 66.3K (MBPP), against 138.2K and 206.5K for MetaGPT. Generated tests agree with canonical solutions 89.6% and 91.4% of the time with GPT-4, against 79.3% and 84.4% for MetaGPT; line coverage is about 92%.

Ablation with GPT-3.5 on HumanEval/MBPP: programmer alone 61.0%/47.9%; adding the test designer 64.0%/62.3%; adding only the executor 64.6%/69.3%; all three 79.9%/89.9%. A single agent that writes both code and tests reaches 71.3%/79.4%, below the separated setup. Pass@1 rises from 74.4% after one iteration to 79.9% after five on HumanEval.

Note that roughly one in ten generated tests is wrong against the reference solution; the paper does not analyse how often a wrong test misleads the programmer.

## Key points

- Tests are written without seeing the code, in a separate context.
- Test execution is a script, not an LLM.
- Separation of test and code authorship is worth about 8-10 points over one agent doing both, in their ablation.
- Most of the gain appears in the first few fix iterations.
- Generated tests are imperfect (about 90% correct with GPT-4).
- Benchmarks are single-function problems, not repositories.

## Relevance to JacKnife

(Our interpretation.)

- In the unit-test state, give the model the task's acceptance criteria and interface but fold or withhold the implementation body, so tests come from the spec. This is a context-selection rule the harness can enforce.
- Test running and result parsing belong to the harness; the model only sees a compact failure report.
- Because some generated tests will be wrong, the debug state needs a way to question a test, for example after N failed fixes the harness shows the criterion and the test together and asks which is wrong.
- Cap fix iterations at a small number (gains flatten by about five) and escalate or re-plan after that.
