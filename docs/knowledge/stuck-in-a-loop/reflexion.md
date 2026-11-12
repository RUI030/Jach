# Stop, Write a Lesson, Retry: Verbal Reflection between Attempts

A method note based on Reflexion [1].

- **Evidence:** A. Controlled comparisons with public code, peer-reviewed (NeurIPS 2023; venue from general knowledge, not confirmed in the source text). Most results are single runs on closed OpenAI models without error bars, and the loop trigger itself is not ablated.
- **Numbers checked against the source:** yes, 2026-11-11, against the arXiv HTML (v4).

## 1. Problem

An agent that fails a task, or gets stuck partway, usually retries with no memory of why the earlier attempt failed. Fine-tuning on the failure is expensive. Can a model improve across attempts at the same task by writing down what went wrong and reading it before the next attempt?

## 2. Method

Three roles share one loop [1, §3]:

- the **Actor** produces a trajectory;
- the **Evaluator** scores it with exact match, a hand-written heuristic, or self-generated unit tests for code;
- the **Self-Reflection** model turns the failed trajectory and score into a short written lesson.

Lessons go into an episodic memory that is prepended to the next attempt. The memory is bounded: the last 3 reflections for ALFWorld and HotpotQA, and 1 for programming [1, §4.1, §4.2, §4.3].

### Key decisions

1. **Reflect between attempts, not within one.** The attempt ends, the environment resets, and a new trial starts with the lesson in context [1, §3].
2. **A harness rule ends a stuck attempt.** In ALFWorld, reflection is triggered when the agent repeats the same action and gets the same response for more than 3 cycles, or takes more than 30 actions [1, §4.1].
3. **Keep memory small.** The bound exists to keep prompts within the context limit [1, §4.1]. A sliding window is named as a limitation [1, §5].
4. **Ground code feedback in tests.** For code, the model writes up to 6 unit tests, filtered to syntactically valid ones, and reflects on their results [1, §4.3].

### Implementation details that generalise

- A reflection is useful only if the evaluator's verdict is right. A false "pass" ends the attempt early with a wrong answer, so false positives hurt more than false negatives [1, §4.3, Analysis].
- In the code ablation, tests without the written reflection did not help: the model saw the failures but its fixes did not address them [1, §4.3, Table 3].

## 3. Evidence

| Task | Baseline | Reflexion | Source |
|---|---|---|---|
| ALFWorld, 134 tasks, ReAct + heuristic trigger | ReAct alone stops improving between trials 6 and 7 | 130 of 134 solved over 12 trials | [1, §4.1, Fig. 3] |
| HumanEval Python, GPT-4, pass@1 | 80.1 | 91.0 | [1, §4.3, Table 1] |
| MBPP Python, GPT-4 | 80.1 | 77.1 | [1, Table 1] |
| LeetCode Hard Python (40 problems) | 7.5 | 15.0 | [1, §4.3, Table 1] |
| HumanEval Rust, hardest 50 | 0.60 | 0.68 | [1, Table 3] |
| HumanEval Python, starchat-beta, 8 trials | 0.26 | 0.26 | [1, App. A, Table 4] |

- ALFWorld used GPT-3 as the model. The ReAct-only agent settled at a 22% hallucination rate with no recovery [1, §4.1, Analysis].
- The MBPP loss tracks test quality: false-positive test results were 16.3% on MBPP Python against 1.4% on HumanEval Python [1, §4.3, Analysis; Table 2].
- Ablation on HumanEval Rust: tests without reflection scored 0.60, the same as the base model. Reflection without tests scored 0.52, below the base [1, Table 3].
- WebShop, 100 environments: no sign of improvement after four trials, and the reflections were not useful. The authors conclude the method fails on tasks that need diverse exploration [1, App. B.1, Fig. 6].
- The authors read the starchat-beta result as showing that self-correction emerges only in stronger models [1, App. A].
- HotpotQA, 100 questions: gains with every model tried, for example ReAct with gpt-4 from 0.39 to 0.51 [1, App. A, Table 5].

## 4. Evidence boundaries

- Apart from starchat-beta, all models are OpenAI models of 2023. The paper does not give starchat-beta's size, and no model was fine-tuned.
- Only the starchat-beta table has a spread; the other results are single runs.
- The "more than 3 identical cycles" trigger is a fixed choice, not compared against other triggers.
- Retries start from a reset environment. The method does not cover recovery inside one long attempt.
- The tasks are short programs and text games, not multi-file projects.

## 5. What we take from it

Our interpretation, not the paper's claims.

- The weak-model result argues against asking our 9B model to write its own reflection. The admin model should write the lesson; the small model then retries the task with it.
- Restart-with-lesson is a cheaper admin intervention than the admin taking over, and each one yields a (state, lesson) pair for training data.
- The evaluator has to be trustworthy. Acceptance checks must come from the harness, never from tests the model wrote.
- Keep a small cap on stored lessons per task. Larger memories were not tested.

## Reference

[1] Noah Shinn, Federico Cassano, Edward Berman, Ashwin Gopinath, Karthik Narasimhan, Shunyu Yao. *Reflexion: Language Agents with Verbal Reinforcement Learning.* NeurIPS 2023. arXiv:2303.11366v4. <https://arxiv.org/html/2303.11366v4>. Code: <https://github.com/noahshinn024/reflexion>. Accessed 2026-11-11.
