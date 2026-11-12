# Revisiting DAgger in the Era of LLM-Agents

- **Source:** https://arxiv.org/html/2605.12913v1
- **Authors / org:** Changhao Li, Rushi Qiang, Jiawei Huang, Chenxiao Gao, Chao Zhang, Niao He, Bo Dai (Georgia Institute of Technology; ETH Zurich)
- **Date:** 13 May 2026
- **Type:** paper
- **Read:** first ~100k characters of the HTML (main text and most appendices; the final ~6k characters were not read)

## Summary

The paper tests DAgger-style training for small coding agents: Qwen3-4B and Qwen3-8B students, a Qwen3-Coder-30B teacher, the OpenHands scaffold, SWE-Gym for training (2,338 tasks) and SWE-bench Verified for evaluation (466 tasks).

In the main method each turn of a rollout is executed by the teacher with probability beta and by the student otherwise. Beta starts at 1.0 and decays by 0.2 per iteration to a floor of 0.6. Whoever acts, the teacher is queried at every visited state and its action is the training label, so the student gets teacher labels on states that its own actions produced. Only teacher actions are needed, not logits. Training runs five collect-then-update iterations of 512 tasks each. A second variant has the student run a prefix of random length (0 to 40 turns) and the teacher finish.

Results on SWE-bench Verified, 4B / 8B: base model 11.2% / 7.7%; reinforcement learning (GRPO) 11.6% / 8.2%; supervised fine-tuning on successful teacher trajectories 22.9% / 23.4%; on-policy distillation 23.4% / 26.2%; DAgger-style 27.3% / 29.8%; prefix-then-teacher variant 24.5% / 27.3%. The paper notes its 8B result exceeds a published 32B agent trained on SWE-Gym (20.6%), though data and scaffold differ.

Supervised fine-tuning peaked and then declined as data grew, and its divergence from the teacher on student-visited states rose again, while both mixed-rollout methods stayed lower. In the failure analysis, 44.3% of the no-submission failures of on-policy distillation were repetitive loops. The DAgger-style agent submitted a patch on 97.9% of tasks; its remaining no-submission failures were mostly context overflow (57.5%).

No seeds or variance are reported, and the beta schedule is not ablated.

## Key points

- At 4B-8B, DAgger-style training beat plain fine-tuning on teacher trajectories by about 4-6 points.
- Labels are teacher actions on every visited state, including states reached by student actions.
- Mostly-teacher rollouts (beta 1.0 down to 0.6) were enough; fully student-driven collection was worse and loop-prone.
- Reinforcement learning from the base model barely moved the result at this scale.
- A black-box teacher suffices.
- After training, loops were no longer the main failure; context overflow was.

## Relevance to JacKnife

(Our interpretation, not the source's claims.)

- This is the closest published setup to ours (Qwen-family, 8B, coding agent, strong-model teacher) and it supports treating admin interventions as the main source of training data.
- Their design labels every visited state with the teacher's action. JacKnife's admin acts only when called. A cheap offline approximation: replay logged small-model states through the admin after the fact to collect labels without the admin having driven the run.
- Interleaved control (teacher takes some turns, student others) corresponds to an admin that fixes one step and hands back, rather than finishing the task. That mode yields more student-visited states per run.
- Plan for iteration: collect, fine-tune, redeploy, collect again. One round on a fixed dataset is the weaker baseline here.
- Context overflow becoming the top failure suggests context management is the next bottleneck once loops are reduced.
