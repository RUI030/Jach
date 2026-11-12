# OpenHands SDK StuckDetector

- **Source:** https://raw.githubusercontent.com/OpenHands/software-agent-sdk/main/openhands-sdk/openhands/sdk/conversation/stuck_detector.py (thresholds: https://raw.githubusercontent.com/OpenHands/software-agent-sdk/main/openhands-sdk/openhands/sdk/conversation/types.py)
- **Authors / org:** OpenHands (All Hands AI)
- **Date:** main branch as fetched on 2026-11-11
- **Type:** source code
- **Read:** full text of `stuck_detector.py`; the `StuckDetectionThresholds` class in `types.py`

## Summary

`StuckDetector` inspects the events since the last user message (scan window: 20 events, widened when one model response contains parallel tool calls) and returns a boolean from `is_stuck()`. It checks five scenarios in order.

1. Repeating action-observation: the last N actions are equal and the last N observations are equal. Default N = 4.
2. Repeating action-error: the same failing action produces an error repeatedly. Default threshold 3; detection fires only when the streak exceeds the threshold, so on the fourth occurrence.
3. Monologue: N consecutive agent messages with no action. Default 3.
4. Alternating pattern: A, B, A, B over the last N events, each matching the event two positions earlier. Default 6.
5. Context-window error loop: present but disabled (always returns false, pending an SDK issue).

Equality is deliberately loose. Actions are compared on tool name, thought and parsed action while ignoring call ids; for invalid calls it compares parsed arguments, or the validation-error type and location with list indices normalised. Parallel calls from one model response count as one attempt, so a batch of bad calls is not mistaken for a loop before the model has seen any error.

A notable design element is the nudge. When the action-error streak first reaches the threshold (one step before the detector fires), `get_action_error_nudge()` returns a message telling the model that the same arguments keep producing the same error and that it should change the arguments or the approach. It is emitted once per streak. Only if the model repeats again is the run declared stuck.

## Key points

- Four live patterns: identical action+observation (4), identical action+error (3, fires on 4th), monologue (3), two-step alternation (6 events).
- Error loops have a lower threshold than success-looking loops.
- Warn-then-stop ladder: one nudge at the threshold, hard detection one repeat later.
- Invalid tool calls are compared by validation-error signature, so "same mistake, slightly different text" still counts.
- Parallel calls in one response are a single attempt.
- Detection only returns a flag; the caller decides what to do.

## Relevance to JacKnife

(Our interpretation, not the source's claims.)

- These four patterns map directly onto our failure mode; a JacKnife detector can start with the same set and thresholds, then tighten them (a 9B model that never self-corrects probably does not deserve four identical attempts).
- Comparing invalid calls by error signature rather than exact text fits our "misused tool parameter" case, where the model may vary irrelevant fields while repeating the same parameter error.
- The nudge-before-stop step is the natural hook for JacKnife: nudge at streak k, call the admin model at k+1 instead of terminating.
- Keep detection (pure function over the event log) separate from the response policy, so the policy can differ per phase or task.
