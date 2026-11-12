# Scaling Long-Horizon LLM Agent via Context-Folding

- **Source:** https://arxiv.org/abs/2510.11967 (PDF: https://arxiv.org/pdf/2510.11967, project page: https://context-folding.github.io/)
- **Authors / org:** Weiwei Sun, Miao Lu, Zhan Ling, Kang Liu, Xuesong Yao, Yiming Yang, Jiecao Chen (ByteDance Seed, CMU, Stanford)
- **Date:** 2025-10-13
- **Type:** paper
- **Read:** abstract page, project page, and sections 1-4 of the PDF (appendices not read)

## Summary

The agent gets two extra tools. `branch(description, prompt)` opens a separate working context for a sub-task. `return(message)` ends the branch; the harness then removes every action and observation produced inside the branch from the main thread and appends only the return message. The agent alternates between a planning state (main thread, token-heavy tool use discouraged) and an execution state (inside a branch, where creating nested branches is disabled). Because the main thread prefix is unchanged, the KV-cache is rolled back to the branch point on return.

Prompting alone is not enough, so the authors train with FoldGRPO, a GRPO variant that computes the policy on the folded context and adds token-level process rewards: a penalty of -1 on main-thread tokens once the main thread exceeds 50% of the context limit, -0.2 on a branch that an LLM judge finds went outside its assigned sub-task, and -1 on failed tool-call turns. Loss is applied only to model-generated tokens; tool observations are masked.

The base model is Seed-OSS-36B with a 32,768-token context and up to 10 branches (327,680 tokens in total). On BrowseComp-Plus (150 held-out items) and SWE-bench Verified (500), pass@1 is 62.0% and 58.0%. The same model as a ReAct agent with a 327K window scores 47.8% and 55.2%; a summarise-when-full agent with RL scores 52.7% and 55.0%. Without RL the folding agent scores 42.0% and 49.2%, better than 32K ReAct but below 327K ReAct. After FoldGRPO the main thread averages about 8-9K tokens while over 100K are processed in total. Plain GRPO made behaviour worse on some measures (finish rate fell from 0.781 to 0.612 on SWE-bench).

## Key points

- Folding is aligned with sub-task boundaries, not triggered by a full window.
- The fold summary is written by the agent itself as the `return` message.
- Untrained, the model often fails to return from a branch or leaves heavy work in the main thread; this needed RL with shaped rewards to fix.
- Nested branches were disabled to keep structure simple.
- Folding beat summarisation at equal token budget in their setup; gains from RL were larger than gains from the mechanism alone.

## Relevance to JacKnife

(Our interpretation.)

- A JacKnife task maps onto a branch: the task brief is the `prompt`, the task result against its acceptance criteria is the `return` message. The paper supports folding at task boundaries.
- The observed failure modes (not returning, drifting out of scope) are the reason for a harness-owned state machine: let the harness decide when a task ends and what gets folded, instead of trusting a 9B model to call `return` correctly.
- If fold/unfold behaviour is to be learned, it has to appear in training data in the exact harness format; the paper shows a 36B model did not do it well zero-shot.
- A 32K working context was sufficient for SWE-bench-class tasks here; a 16k budget is tighter but in the same range, and the paper's main thread settled under 9K.
