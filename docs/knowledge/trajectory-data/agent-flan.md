# Agent Tuning Data: Chat-Format Alignment, Capability Balancing and Negative Samples

A method note based on Agent-FLAN [1].

- **Evidence:** B. Controlled ablations on Llama-2 7B with public code; preprint; general tool-use and agent benchmarks, not coding.
- **Numbers checked against the source:** yes, 2026-11-11, against the arXiv HTML.

## 1. Problem

Fine-tuning on agent trajectories has side effects. The paper reports three: the model learns the output template before the decisions inside it; agent skills are learned at different speeds; and tuned models emit agent-format text or tool calls when a plain reply was wanted. [1, §3]

## 2. Method

Agent-FLAN rebuilds the AgentTuning corpus (AgentInstruct plus ToolBench, 24,703 samples in total) in three ways. [1, §4, App. B, Table 6]

| Change | What is done |
|---|---|
| Chat-format alignment | ReAct "Thought / Action / Action Input" turns are rewritten as ordinary multi-turn dialogue; JSON arguments are split up with short lead-in statements. 10% of the data is kept in ReAct format, plus 2,000 instruction-following samples that ask for ReAct or JSON output explicitly. [1, §4.1, App. A] |
| Capability balancing | Each turn is labelled as reasoning (thought), retrieval (choosing the function), understanding (the arguments) or instruction following (the format). The final mix weights reasoning : retrieval : understanding at 1 : 0.25 : 0.75. [1, §3, §4.2, App. A] |
| Negative samples | 761 ToolBench queries answered by GPT-3.5 with no tool offered; half of them also get irrelevant tools in the system prompt. The model sees cases where the right answer is a plain reply. [1, §4.3, App. C] |

The agent data is mixed 1:1 with general chat data (ShareGPT), and loss is applied only to assistant turns. [1, §4.1, App. A]

### Key decisions

1. **Separate format from content.** The authors observed that loss on formatted agent data falls fast while content loss stays high, and read this as the model fitting the template. [1, §3, Fig. 2]
2. **Rebalance by learning speed.** Instruction following converged fastest and reasoning slowest in the per-capability loss curves, so the fast-converging parts are down-weighted. [1, §3, Fig. 3]
3. **Teach when not to act.** Training data usually covers only "no tools, chat" and "tools, use them"; the two mixed cases are added explicitly. [1, §4.3, Fig. 6]

### Implementation details that generalise

- Down-weighting fast-learned data cut training tokens from 37.3M to 18.1M with a slightly higher T-Eval score. [1, §4.2, Table 2]
- A small share of explicitly formatted data keeps the ability to emit a required format on request. [1, §4.1]

## 3. Evidence

Llama-2-7B unless noted.

| Comparison | Result | Source |
|---|---|---|
| Overall agent score: Agent-FLAN vs AgentTuning (same data size) vs untuned | 41.7 vs 38.2 vs 27.2 | [1, §4, Table 1] |
| T-Eval tool use: ReAct format vs chat-aligned (all data) vs weighted mix | 61.8 vs 64.9 vs 66.3 | [1, §4.2, Table 2] |
| T-Eval when halving reasoning / understanding data | −1.1 / −0.3 points | [1, §4.2, Table 2] |
| Agent-H score: AgentTuning vs Agent-FLAN vs Agent-FLAN without negatives | 83.9 vs 89.1 vs 84.5 | [1, §4.3, Table 3] |
| T-Eval with vs without negatives | 66.0 vs 66.3 | [1, §4.3, Table 3] |
| General ability (MMLU, GSM8K, HumanEval) vs general-data-only | within ±0.4 at 7B; up to +1.1 at 13B | [1, §5.2, Table 4] |

- Halving retrieval or instruction-following data left T-Eval unchanged or slightly higher (65.3, 65.9 vs 64.9). [1, §4.2, Table 2]
- With 25% of the data the model got "the most" of the gain; later quarters added less. Values are only in a figure. [1, §5.1.1, Fig. 7]
- Gains held from 7B to 13B and 70B; values are only in a figure. [1, §5.1.2, Fig. 8]

## 4. Evidence boundaries

- **The hallucination benchmark measures less than its name suggests.** Agent-H (1,845 samples from glaive-function-calling-v2) checks only whether the output is a raw reply or a function call, and whether it contains agent keywords such as "Thought:" or "I need to call". [1, §4.3] It does not test whether a called tool exists or whether its arguments are valid.
- **Negatives cost a little task score.** T-Eval was 0.3 lower with them. [1, Table 3]
- **No error bars or repeated runs** are reported. Domains are general tool use, web, QA and science, not repository coding; models are Llama-2.
- **The "format versus content" observation rests on one loss plot** with no ablation isolating it.

## 5. What we take from it

Our interpretation, not the paper's claims.

- Our data uses Qwen's own chat template and its native XML tool-call syntax, which is the paper's chat-alignment point. Harness structure (phase headers, fold lines) should sit inside normal roles as plain content, not as a new wire format.
- A low overall training loss can hide unlearned decisions. Logging loss separately for tool names, arguments and reasoning text costs little and shows whether the model is learning more than the template.
- Our hallucinated imports and paths are a kind of action hallucination that Agent-H does not measure. The analogue for us is negative examples in our own format: a missing module answered by searching or loading documentation, a tool not offered in this phase, an `unfold` id that does not exist.
- Turns that carry decisions (diagnosing a checker error, choosing the edit) should be weighted above routine well-formed calls, which are learned early.

## Reference

[1] Zehui Chen, Kuikun Liu, Qiuchen Wang, Wenwei Zhang, Jiangning Liu, Dahua Lin, Kai Chen, Feng Zhao (USTC; Shanghai AI Laboratory). *Agent-FLAN: Designing Data and Methods of Effective Agent Tuning for Large Language Models.* arXiv:2403.12881. <https://arxiv.org/html/2403.12881>. Code: <https://github.com/InternLM/Agent-FLAN>. Accessed 2026-11-11.
