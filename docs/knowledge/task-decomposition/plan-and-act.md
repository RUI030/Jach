# Separate Planner and Executor, with Replanning and Plans Recovered from Trajectories

A method note based on Plan-and-Act [1].

- **Evidence:** B. Controlled incremental ablation on one benchmark (165 tasks) plus two further benchmarks; single-group preprint; single runs, no error bars; web navigation only.
- **Numbers checked against the source:** yes, 2026-11-11, against the arXiv HTML (v3), main text and limitations.

## 1. Problem

A single model that both plans a long task and issues every low-level action tends to lose its strategy over many steps. Splitting planning from execution needs a planner that writes good plans, and off-the-shelf models plan poorly in domains they were not trained on. Training data of the form (request, plan) rarely exists. [1, §3, §4]

## 2. Method

A **Planner** turns the user request into a short list of high-level steps. An **Executor** turns the current step into one concrete action from the page HTML. With **dynamic replanning**, the Planner rewrites the plan after every Executor action, using the current state and the previous plans and actions. [1, §3.1–3.3]

Training data is synthesised in three stages. [1, §4, Fig. 3]

1. **Trajectories.** Generate new queries from seed queries, let a demonstrator agent attempt them, and keep the successful ones as judged by an outcome reward model. [1, §4.1]
2. **Grounded plan annotation.** A teacher LLM reads each successful trajectory and writes the plan it implies, mapping each plan step to the actions that carried it out. The same method produces replanning and reasoning-trace data. [1, §4.2]
3. **Plan expansion.** A teacher generates 10,000 more query-plan pairs from the seeds, then 5,000 more aimed at failure types found in error analysis. [1, §4.3]

### Key decisions

1. **Plans are reverse-engineered from what worked**, not written from the request alone. Plans written without seeing the environment were often misaligned with how the task has to be done. [1, §4.2]
2. **The plan carries memory.** Facts found during execution (for example, who the top contributor is) are written into the remaining plan, so no separate memory module is needed. [1, §3.3]
3. **Executor history is trimmed.** After each action the Executor drops redundant HTML before the next one. [1, §3.2]

### Implementation details that generalise

- Generating synthetic plans was far faster than collecting trajectories: 15,000 examples in under an hour, against days or weeks of environment interaction. [1, §6]
- Targeted augmentation works by classifying which training points relate to observed failure nodes and using them as seeds. [1, §4.3]

## 3. Evidence

WebArena-Lite, 165 tasks, binary success, Llama-3.3-70B Planner and Executor (replanning models trained with LoRA). Rows are cumulative. [1, §5.1–5.3, Table 1]

| Planner | Base executor | Fine-tuned executor | + synthetic trajectories |
|---|---|---|---|
| No planner | 9.85 | 36.36 | 36.97 |
| Zero-shot planner | 14.21 | 17.16 | 23.63 |
| + fine-tuned on 1,113 real plans | 22.42 | 16.36 | 20.60 |
| + synthetic trajectories | 24.24 | 27.28 | 30.30 |
| + 10,000 expanded plans | 27.10 | 38.18 | 39.40 |
| + 5,000 targeted plans | 29.63 | 42.42 | 43.63 |
| + dynamic replanning | 44.24 | 48.48 | 53.94 |
| + chain of thought | | | 57.58 |

- The previous best cited on WebArena-Lite is 49.1 (WebRL-Llama-3.1-70B). [1, Table 1]
- With the same chain-of-thought training data, Llama-3.1-8B reached 53.33 and QwQ-32B 54.88, against 53.94 for the 70B model without it. [1, §5.3.2, Table 2]
- Full WebArena: 45.7 (Llama 70B), 48.15 (QwQ-32B). WebVoyager: 58.08 (Llama-3.1-8B), 81.36 (QwQ-32B). [1, §5.4–5.5, Tables 3–4]

## 4. Evidence boundaries

- **Untrained or naively trained static plans hurt.** With a fine-tuned executor, adding a zero-shot planner dropped success from 36.36 to 17.16, and one fine-tuned on the 1,113 real plans to 16.36; the authors report it overfitted. [1, §5.2]
- **Trained static plans did help.** With the best executor, the static planner stack went from 36.97 (no planner) to 43.63. Replanning then added 10.31. [1, Table 1]
- **No coding tasks.** All results are web navigation.
- **No repeated runs or error bars.** A 165-task benchmark gives each task about 0.6 points.
- **The smallest model is 8B, fine-tuned for this domain**, and it was tested only with chain-of-thought data.
- **Stated limits:** replanning after every action is slow, and the trajectory stage needs a base agent that already solves some tasks. [1, Limitations]

## 5. What we take from it

Our interpretation, not the paper's claims.

- The task list should be revisable during the run. A short re-plan step after each task finishes or fails, rather than after each action, is a cheaper version of what helped most here.
- Grounded plan annotation is a direct recipe for plan-phase training data: take successful trajectories, have the admin model write the task list with acceptance criteria that they satisfy, and train on (request, task list) pairs.
- An untrained planner made a trained executor worse. A plan phase should not ship before the plan data exists.
- One fine-tuned model acting as both planner and executor, switched by the phase name in the prompt, is an assumption to test; the paper used separate models.

## Reference

[1] Lutfi Eren Erdogan, Nicholas Lee, Sehoon Kim, Suhong Moon, Hiroki Furuta, Gopala Anumanchipalli, Kurt Keutzer, Amir Gholami (UC Berkeley; University of Tokyo; ICSI). *Plan-and-Act: Improving Planning of Agents for Long-Horizon Tasks.* arXiv:2503.09572v3, 22 Apr 2025. <https://arxiv.org/html/2503.09572>. Accessed 2026-11-11.
