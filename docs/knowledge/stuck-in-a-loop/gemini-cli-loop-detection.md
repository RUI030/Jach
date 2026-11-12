# Layered Loop Detection: Call-Cycle Hashing, Text Chanting, and a Late LLM Judge

A method note based on the Gemini CLI `LoopDetectionService` [1].

- **Evidence:** C. Shipped source code; shows what the service does, not that its rules or thresholds work well. No evaluation of the thresholds is published with the code.
- **Numbers checked against the source:** yes, 2026-11-11, against raw `packages/core/src/services/loopDetectionService.ts` and `packages/core/src/core/client.ts` at commit `aeb6c04` (`main`; the service file last changed in commit `acae7124bd`, 2026-07-17).

## 1. Problem

A CLI agent can repeat one tool call, cycle through a few calls, or stream the same sentence over and over. A human is often watching, so false alarms are costly. The service has to catch real loops cheaply and leave batch work alone, such as the same edit applied across many files.

## 2. Method

Three detectors run at different costs. All state is reset by `reset()` at each new user prompt, so counts are per prompt, not per session.

**Tool-call cycles (`checkToolCallLoop`).** Each call is keyed by a SHA-256 hash of `name:JSON.stringify(args)` (`getToolCallKey`). The last 25 keys are kept (`5 * TOOL_CALL_LOOP_THRESHOLD`). For each cycle length k from 1 to 5, a loop is declared if the last `k * 5` keys are the last k keys repeated 5 times (`TOOL_CALL_LOOP_THRESHOLD = 5`). This catches five identical calls in a row, and also an A, B, A, B pattern repeated five times.

**Content chanting (`checkContentLoop`, `isLoopDetectedForChunk`).** Streamed text is hashed in sliding chunks of `CONTENT_CHUNK_SIZE = 50` characters, over at most `MAX_HISTORY_LENGTH = 5000` characters. A loop needs all three of:

- the same chunk seen `CONTENT_LOOP_THRESHOLD = 10` times;
- an average gap between the last 10 occurrences of at most 250 characters (`CONTENT_CHUNK_SIZE * 5`);
- at most 5 distinct texts between consecutive occurrences (`Math.floor(CONTENT_LOOP_THRESHOLD / 2)`), so a list with a shared prefix is not a loop.

Text inside code fences is not tracked. Tables, list items, headings, blockquotes, dividers and any tool call reset the tracker.

**LLM judge (`turnStarted`, `checkForLoopWithLLM`).** Once a prompt has run `LLM_CHECK_AFTER_TURNS = 30` turns, a model is asked about the last `LLM_LOOP_CHECK_HISTORY_COUNT = 20` history entries plus the original user request. It returns an analysis and a confidence from 0 to 1. Confidence of at least `LLM_CONFIDENCE_THRESHOLD = 0.9` is required. If a second "double-check" model is available, it is asked too and must also reach 0.9; if not, the first verdict stands. The next check comes after `round(5 + 10 * (1 - confidence))` turns, between `MIN_LLM_CHECK_INTERVAL = 5` and `MAX_LLM_CHECK_INTERVAL = 15`, starting from `DEFAULT_LLM_CHECK_INTERVAL = 10` (`updateCheckInterval`).

### Key decisions

1. **Cheap checks always, model check late.** The hash checks run on every stream event. The judge runs only on long prompts and needs high confidence, twice when a second model exists.
2. **Tell the judge what is not a loop.** `LOOP_DETECTION_SYSTEM_PROMPT` requires a repetitive pattern over at least 5 consecutive model actions with no net progress. It excludes batch work across files, edits to different parts of one file, sequential reads, and retries with changed arguments. It tells the judge to compare arguments, not tool names.
3. **One recovery turn, then stop.** In `client.ts`, a first detection (`count === 1`) calls `_recoverFromLoop`: `clearDetection()` clears the flag but keeps the count, and a feedback message is sent that includes the detection detail and asks the model to step back. A second detection in the same prompt (`count > 1`) emits `LoopDetected` and ends the turn.

### Implementation details that generalise

- For a tool-call loop, the detail in the feedback message is the tool name plus its full JSON arguments, so the recovery message repeats the looping call back to the model.
- Before the judge sees it, the history is trimmed so it does not start with a function response or end with a function call (`trimRecentHistory`).
- Loop detection can be turned off for a session (`disableForSession`) or in configuration (`getDisableLoopDetection`).

## 3. Evidence

There is no measured evidence. The constants carry comments on their meaning but not on how they were chosen. No detection rate, false-positive rate or effect on task success is published with the code [1, `loopDetectionService.ts`, constants block].

## 4. Evidence boundaries

- The thresholds are defaults for Gemini models with a human in the loop. Nothing indicates tuning for small models.
- Exact hashing means any change in any argument breaks a tool-call match. Our inference, not tested: `JSON.stringify` keeps key order, so the same arguments in a different key order would also not match.
- A cycle has to fill the whole recent window. Inserting one different call resets the pattern.
- The judge costs one or two large-model calls per check and does not start before turn 30.

## 5. What we take from it

Our interpretation, not the source's claims.

- Detecting cycles of length 1 to 5 is worth copying. An edit, check, edit, check loop with identical content escapes a "same call N times" rule.
- Exact argument hashing will miss our invented-path loops, where the path changes each time. A second key such as (tool, error class) is needed beside the exact one.
- The "first detection gets one recovery turn, second ends it" counter maps onto our ladder, with the admin model in place of the plain stop.
- Echoing the repeated call in the recovery message is the opposite of what the small-model feedback study recommends. Our recovery text should describe the failure without quoting the call.

## Reference

[1] Google. *gemini-cli*, `packages/core/src/services/loopDetectionService.ts` and `packages/core/src/core/client.ts` (`_recoverFromLoop`). Commit `aeb6c04b093eb00c33585ba587c4889ae4c5e957` (`main`). <https://raw.githubusercontent.com/google-gemini/gemini-cli/main/packages/core/src/services/loopDetectionService.ts>. Accessed 2026-11-11.
