# A Graded Response Ladder for Repeated Tool Calls

A method note based on the OpenRouter Agent SDK doom-loop detection docs [1].

- **Evidence:** C. Official product documentation of what the SDK does. No evaluation data and no source code were read.
- **Numbers checked against the source:** yes, 2026-11-11, against the raw Markdown docs page (undated; server `last-modified` 2026-11-12 03:30 GMT).

## 1. Problem

A stuck agent keeps spending money on the same call. A detector that can only stop the run throws away runs that a hint or a stronger model could have saved. Tools also differ in what "the same call" means: a search with different capitalisation is the same, while a status poll is meant to repeat.

## 2. Method

Detection runs inside the SDK's `callModel` tool loop and is off by default (`doomLoop: true` enables it). Three kinds of repetition are counted:

1. a call to one of the caller's tools with the same inputs, including repeatedly sending an empty `{}` or invalid JSON;
2. a repeated request to a server-side tool, such as the same web search;
3. repeated text: a phrase repeating at the end of a response, or a response identical to the previous one (`text: { minRepeats: 4 }` by default).

Each repeat adds one to a streak. Actions fire at thresholds on the streak, and the strongest one wins.

| Action | Effect | Default |
|---|---|---|
| `observe` | Emit a `DoomLoopDetected` hook event only | at 2 |
| `steer` | Add a message before the next turn saying the agent is repeating itself | off |
| `escalate` | Run the next turn on a stronger model and/or force an advisor consult, then switch back | off; needs an `escalation` config |
| `block` | Refuse the repeated call and return an error to the model | at 3 |
| `stop` | End the run with `SessionEnd.reason: 'doom_loop'` | at 6 |

### Key decisions

1. **Count only informed repeats.** A repeat counts only after the model has seen the previous result. Identical calls fired together in one turn count once.
2. **Interleaving does not reset.** Calling other tools between repeats keeps a tool's streak. Only changed inputs reset it.
3. **Make "the same" a per-tool setting.** `loopKey` can be a function returning the identity (for example a lower-cased, trimmed query), a list of fields that matter (`['command', 'cwd']`), or `false` to exempt a tool whose job is to repeat. A function may return `null` to skip one call. If it fails, the SDK falls back to comparing all inputs.
4. **Escalation is a rung, with a budget.** The documented example ladder is observe 2, escalate 3, block 5, stop 8, with `maxEscalations: 2` per conversation. When the budget runs out, the weaker actions take over.
5. **Reject configurations that cannot work.** The SDK warns about `block` without `stop`, which lets a model retry a blocked call forever, and about a weaker action set at a higher threshold than a stronger one, which can never fire.

### Implementation details that generalise

- Inputs are normalised before comparison, so rearranged JSON keys or formatting changes do not evade detection.
- `block` cannot apply to text or server-tool repeats, which have already happened. Those fall through to the strongest weaker action enabled.
- Streaks live in the saved conversation state. A new user message clears a `stop` verdict but keeps the streaks, so a model that resumes the same call is caught again.
- A lifecycle hook can override the action per event, for example downgrading a block for a tool known to repeat harmlessly.
- Repeats are judged on what the model sent, before any pre-tool hook rewrites the call.
- On `stop`, unfinished calls get error outputs so the saved conversation stays valid and resumable.

## 3. Evidence

There is no measured evidence. The page states the defaults as recommended values and gives no benchmark, detection rate or effect on task success [1, "Overview", "Getting unstuck with a stronger model"]. It lists its own blind spots: changing inputs without a `loopKey`, rephrased text, and calls executed by the caller's own code, which are not counted [1, "What this doesn't catch"].

## 4. Evidence boundaries

- The defaults are vendor choices for general-purpose agents. Nothing indicates they were set for small models.
- The docs do not say what the `steer` and `block` messages contain, so we cannot compare them with the small-model feedback findings.
- The escalation rung is described, not measured. Whether one turn on a stronger model resolves loops is not shown.
- Text detection needs exact repeats.

## 5. What we take from it

Our interpretation, not the source's claims.

- The ladder matches what JacKnife needs: steer, block the repeated call, escalate to the admin model, fail the task. The escalation cap per task should be explicit.
- "Other calls do not reset the streak" matters for us. A model that does edit, check, the same edit, check should keep accumulating.
- A per-tool identity key lets us treat "same file, same old text" as one edit even when incidental fields change.
- Blocking needs no cooperation from the model, which suits a model that ignores corrective text.

## Reference

[1] OpenRouter. *Doom-Loop Detection*, Agent SDK documentation, `callModel`. Undated. <https://openrouter.ai/docs/agent-sdk/call-model/doom-loop-detection.md>. Accessed 2026-11-11.
