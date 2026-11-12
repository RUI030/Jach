# Branch-and-Return Context Folding Trained with RL

A method note based on "Scaling Long-Horizon LLM Agent via Context-Folding" [1].

- **Evidence:** B. Controlled comparison on one base model with matched RL baselines; single-group preprint; no error bars; two benchmarks.
- **Numbers checked against the source:** yes, 2026-11-11, against the arXiv PDF (v1) text.

## 1. Problem

A ReAct agent appends every action and observation, so a long task fills the window. Summarising when the window is full drops detail at arbitrary points. The paper asks whether an agent can fold its own history at sub-task boundaries and keep a small working context without losing accuracy. [1, §1, §2.4]

## 2. Method

The agent gets two tools. `branch(description, prompt)` opens a separate working context for a sub-task. `return(message)` ends the branch: everything produced inside it is removed from the main thread and only the return message is appended. [1, §2.2]

The paper instantiates this as plan and execute. In the main thread the agent plans and decides when to branch; token-heavy tool use there is discouraged. Inside a branch it executes, and nested branches are disabled. [1, §2.2]

The model is trained with FoldGRPO, a GRPO variant in which the policy is computed on the folded context and token-level process rewards are added to the binary outcome reward. [1, §2.3]

### Key decisions

1. **Fold at sub-task boundaries, not when the window is full.** The authors describe folding as summarisation aligned with sub-task ends, so detail is kept while it is in use. [1, §2.4]
2. **The model writes the fold summary itself** as the `return` message. [1, §2.2]
3. **Shape behaviour with process rewards**, because outcome reward alone produced two failures: heavy work left in the main thread, and branches never returned from. [1, §2.3.2]
   - −1 on every main-thread token (except branch-creating turns) once the main thread passes 50% of the working-context limit.
   - −0.2 on all tokens of a branch that an LLM judge (GPT-5-nano) finds went outside its sub-task.
   - −1 on all tokens of a failed tool-call turn.
4. **Only model-generated tokens are trained**; tool observations are masked from the loss. [1, §2.3.1]

### Implementation details that generalise

- On `return` the KV-cache is rolled back to the branch point, because the main-thread prefix is unchanged. Folding then costs no re-prefill. [1, §2.2]
- Folding can be read as a sub-agent system whose sub-agents are created on the fly, share the main prefix and run interleaved rather than in parallel. Parallel branches scored about the same as single ones (0.613 vs 0.620 on BrowseComp-Plus). [1, §2.4, §4.5.3]

## 3. Evidence

Base model Seed-OSS-36B-Instruct. Folding agent: 32,768-token working context, up to 10 branches (327,680 tokens total). Summary agent: 32K with up to 10 summary sessions. All RL baselines use the same model, data and hyperparameters. Pass@1, greedy decoding, BrowseComp-Plus N=150 (held-out split), SWE-bench Verified N=500. [1, §3.1–3.3, Table 1]

| Agent | Context | BC-Plus | SWE-V |
|---|---|---|---|
| ReAct | 32K | 0.286 | 0.436 |
| ReAct | 327K | 0.478 | 0.552 |
| ReAct + GRPO | 327K | 0.540 | 0.574 |
| Summary | 32K × 10 | 0.386 | 0.488 |
| Summary + GRPO | 32K × 10 | 0.527 | 0.550 |
| Folding, no RL | 32K × 10 | 0.420 | 0.492 |
| Folding + GRPO | 32K × 10 | 0.567 | 0.564 |
| Folding + FoldGRPO | 32K × 10 | 0.620 | 0.580 |

Behaviour statistics [1, §4.3, Table 2]:

| Folding agent | Finish (BC / SWE) | Main-thread tokens (BC / SWE) | Scope accuracy (BC / SWE) |
|---|---|---|---|
| No RL | 0.806 / 0.781 | 12,195 / 47,475 | 0.774 / 0.473 |
| + GRPO | 0.738 / 0.612 | 22,285 / 48,908 | 0.762 / 0.419 |
| + FoldGRPO | 0.935 / 0.962 | 7,752 / 8,885 | 0.895 / 0.754 |

- Plain GRPO made folding behaviour worse: lower finish rate and longer main threads. [1, Table 2]
- With 50 questions combined into one task, the agent used 32.6 branches on average, although training allowed at most 10. [1, §4.4.2]

## 4. Evidence boundaries

- **On SWE-bench the gain over an RL-trained long-context ReAct is small.** 0.580 vs 0.574, from one run with no error bars. The larger gap is on BrowseComp-Plus (0.620 vs 0.540).
- **Without RL, folding is worse than plain 327K ReAct** on both tasks. Most of the gain comes from training, not from the mechanism.
- **The smallest model is 36B**, with 32K working context. Nothing is measured near 9B.
- **No unfold.** Once a branch returns, its content is gone from the model's view.
- **The scope penalty needs an external LLM judge** during training.

## 5. What we take from it

Our interpretation, not the paper's claims.

- A JacKnife task maps onto a branch: the task brief is the prompt, the checked result is the return message. Having the harness end the task removes the "never returns" failure the paper needed RL to fix.
- The untrained folding agent left 47K tokens in its main thread on SWE-bench. We should not expect a 9B model to fold on its own; harness-driven folding is the safer default.
- If any fold behaviour is model-driven, it must appear in our training trajectories, and failure modes (out-of-scope work, failed tool calls) need explicit negative signal.

## Reference

[1] Weiwei Sun, Miao Lu, Zhan Ling, Kang Liu, Xuesong Yao, Yiming Yang, Jiecao Chen (ByteDance Seed; CMU; Stanford). *Scaling Long-Horizon LLM Agent via Context-Folding.* arXiv:2510.11967v1, 2025-10-13. <https://arxiv.org/pdf/2510.11967>. Project page: <https://context-folding.github.io/>. Accessed 2026-11-11.
