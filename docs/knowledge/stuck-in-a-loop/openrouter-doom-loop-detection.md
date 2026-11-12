# OpenRouter Agent SDK: Doom-Loop Detection

- **Source:** https://openrouter.ai/docs/agent-sdk/call-model/doom-loop-detection.md
- **Authors / org:** OpenRouter
- **Date:** undated documentation page, fetched 2026-11-11
- **Type:** docs
- **Read:** full text

## Summary

The page documents an optional detector in OpenRouter's agent loop and is useful mainly as a clear specification of a response ladder. It is off by default. When enabled, the default thresholds are: observe at 2 repeats, block at 3, stop at 6.

Three things count as repeats: the same tool called with the same inputs; identical server-side tool requests; and repeated text (a phrase repeating at the end of a response, or a response identical to the previous one, default minimum 4 repeats). Malformed tool inputs count too: a model that keeps sending an empty object or invalid JSON is treated as stuck.

Counting rules are specific. Calling other tools in between does not reset a streak; only changing the inputs does. Several identical calls in one turn count once. A repeat is counted only if the model received the previous result and tried again.

Five actions exist, strongest wins: observe (emit a hook event), steer (inject a message saying the agent is repeating itself), escalate (run the next turn on a stronger model and/or force an advisor consult, then revert; capped by `maxEscalations` per conversation), block (refuse the call and return an error to the model), and stop (end the run). The SDK warns about configurations that cannot work, for example block without stop, which lets a stubborn model retry forever.

A per-tool `loopKey` defines what "the same call" means: a function or a list of fields (for instance only `command` and `cwd`) so that volatile fields such as timestamps do not defeat matching. Documented limitations: rephrased text evades text detection, and calls with changing inputs never match without a `loopKey`. The page gives no evaluation data.

## Key points

- Ladder: observe (2), block (3), stop (6); steer and escalate are opt-in rungs between.
- Interleaving other tools does not reset the streak; only changed inputs do.
- Malformed or empty tool inputs are counted as loop evidence.
- Escalation to a stronger model is a first-class loop response, with a conversation-wide cap.
- `loopKey` normalises call identity per tool.
- No benchmark numbers; thresholds are vendor defaults.

## Relevance to JacKnife

(Our interpretation, not the source's claims.)

- The ladder is close to what JacKnife needs: steer, then block the repeated call, then escalate to admin, then fail the task. The cap on escalations per task should be explicit.
- "Other calls in between do not reset the streak" matters for us: a model that does edit, check, edit (same), check should still accumulate.
- A per-tool identity key lets us treat "same file, same old_string" as the same edit even when incidental fields differ, and treat any call to a nonexistent path as the same class of error.
- Blocking is a harness action that needs no model cooperation, which suits a model that ignores corrective text.
