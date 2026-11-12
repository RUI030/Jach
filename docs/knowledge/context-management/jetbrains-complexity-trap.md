# Observation Masking versus LLM Summarisation for Agent History

A method note based on "The Complexity Trap" [1].

- **Evidence:** B. Controlled experiment with public code and data; workshop paper; one benchmark.
- **Numbers checked against the source:** yes, 2026-11-11, against the arXiv HTML.

## 1. Problem

An agent's history grows every turn until it is too expensive or too long to send. The common fix is to have an LLM summarise older turns. That adds a second model call, a prompt to maintain, and a lossy rewrite of the history. Is it better than simply hiding old tool output?

The question matters because of where the tokens are: in a coding agent, tool output (file contents, listings, test logs) is about 84% of an average turn. [1, §1, Fig. 1]

## 2. Method

A turn has three parts: the model's reasoning, its action (the tool call), and the observation (the tool result). The paper compares three ways of building the history sent to the model. [1, §3.1]

| Strategy | What the model sees | Extra model calls |
|---|---|---|
| Raw | Everything | None |
| Observation masking | All reasoning and actions. Observations older than the last *M* turns are replaced by a placeholder line. | None |
| LLM summary | One running summary of old turns, plus the last *M* turns untouched. Re-summarised every *N* turns. | One per summary |

### Key decisions

1. **Mask by part, not by turn.** Reasoning and actions are kept for the whole run; only observations are hidden. The model keeps the full record of what it did and why.
2. **Use a fixed rolling window.** No model judgement is involved in deciding what to hide, so the step is deterministic and costs nothing.
3. **Tune the window to the harness.** The best *M* was 10 in SWE-agent and 58 in OpenHands. The paper attributes the gap to bookkeeping: SWE-agent removes failed-syntax retries from history, OpenHands keeps them, so its turns carry less information each. [1, §5.1, App. D.1]
4. **Treat summarisation as a last resort.** A hybrid masks from the start and summarises only after many more turns, to bound context on very long runs. [1, §5.3]

### Implementation details that generalise

- Masking slows context growth but does not bound it. A run that is long enough still overflows, which is the hybrid's reason to exist. [1, §3.1]
- A summary call cannot reuse the prompt cache, because each one reads a different span of turns. [1, §5.2]
- Reusing each strategy's own settings inside the hybrid made cost worse, not better. The hybrid needs its own tuning. [1, §5.3]

## 3. Evidence

SWE-agent on SWE-bench Verified (500 tasks), 250-turn limit, *M* = 10, *N* = 21. [1, §3.2, Table 1]

| Model | Strategy | Solve rate | Cost per task |
|---|---|---|---|
| Qwen3-Coder 480B | Raw | 53.4% ± 4.3 | $1.29 |
| | Masking | 54.8% ± 4.4 | $0.61 (−52.7%) |
| | LLM summary | 53.8% ± 4.2 | $0.64 (−50.4%) |
| Gemini 2.5 Flash, thinking | Raw | 40.4% ± 4.3 | $0.56 |
| | Masking | 36.4% ± 4.2 | $0.24 (−57.1%) |

- Masking was the cheapest strategy in four of five model setups. [1, §4.2]
- Summaries made runs longer: about 15% more turns than raw for Qwen3-Coder 480B. The authors suggest a summary hides the failure signals that would otherwise make the agent stop. [1, §4.4, Fig. 4]
- Summary calls were up to 7.2% of a task's cost. [1, §5.2, Table 2]
- The hybrid, on a 50-task subset, was 7% cheaper than masking and 11% cheaper than summarising. [1, §5.3]

## 4. Evidence boundaries

- **The solve-rate differences are inside the error bars.** 54.8, 53.8 and 53.4 with ±4 points do not separate. The supported claim is "masking is no worse and costs less", not "masking is better".
- **It is not free everywhere.** With Gemini 2.5 Flash in thinking mode, both strategies lost about 4 points or more against raw. [1, Table 1]
- **The smallest model tested is 32B.** Nothing here is measured on a model near 9B, or on a fine-tuned one.
- **One domain.** All results are from SWE-bench, where tool output is long. The authors say the result may not hold where output is short. [1, §6]
- **The OpenHands and hybrid results rest on 50 tasks each.** [1, §5.1, §5.3]
- **The window is blind.** It hides by age only, so a file's old contents can stay visible after the file has changed. [1, §6]

## 5. What we take from it

Our interpretation, not the paper's claims.

- Folding tool results while keeping the model's own actions is a sound default, and a deterministic fold needs no model call.
- How many recent turns stay unfolded must be measured on our harness and model. It depends on what else the harness keeps in history.
- Run length is worth tracking whenever fold rules change.

## Reference

[1] Tobias Lindenbauer, Igor Slinko, Ludwig Felder, Egor Bogomolov, Yaroslav Zharov (JetBrains Research; TU Munich). *The Complexity Trap: Simple Observation Masking Is as Efficient as LLM Summarization for Agent Context Management.* arXiv:2508.21433. <https://arxiv.org/html/2508.21433>. Code: <https://github.com/JetBrains-Research/the-complexity-trap>. Accessed 2026-11-11.
