# SWE-smith: Scaling Data for Software Engineering Agents

- **Source:** https://arxiv.org/html/2504.21798
- **Authors / org:** John Yang, Kilian Lieret, Carlos E. Jimenez, Alexander Wettig, Kabir Khandpur, Yanzhe Zhang, Binyuan Hui, Ofir Press, Ludwig Schmidt, Diyi Yang (Stanford, Princeton, Alibaba Qwen)
- **Date:** 2025-04 (arXiv v2 dated 2025-05-21)
- **Type:** paper
- **Read:** main text (first ~100k characters of the HTML; most of the appendix not read)

## Summary

SWE-smith is a pipeline for producing training tasks for coding agents at scale. It reverses the SWE-bench recipe: first build one executable environment per repository, then synthesise many bugs inside it. An agent installs each repository and runs its tests; a Docker image is built once and shared by all tasks from that repository.

Bugs come from four generators: an LLM modifies or rewrites a function; procedural AST transformations (remove a conditional, change an operator); combinations of several such patches; and "PR mirroring", where an LLM reverts a historical pull request in the current code. A candidate is kept only if it breaks at least one test that previously passed. An LLM then writes an issue-style problem statement from the patch, a failing test and its output. The result is about 50k tasks from 128 Python repositories for roughly $1,360 in LLM cost.

For training data, Claude 3.7 Sonnet was run through SWE-agent (75-step limit, $2 cap). From 17,906 attempts 6,457 resolved the task (36%). Only resolved trajectories are used, and each task contributes at most three; the final set is 5,016 trajectories. Fine-tuning Qwen2.5-Coder-32B on it gives SWE-agent-LM-32B, which resolves 40.2% of SWE-bench Verified in one attempt; a 7B variant resolves 15.2%.

Ablations: performance grows roughly with the logarithm of the number of repositories; LLM-written issue text works as well as real issues, and fixed templates are worse; task difficulty predicts solvability but not training value; fine-tuning on one repository raises results there (21.2% vs 13.6% on SymPy) at a small general cost.

Failure analysis: over 25% of the fine-tuned model's trajectories contain a repeated run of at least 10 actions, against under 4% for the teacher, and about 53% of failures end at a step or cost limit.

## Key points

- Build the environment once per repository, then generate tasks inside it; validation is by tests that flip from pass to fail.
- Training set = teacher trajectories that passed the tests, capped per task.
- About 5k trajectories were enough to take a 32B model to 40% on SWE-bench Verified.
- Repository diversity matters; realistic issue text matters; difficulty does not.
- The student repeats actions far more than its teacher; loops are the dominant failure.

## Relevance to JacKnife

(Our interpretation.)

- The same recipe can produce Jac tasks: pick Jac repositories with tests, inject bugs by AST mutation or LLM rewrite, keep those that break a passing test, and generate the task brief from the failing test. This yields debug-state training data cheaply.
- Cap trajectories per task (three here) to avoid over-representing easy tasks.
- Expect the fine-tuned 9B model to loop more than its teacher. Loop detection in the harness and loop-rate as an evaluation metric are both needed.
- The 7B result (15.2%) sets expectations for a 9B model in a free-form agent loop; the JacKnife bet is that a harness-owned workflow narrows this gap, which these authors did not test.
