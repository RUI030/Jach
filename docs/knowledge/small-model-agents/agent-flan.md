# Agent-FLAN: Designing Data and Methods of Effective Agent Tuning for Large Language Models

- **Source:** https://arxiv.org/html/2403.12881
- **Authors / org:** Zehui Chen, Kuikun Liu, Qiuchen Wang, Wenwei Zhang, Jiangning Liu, Dahua Lin, Kai Chen, Feng Zhao (University of Science and Technology of China; Shanghai AI Laboratory)
- **Date:** 19 March 2024
- **Type:** paper
- **Read:** full text

## Summary

The paper studies how to construct fine-tuning data for agent behaviour, using Llama-2 7B, 13B and 70B. It starts from three observations. First, typical agent data entangles a rigid output format (Thought / Action / Action Input) with the actual reasoning; the model fits the format almost immediately while the loss on content stays high. Second, different skills are learned at different speeds: instruction following is fastest, reasoning slowest. Third, existing agent-tuning data ignores hallucination.

The method has three parts. Format alignment rewrites ReAct-style samples as ordinary multi-turn chat so the model learns the behaviour rather than a template; only 10% of data is kept in the strict format. Capability decomposition splits data by skill (reasoning, retrieval, understanding, instruction following) and reweights it towards the slow skills. Negative samples teach when not to act: queries that ask for a tool when none is provided, and ordinary questions asked while tools are available.

Two hallucination types are defined: format hallucination (emitting agent-format keywords when not asked) and action hallucination (calling functions that do not exist, or calling a tool when a plain reply is right). A benchmark, Agent-H (1,845 samples), measures both.

With about 24.7k agent samples mixed 1:1 with general chat data, the 7B model scored 41.7 on the paper's combined agent evaluation against 38.2 for the AgentTuning baseline and 27.2 untuned. On T-Eval it reached 66.0 against 61.8. The 761 negative samples raised the hallucination score from 84.5 to 89.1 with no loss in task score. Using 25% of the data delivered most of the gain. Halving reasoning data hurt most; halving instruction-following or retrieval data had little effect. General ability (MMLU, GSM8K, HumanEval) was essentially unchanged.

## Key points

- Models overfit the surface format of agent data quickly; converting to natural chat improved results by about 3 points on T-Eval.
- Reasoning data is the scarce resource; format and instruction-following data saturate early.
- A few hundred negative samples (about 3% of the data) measurably reduce calls to non-existent tools.
- Mixing in general chat data preserved general ability.
- A quarter of the data gave most of the benefit: diversity over volume.
- Benchmarks are general tool use, not coding.

## Relevance to JacKnife

(Our interpretation, not the source's claims.)

- Hallucinated file paths and tools are action hallucination. The remedy shown here is in the training data: add examples where the right action is to say the file or tool does not exist, or to search first.
- If our fine-tuning set is all strict tool-call format, the model may have learned the template more than the decisions. Check loss separately on format tokens and on argument content.
- When adding JacKnife trajectories, prioritise steps that carry reasoning (diagnosing a checker error, choosing what to edit) over routine well-formed calls, which saturate quickly.
- Keep a share of non-agent data in each fine-tuning round to avoid degrading general Jac coding ability.
