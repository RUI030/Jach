# Rule-Based Stuck Detection over the Event Log, with a Nudge before Stopping

A method note based on the OpenHands software-agent SDK `StuckDetector` [1].

- **Evidence:** C. Shipped source code; shows what the detector does, not that its rules or thresholds are better than others. No evaluation of the thresholds is published with the code.
- **Numbers checked against the source:** yes, 2026-11-11, against raw `stuck_detector.py`, `types.py` and `impl/local_conversation.py` on `main` (head commit `9f7d5cb`; `stuck_detector.py` last changed in commit `c3985a4c1f`, 2026-10-29).

## 1. Problem

An agent loop can keep calling the model forever while it repeats one action, alternates between two, or talks to itself without acting. The harness needs a cheap, deterministic way to notice this and stop the run, without flagging normal work such as a batch of parallel calls.

## 2. Method

`StuckDetector.is_stuck()` looks at the events after the last user message, inside a window of `MAX_EVENTS_TO_SCAN_FOR_STUCK_DETECTION = 20` events. It checks five scenarios in order and returns `True` on the first match. Thresholds are fields of `StuckDetectionThresholds` in `types.py`.

| Scenario (method) | Rule | Default |
|---|---|---|
| 1. `_is_stuck_repeating_action_observation` | The last N actions are all equal and the last N observations are all equal | `action_observation = 4` |
| 2. `_is_stuck_repeating_action_error` | The trailing streak of responses that repeat one failing action is greater than N | `action_error = 3`, so it fires on the 4th |
| 3. `_is_stuck_monologue` | At least N consecutive agent messages with no action or observation between them | `monologue = 3` |
| 4. `_is_stuck_alternating_action_observation` | The last N actions and the last N observations each equal the one two positions earlier (A, B, A, B, A, B) | `alternating_pattern = 6` actions and 6 observations |
| 5. `_is_stuck_context_window_error` | Disabled: always returns `False` (TODO pointing at SDK issue 282) | none |

### Key decisions

1. **Warn once, then stop.** `get_action_error_nudge()` returns a message when the action-error streak equals the threshold (3). The message names the tool, says the same arguments gave the same error 3 times, and quotes the latest error. `_last_nudged_error_event_id` keeps it to one nudge per streak. Scenario 2 fires only at streak 4, so the model gets exactly one warned attempt.
2. **Error loops are warned, not stopped sooner.** The defaults look lower for errors (3 against 4), but scenario 2 uses "greater than", so both a repeated failing call and a repeated successful one stop the run at the 4th occurrence. What differs is that the failing case gets the nudge at 3 and is matched more loosely (decision 4).
3. **Parallel calls are one attempt.** `_action_error_streak` counts distinct `llm_response_id` values, not calls. `_invalid_calls_share_response` skips scenarios 1 and 4 when the invalid calls being compared came from one response, since the model has not yet seen any of their errors.
4. **Equality is defined per event type, ignoring ids.** `_event_eq` compares valid actions on source, tool name, parsed action and the model's `thought`. Invalid calls (no parsed action) are compared on tool name and validated arguments, with the SDK's `security_risk` and `summary` fields removed first. Inside an action-error streak, `_same_error_action` compares invalid calls by the multiset of validation-error `(type, location)` pairs, with list indices set to 0, unless a `value_error` or `assertion_error` is involved.
5. **Detection stops the run.** In `LocalConversation._check_stuck_or_nudge`, a nudge is appended as an environment `MessageEvent` and the loop continues; a positive `is_stuck()` sets `execution_status` to `STUCK` and ends the run loop. Detection is on by default (`stuck_detection=True`), and thresholds can be passed as a dict.

### Implementation details that generalise

- Comparing the model's `thought` as part of a valid action means a reworded thought defeats scenarios 1 and 4. Comparing validation-error signatures for invalid calls does the opposite: different wrong values at the same field still count as one mistake.
- The monologue counter skips condensation summary events, so history folding does not reset it.
- The action-error window widens with the largest number of parallel calls in one response, so wide batches cannot push the streak out of the window.
- `is_stuck()` returns early when there are fewer events than the smallest of the action-observation, action-error and monologue thresholds.

## 3. Evidence

There is no measured evidence. The repository ships the thresholds as defaults without a published evaluation of detection rate, false positives, or effect on task success [1, `types.py`, `StuckDetectionThresholds`]. The code comment on the scan window explains its size only as room for 4 repeats of 2 events plus a buffer [1, `stuck_detector.py`, `MAX_EVENTS_TO_SCAN_FOR_STUCK_DETECTION`].

## 4. Evidence boundaries

- The thresholds are engineering defaults tuned, if at all, for the frontier models OpenHands is usually run with. Nothing indicates they were set for a 9B model.
- Only exact repetition (after normalisation) is caught. A model that changes one argument each time, or alternates over three steps, passes every rule.
- The detector does not escalate. Its only responses are one nudge and a stop.
- The nudge text quotes the latest error. Whether that helps a small model is not tested here; see the note on feedback that backfires.

## 5. What we take from it

Our interpretation, not the source's claims.

- The five scenarios are a reasonable starting rule set for JacKnife, written as a pure function over the event log, with the response policy kept separate.
- The nudge-then-stop pair fits our ladder: nudge at streak k, and call the admin model at k+1 instead of stopping.
- Matching invalid calls by validation-error signature fits our misused-parameter failures, where irrelevant fields vary between attempts.
- Including the model's reasoning text in the equality key is a choice to avoid. Our model's reasoning varies more than its actions.

## Reference

[1] OpenHands (All Hands AI). *software-agent-sdk*, `openhands-sdk/openhands/sdk/conversation/stuck_detector.py`, `.../conversation/types.py` (`StuckDetectionThresholds`), `.../conversation/impl/local_conversation.py` (`_check_stuck_or_nudge`). Branch `main`, head commit `9f7d5cb11b1256c1878f5584a657401feca9ad16`. <https://raw.githubusercontent.com/OpenHands/software-agent-sdk/main/openhands-sdk/openhands/sdk/conversation/stuck_detector.py>. Accessed 2026-11-11.
