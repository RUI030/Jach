# Reflexion: Language Agents with Verbal Reinforcement Learning

- **Source:** https://arxiv.org/html/2303.11366v4
- **Authors / org:** Noah Shinn, Federico Cassano, Edward Berman, Ashwin Gopinath, Karthik Narasimhan, Shunyu Yao
- **Date:** submitted 20 March 2023 (v4 revised 10 October 2023)
- **Type:** paper
- **Read:** full text (HTML v4, including appendix results)

## Summary

Reflexion improves an agent across repeated attempts at the same task without changing weights. Three roles are involved: an Actor that produces the trajectory, an Evaluator that scores it (exact match, hand-written heuristics, or self-generated unit tests for code), and a Self-Reflection model that turns the failed trajectory and the sparse score into a short written lesson. The lesson is stored in an episodic memory capped at one to three entries and prepended to the next attempt.

In the AlfWorld household environment the trigger for ending a trial and reflecting is a harness heuristic: the same action giving the same observation more than three times in a row, or more than 30 actions. With reflection the agent completed 130 of 134 tasks over 12 trials, while the ReAct baseline plateaued. On HumanEval (Python) Reflexion with GPT-4 reached 91.0% pass@1 against 80.1% for plain GPT-4, and 15.0% against 7.5% on a hard LeetCode set.

The negative results matter as much. On MBPP, Reflexion scored below plain GPT-4 (77.1% vs 80.1%) because self-written tests were wrong: the false-positive rate was 16.3% on MBPP against 1.4% on HumanEval. On WebShop there was no improvement after four trials and the reflections were unhelpful. With a weak open model (starchat-beta) on HumanEval the gain was zero (0.26 to 0.26); the authors suggest that self-correction is an emergent property of stronger models. An ablation on hard Rust problems showed that test feedback without the reflection step gave no gain over the baseline (0.60), while the full method reached 0.68.

## Key points

- Reflection is between attempts, not within one: detect the stall, stop, write a lesson, restart with the lesson in context.
- Loop detection (same action and observation more than 3 times) is the trigger, done by the harness.
- Memory is small on purpose: the last 1 to 3 reflections.
- Gains depend on evaluator quality; wrong self-generated tests made results worse than no reflection.
- A weak model gained nothing from self-reflection.

## Relevance to JacKnife

(Our interpretation, not the source's claims.)

- The starchat-beta result suggests our 9B model should not be asked to write its own reflection. The reflection is a good job for the admin model: read the failed attempt, write a 2-3 sentence lesson, restart the task with it.
- Restart-with-lesson is a cheaper admin intervention than having the large model take over the task, and it yields (state, lesson) pairs that could later be training data.
- The evaluator must be trustworthy. JacKnife's acceptance criteria and the Jac checker should come from the harness, not from model-written tests.
- Cap the number of stored lessons per task; unbounded lesson history is not what the paper tested.
