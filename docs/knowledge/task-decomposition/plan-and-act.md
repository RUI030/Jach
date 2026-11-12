# Plan-and-Act: Improving Planning of Agents for Long-Horizon Tasks

- **Source:** https://arxiv.org/html/2503.09572
- **Authors / org:** Lutfi Eren Erdogan, Nicholas Lee, Sehoon Kim, Suhong Moon, Hiroki Furuta, Gopala Anumanchipalli, Kurt Keutzer, Amir Gholami (UC Berkeley and others)
- **Date:** 2025-03 (arXiv v3 dated 2025-04-22)
- **Type:** paper
- **Read:** main text (first ~100k characters of the HTML; later appendices not read)

## Summary

The paper separates a web agent into a Planner, which writes a high-level step plan from the user's request, and an Executor, which turns the current step into concrete actions from the page HTML. The argument is that one model doing strategy and low-level action at once loses consistency over long tasks. With dynamic replanning, the Planner rewrites the plan after every Executor step using what was just observed.

Because planning data is scarce, the authors synthesise it in three steps. First, collect action trajectories from a demonstrator agent and keep the successful ones using an outcome reward model. Second, "grounded plan annotation": an LLM reads each successful trajectory and writes the high-level plan that it implies, linking each plan step to the actions that carried it out. Third, plan expansion: an LLM generates about 10,000 more query-plan pairs from those seeds, plus 5,000 targeted at failure types found in error analysis.

Planner and Executor are fine-tuned LLaMA-3.3-70B models (smaller models are also reported). On WebArena-Lite: no planner with a fine-tuned executor scores 36.97%; a zero-shot planner with a base executor 14.21%; a planner fine-tuned only on the small set of real plans 22.42% and it overfits; plan expansion adds roughly 10 points; dynamic replanning adds roughly another 10, reaching 53.94% with the fine-tuned executor; adding chain-of-thought gives 57.58%. The previous best cited is 49.1%. An 8B model with chain-of-thought matched the 70B model without it. On WebVoyager an 8B model scored 58.08% and QwQ-32B 81.36%.

Stated limitations: replanning after every action is slow, and the pipeline needs a base agent that already solves some tasks.

## Key points

- Static plans help little and overfit; replanning from new observations gives the largest architectural gain.
- Plans for training can be reverse-engineered from successful trajectories.
- Synthetic plan data, including data targeted at observed failures, gave about 10 points.
- Explicit reasoning before the plan or action helped small models most.
- Web navigation only; no coding evaluation.

## Relevance to JacKnife

(Our interpretation.)

- The plan should be revisable. After each task completes or fails, the state machine should allow a short re-plan step that sees the folded result, not only at the start. Doing it per task instead of per action avoids the cost the authors report.
- Grounded plan annotation is directly usable for training data: take successful teacher trajectories and have a teacher write the task list with acceptance criteria that those trajectories satisfy, then train the plan state on (request, task list) pairs.
- Collect failure categories from evaluation runs and synthesise extra planning examples aimed at them.
- One fine-tuned model can serve as planner and executor if the state is named in the prompt; the paper used separate models, so this is an assumption to test.
