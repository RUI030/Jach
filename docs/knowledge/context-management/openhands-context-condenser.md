# OpenHands Context Condensation for More Efficient AI Agents

- **Source:** https://openhands.dev/blog/openhands-context-condensensation-for-more-efficient-ai-agents
- **Authors / org:** Calvin Smith (OpenHands / All Hands AI)
- **Date:** 2025-04-09
- **Type:** engineering blog
- **Read:** full text

## Summary

The post introduces the default compaction mechanism in the open-source OpenHands coding agent. The problem stated is that long sessions get slower, cost more per turn, and work less well because the model processes more irrelevant history; starting a new chat fixes that but loses continuity.

The condenser fires only when the context reaches a size threshold. Older events are replaced by an LLM-written summary and the recent events are kept intact. The summary is structured around the user's goals, the progress made, and what remains to be done; for software tasks it also keeps technical details such as the important files and the failing tests. Because condensation happens only at the threshold and not every turn, the prompt cache is rebuilt occasionally and reused in between.

The author's cost argument: if events are roughly equal in size, total cost of an uncondensed session grows quadratically with the number of turns, while the condensed session grows linearly. On a subset of SWE-bench Verified, per-turn cost after condensation begins settles at less than half of the baseline. Solve rate was 54% with the condenser versus 53% without; no variance or significance is given, so this should be read as "not worse", not as an improvement. Turn counts rise slightly because condensation takes a turn.

The post does not give default thresholds, the size of the preserved tail, or the summary prompt. Those would have to be read from the OpenHands source, which was not done here.

## Key points

- Threshold-triggered summarisation of old events with a protected recent tail.
- The summary has fixed slots: goals, progress, remaining work, key files, failing tests.
- Triggering rarely keeps prompt caching useful.
- Reported outcome: about half the per-turn cost with solve rate unchanged within noise, on a subset.

## Relevance to JacKnife

(Our interpretation.)

- This is the design JacKnife chose not to use as its primary mechanism; the JetBrains paper (see `jetbrains-complexity-trap.md`) found that OpenHands-style summarisation gave no solve-rate advantage over masking.
- The summary slots are still a useful checklist for what a task-level handoff record must contain: goal, done, remaining, key files, failing tests.
- If a single task still overflows 16k after folding, a slot-based condensation of that task alone is a reasonable fallback; the harness can fill most slots from its own state without an LLM call.
- A 1-point difference on a subset is not evidence either way; JacKnife will need its own measurement.
