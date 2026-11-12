# Agent-FLAN: Designing Data and Methods of Effective Agent Tuning for Large Language Models

- **Source:** https://arxiv.org/html/2403.12881
- **Authors / org:** Zehui Chen, Kuikun Liu, Qiuchen Wang, Wenwei Zhang, Jiangning Liu, Dahua Lin, Kai Chen, Feng Zhao (USTC, Shanghai AI Laboratory)
- **Date:** 2024-03-19
- **Type:** paper
- **Read:** full text

## Summary

The paper studies how to construct agent fine-tuning data for open models (Llama-2 at 7B, 13B and 70B) and starts from three observations.

First, agent data entangles two things: following a rigid output format (ReAct, JSON) and reasoning. When trained on such data, the loss on format tokens drops quickly while the loss on content stays high; the model learns the template before it learns what to put in it. Second, capabilities are learned at different speeds: instruction following fastest, retrieval and understanding next, reasoning slowest. Third, tuned agents hallucinate in two ways: using the agent format when a plain answer was wanted, and calling tools that do not exist.

The method has three parts. (1) Rewrite formatted agent turns as ordinary multi-turn chat that matches the model's chat template, with loss applied only to assistant turns, plus a small amount of data that keeps the ability to follow explicit format instructions. (2) Split data by capability and rebalance; the final mix weights reasoning, retrieval and understanding at 1 : 0.25 : 0.75, and ablations show reasoning and understanding data matter most. (3) Add negative samples: queries that need a tool when none is offered, and ordinary queries with irrelevant tools offered, so the model learns when not to act.

Results for the 7B model: overall score 41.7 versus 38.2 for the prior method (AgentTuning); tool-use evaluation (T-Eval) 66.0 versus 61.8; hallucination score 89.1 versus 83.9. Removing the negative samples lowers the hallucination score to 84.5. Using 25% of the data captured most of the gain. Gains continued from 7B to 70B.

## Key points

- Models overfit the output template early; format tokens dominate the easy part of the loss.
- Aligning training data to the model's native chat template helps.
- Loss is computed only on assistant turns.
- Balance data by capability; more reasoning data, less of what is learned quickly.
- Negative examples (no suitable tool, irrelevant tools) reduce hallucinated tool calls.
- Diminishing returns from volume: a quarter of the data gave most of the benefit.

## Relevance to JacKnife

(Our interpretation.)

- Render JacKnife trajectories in the Qwen chat template with its native tool-call syntax; keep harness-specific structure (fold lines, state headers) as plain content inside standard roles instead of inventing a new wire format.
- Mask loss to assistant turns. Folded lines, tool results and harness messages are inputs, not targets.
- Track loss separately for format tokens and content tokens during training; a low overall loss can hide content that is not being learned.
- Include negative cases specific to this harness: an `unfold` request for an id that does not exist, a state where a tool is not allowed, a turn where no tool call is needed.
- Balance the dataset by state (understand, plan, implement, test, debug) so that the frequent, easy states do not dominate.
