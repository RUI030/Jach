# SWE-smith: Scaling Data for Software Engineering Agents

- **Source:** https://arxiv.org/html/2504.21798
- **Authors / org:** John Yang, Kilian Lieret, Carlos E. Jimenez, Alexander Wettig, Kabir Khandpur, Yanzhe Zhang, Binyuan Hui, Ofir Press, Ludwig Schmidt, Diyi Yang
- **Date:** April 2025 (v2 dated 21 May 2025)
- **Type:** paper
- **Read:** main text and appendices A, B and F (appendices C-E were only partly covered; several ablation values exist only in figures)

## Summary

SWE-smith is a pipeline for producing training tasks for coding agents at scale, and a study of fine-tuning open models on agent trajectories. It builds an execution environment per repository, then synthesises bugs that break existing passing tests, using LLM rewrites, procedural AST changes, combinations of patches, and reverted pull requests. The result is about 50k tasks from 128 Python repositories.

Claude 3.7 Sonnet solved a subset inside the SWE-agent scaffold; only trajectories that resolved the task were kept, at most three per task, giving about 5,000. Qwen2.5-Coder 32B and 7B were fully fine-tuned on these (learning rate 5e-5, up to 3 epochs, 32k context, history truncated to the five latest tool outputs). The 32B model reached 40.2% on SWE-bench Verified; the 7B model 15.2%. With only 500 trajectories the 32B model already reached 28.2%.

Data findings: keeping only resolved trajectories beat random sampling at every size tested. Performance grew roughly logarithmically with the number of repositories at fixed trajectory count. Task difficulty showed no clear relation to downstream performance. Fixed-template issue texts reduced the variety of actions in the data by about 31% and lowered results. On a multilingual benchmark the fine-tuned model barely beat its base (8.4% against 6.5%).

Behaviour findings: the fine-tuned 32B model repeated itself far more than its teacher. Over 25% of its trajectories contained a repeated sequence of 10 or more steps, against under 4% for Claude; such a sequence predicted failure 89% of the time, and about 73% of the longest repeats were file-view calls. About 53% of its failures were runs that hit step or cost limits. The authors tried scaffold fixes (warnings after 4 to 6 repeats, resampling the action up to 10 times, injected messages, higher temperature). Repetition fell but the resolve rate did not improve, and they suggest repetition may be a symptom of difficulty.

## Key points

- About 5k successful teacher trajectories took a 32B model to roughly 40% on SWE-bench Verified; the same recipe gave 15% at 7B.
- Filter to successful trajectories; diversify repositories and issue wording.
- A fine-tuned student loops much more than its teacher (25% against 4% of trajectories).
- Warnings, resampling and temperature changes reduced loops but not failures.
- Gains did not transfer across programming languages.
- Repository-specific fine-tuning helped on that repository (21.2% against 13.6% on SymPy).

## Relevance to JacKnife

(Our interpretation, not the source's claims.)

- The loop behaviour of our model is the expected result of cloning successful teacher trajectories, and it gets worse as the model gets smaller. It should be addressed in the data (see `escalation/`) as well as in the harness.
- Nudges and resampling alone should not be expected to raise our success rate; pair loop-breaking with added information or an admin step.
- The weak cross-language transfer means Python agent data will not make a good Jac agent; Jac trajectories are needed.
- For data collection, variety of Jac projects and task wording is likely worth more than volume from a few projects; at 32B, 500 trajectories already reached 28.2% against 40.2% with about 5,000.
- Truncating history to the latest five tool outputs was part of their training and inference setup; whatever context policy JacKnife uses must be the same in training data and at run time.
