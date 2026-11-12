# R2E-Gym: Procedural Environments and Hybrid Verifiers for Scaling Open-Weights SWE Agents

- **Source:** https://arxiv.org/html/2504.07164
- **Authors / org:** Naman Jain, Jaskirat Singh, Manish Shetty, Liang Zheng, Koushik Sen, Ion Stoica (UC Berkeley, Australian National University)
- **Date:** 2025-04-09
- **Type:** paper
- **Read:** main text (first ~100k characters of the HTML; later appendices not read)

## Summary

R2E-Gym builds executable training tasks from repository commits instead of from human-written issues. Commits are filtered by rules and an LLM to favour small, non-documentation code changes. Tests that fail before and pass after the commit are taken from the repository when they exist; otherwise an LLM writes reproduction tests with the true patch as context. The problem statement is "back-translated" by an LLM from the commit, with the failing tests in the prompt to make it precise. The full set has 8,135 tasks; 4,578 with no repository overlap with SWE-bench are used for training.

Teacher trajectories come from Claude 3.5 Sonnet in a minimal ReAct scaffold with four tools: file editor, search, bash, submit. Only successful runs are kept: 3,321 trajectories from 2,048 environments. Qwen2.5-Coder at 7B, 14B and 32B is fine-tuned with full supervised fine-tuning on both thoughts and actions, with a 20K-token training context.

SWE-bench Verified pass@1: 34.4% (32B), 26.8% (14B), 19.0% (7B). Ablations: training with the teacher's thoughts gives 34.4% versus 30.4% without them. Synthetic issue text performs the same as real issues (27.8% vs 28.0% at 400 trajectories each). Scaling from 100 to 3,200 trajectories shows diminishing returns: the 14B model saturates near 800 trajectories while the 32B model keeps improving.

For test-time selection among multiple attempts, an execution-based verifier (agent-written reproduction tests plus regression tests) plateaus near 43.7%, an execution-free verifier (a fine-tuned 14B model judging the trajectory) near 42.8%, and a hybrid reaches 51.0% with 26 attempts. Weaknesses reported: most generated tests do not separate correct from incorrect patches, some are "toxic" (pass wrong patches, fail right ones), and the execution-free verifier leans on stylistic cues in the agent's thoughts.

## Key points

- Tasks can be mined from commits with LLM-written tests and issue text; synthetic issues train as well as real ones.
- Keeping the teacher's reasoning in the training targets is worth about 4 points.
- Smaller models saturate earlier with more data (14B near 800 trajectories).
- A minimal four-tool scaffold was sufficient for strong results.
- Generated tests are often weak discriminators and sometimes misleading.

## Relevance to JacKnife

(Our interpretation.)

- Train on thoughts plus actions, not actions alone. For a 16k budget the thoughts should be short, but they should be present in targets.
- A 9B model probably saturates on trajectory count early (the 14B model did near 800), so after the first thousand or so, effort is better spent on coverage of states, error types and Jac features than on volume.
- Their 20K training context is close to JacKnife's 16k: evidence that useful coding-agent behaviour can be learned inside a short window when the scaffold is minimal.
- Commit mining plus back-translated task briefs is a second route to Jac tasks alongside bug injection.
- Model-written tests cannot be the only acceptance gate; keep some criteria that the harness or a human fixes in advance.
