# Better than Your Teacher: LLM Agents that Learn from Privileged AI Feedback (LEAP)

- **Source:** https://arxiv.org/html/2410.05434
- **Authors / org:** Sanjiban Choudhury (Cornell University), Paloma Sodhi (ASAPP Research)
- **Date:** 7 October 2024
- **Type:** paper
- **Read:** first ~100k characters of the HTML (main text; the final ~47k characters of appendices were not read)

## Summary

LEAP is an iterative DAgger-style loop for LLM agents with one addition: the teacher is given privileged information that the student will not have at test time. In ALFWorld this is object locations and an optimal action sequence; in WebShop the target product attributes; in InterCode Bash the ground-truth command. The teacher does not act in the environment. It reads the student's trajectory, including the student's stated reason and action at each step, and writes a corrected reason and action. The corrections are added to the dataset and the student is retrained, for two to four rounds.

A central design issue is realizability. If the teacher's corrections rely on information the student cannot observe, the student cannot learn to imitate them. The teacher is therefore instructed not to reveal privileged facts and to give corrections the student could have reached from what it saw. An expert that leaned too heavily on privileged information produced much worse students than a moderate one.

Students are Llama3-8B with LoRA (and Llama-3.1-70B for Bash); the teacher is GPT-4o. On ALFWorld out-of-distribution tasks the student went from 65.7% (behaviour cloning) to 91.0% after one round and 91.8% after three, against 65.7% for GPT-4o acting as a ReAct agent without privileged state. On WebShop the score rose from 29.4 to 61.8, above GPT-4o's 58.4. On InterCode Bash the 8B student rose from 41.4% to 49.9%, still below GPT-4o's 71.3%. Using the 8B model as its own privileged teacher also worked on ALFWorld (65.7% to 91.8%). Plain supervised fine-tuning on corrections beat preference-based updates (96.4% against 87.1% for KTO and 74.3% for DPO, in-distribution).

Improvement was not monotonic across rounds, so the authors select the best round on validation data.

## Key points

- The teacher corrects the student's own trajectories offline rather than acting itself.
- Privileged information makes a teacher better than its unassisted self, so students can exceed the unassisted teacher.
- Corrections must be reachable from the student's observations.
- Most of the gain came in the first round.
- Supervised fine-tuning on corrections outperformed DPO and KTO.
- On the code-like task (Bash), the 8B student improved but stayed well below the teacher.

## Relevance to JacKnife

(Our interpretation, not the source's claims.)

- In a harness with acceptance criteria, privileged information is available for free after the fact: the eventually accepted solution, or the checker's verdict. The admin can relabel failed small-model trajectories offline with that knowledge, without running live.
- Offline correction is cheaper than live takeover and can be batched, which separates data collection from rescue.
- The realizability rule applies to admin prompts: corrections should cite only what the small model could see (the file content, the checker message), not knowledge of the final answer.
- The self-teacher result suggests a low-cost experiment: the 9B model, shown the accepted solution, relabels its own failed steps.
- Keep a validation set and select checkpoints per round; do not assume later rounds are better.
