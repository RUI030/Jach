# Threshold-Triggered Structured Summarisation of Agent History

A method note based on the OpenHands condenser post [1] and the current condenser source code [2].

- **Evidence:** D for the measured result (vendor blog, one-point difference on an unnamed subset, no variance). C for the mechanism, read from source code.
- **Numbers checked against the source:** yes, 2026-11-11, against the blog's HTML text and the source at commit `9f7d5cb` of `OpenHands/software-agent-sdk`.

## 1. Problem

In long sessions, an agent gets slower, costs more per turn and does worse as it processes irrelevant history. Starting a new chat fixes that but loses continuity. [1, "The Context Growth Problem"]

## 2. Method

When the history passes a size threshold, older events are replaced by an LLM-written summary and recent events are kept intact. The summary encodes the user's goals, progress made and what remains; for software tasks, also critical files and failing tests. [1, "Our Solution"]

### Key decisions

1. **Summarise only at a threshold, not every turn.** The prompt cache is rebuilt occasionally and reused in between. [1, "Optimizing for Cache Efficiency"]
2. **Use a separate summariser LLM**, which may differ from the agent's model. [2, `LLMSummarizingCondenser`]
3. **Protect the head and tail.** The first `keep_first` events (default 2) are never condensed, and the leading system prompt is never forgotten. [2, `keep_first`, `_get_forgotten_events`]
4. **Fixed summary slots.** The summariser prompt asks for USER_CONTEXT, TASK_TRACKING (preserving task IDs and statuses), COMPLETED, PENDING and CURRENT_STATE, and for code tasks also CODE_STATE, TESTS, CHANGES, DEPS and VERSION_CONTROL_STATUS. [2, `prompts/summarizing_system.j2`]

### Implementation details that generalise

From the source [2, `llm_summarizing_condenser.py`]:

- Three triggers: more than `max_size` events (default 240), more than `max_tokens` tokens (the smaller of the configured cap and the agent model's input limit), or an explicit request.
- Each condensation targets half: half of `max_size` events, or enough tokens to fall under half of `max_tokens`. When several triggers fire, the strictest wins.
- The start and end of the forgotten range are moved to the next index where the view may safely be cut, so the cut respects event boundaries.
- A condensation that would forget less than `minimum_progress` (default 10%) of events is treated as an error, so tiny condensations are not attempted.
- A hard reset summarises every event after the system prompt. If that summary call fails, each event string is cut to 80% of the previous limit and the call retried, up to 5 times.

## 3. Evidence

On a subset of SWE-bench Verified [1, "Major Efficiency Gains"]:

- Once condensation starts, average per-turn cost diverges from the baseline and settles at less than half of it.
- Solve rate: 54% with the condenser, 53% without.
- Turn counts rise slightly because condensation itself takes a turn.

The post argues that with similar-sized events, uncondensed cost grows quadratically with turns and condensed cost linearly. This is a model, not a measurement. [1, "Optimizing for Cache Efficiency"]

## 4. Evidence boundaries

- **The subset is not named or sized**, and no variance is given. 54% against 53% is not evidence of a difference.
- **The post does not name the model or the thresholds used.** The source defaults above are from November 2026 and may differ from the April 2025 run.
- **Independent work disagrees on value.** The JetBrains study, which ran OpenHands-style summarisation, found it no better than plain observation masking and that it made runs longer (see `jetbrains-complexity-trap.md`).
- Summaries are lossy and the forgotten events are not addressable by the agent; there is no unfold.

## 5. What we take from it

Our interpretation, not the paper's claims.

- This is the design we chose not to make primary; plain folding with unfold costs no model call.
- The summary slots are a good checklist for a task handover record. Most slots (task IDs, status, files touched, failing tests) can be filled by the harness from its own state without an LLM.
- `minimum_progress` and "reduce to half" are worth copying for any emergency compaction, so it neither fires for negligible gains nor fires again on the next turn.
- If a single task still overflows 16k after folding, a slot-based condensation of that task alone is a reasonable fallback.

## Reference

[1] Calvin Smith (OpenHands). *OpenHands Context Condensensation for More Efficient AI Agents.* Blog post, 2025-04-09. <https://openhands.dev/blog/openhands-context-condensensation-for-more-efficient-ai-agents>. Accessed 2026-11-11.

[2] OpenHands. `openhands-sdk/openhands/sdk/context/condenser/llm_summarizing_condenser.py` and `prompts/summarizing_system.j2`, repository `OpenHands/software-agent-sdk`, commit `9f7d5cb11b1256c1878f5584a657401feca9ad16` (2026-11-12 UTC). <https://github.com/OpenHands/software-agent-sdk>. Accessed 2026-11-11.
