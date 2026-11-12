# Stuck in a loop

Sources on why LLM agents repeat actions or stall, how shipped harnesses detect it, and which responses help. The folder holds two failure taxonomies built from annotated traces, the loop detectors of three harnesses (read from source code or official docs), reflection between attempts, and one study of why error feedback makes small models repeat a failed call. All sources were fetched and checked on 2026-11-11.

| Note | Grade | One-line takeaway |
|---|---|---|
| [mast-why-multi-agent-systems-fail.md](mast-why-multi-agent-systems-fail.md) | B | Step repetition is the most common of 14 failure modes (15.7% of labels), but it occurs about as often in successful runs as in failed ones. |
| [empirical-study-issue-solving-failures.md](empirical-study-issue-solving-failures.md) | B | Agentic coders fail mostly while iterating and validating, failed runs take 3.5 times more steps, and an expert reviewer agent solved 24 of 108 failed issues. |
| [feedback-that-backfires.md](feedback-that-backfires.md) | B | For models of 1.7B and below, the failed call's tokens in context drive repeats; abstracting the call and banning it cut loops from 29% to 4% without raising success. |
| [reflexion.md](reflexion.md) | A | A harness rule ends a stuck attempt, the model writes a lesson, and the retry reads it; gains with strong models, none with a weak one or with wrong self-written tests. |
| [openhands-stuck-detector.md](openhands-stuck-detector.md) | C | Four deterministic patterns over the event log, one nudge at a 3-error streak, then the run stops. |
| [gemini-cli-loop-detection.md](gemini-cli-loop-detection.md) | C | Hash-based call cycles of length 1 to 5, text-chanting detection and a late LLM judge; one recovery turn, then stop. |
| [openrouter-doom-loop-detection.md](openrouter-doom-loop-detection.md) | C | A configurable ladder (observe, steer, escalate to a stronger model, block, stop) with a per-tool definition of "the same call". |

Related notes elsewhere: `trajectory-data/swe-smith.md` (repetition in a fine-tuned 32B agent) and `small-model-agents/swe-agent-aci.md` (recovery after a failed edit). Their numbers were not rechecked for this folder.

## Detector rules compared

| System | What counts as "the same" | Rule and default threshold | Response | Scope |
|---|---|---|---|---|
| OpenHands SDK | Valid action: tool, parsed action and thought, ids ignored. Invalid call: tool and arguments; in error streaks, validation-error type and location | Same action and observation 4 times; same failing action in more than 3 responses; 3 agent messages with no action; A-B alternation over 6 actions and 6 observations | Nudge once at an error streak of 3; stop the run (`STUCK`) on any rule | Events since the last user message, window of 20 |
| Gemini CLI | SHA-256 of tool name and JSON arguments; 50-character text chunks | A cycle of 1 to 5 calls repeated 5 times; a text chunk seen 10 times, average gap of 250 characters or less, 5 or fewer distinct gaps; LLM judge from turn 30, confidence 0.9 or more, confirmed by a second model if available | First detection: one feedback turn; second: end the turn | Per user prompt |
| OpenRouter SDK | All inputs after normalisation, or a per-tool `loopKey`; exact text | Streak of informed repeats; other tools in between do not reset it; text needs 4 repeats | observe at 2, block at 3, stop at 6; steer and escalate off by default | Conversation; survives save and resume |
| Reflexion (ALFWorld) | Same action and same observation | More than 3 identical cycles, or more than 30 actions | End the attempt, write a lesson, retry | One attempt |
| Expert-Executor | Judged by the expert model | Passive review every 25 rounds (round limit 40), plus requests from the executor | Expert advice | One issue |

None of the three shipped detectors publishes an evaluation of its thresholds. The Reflexion and Expert-Executor triggers are fixed settings, also not compared against alternatives.

## Patterns across sources

- **Repetition is common at every model size, and worse in small models.** MAST ranks step repetition first (15.7%); in its open-model appendix, step repetition is labelled 97 and 99 times for CodeLlama-7b in two settings of a 400-trace set. The issue-solving study finds agentic tools failing mostly in late iteration. Rests on MAST and the issue-solving study (B).
- **Repetition is a symptom more than a verdict.** MAST finds step repetition about as often in successful runs (20.0%) as failed ones (20.0%) in ChatDev. In the small-model study, cutting loops from 29% to 4% left success unchanged or lower. Rests on MAST and the small-model study (B).
- **Shipped detectors are deterministic first.** OpenHands, Gemini CLI and OpenRouter compare normalised (tool, arguments) and count. Only Gemini CLI adds an LLM judge, late and with a 0.9 bar. Rests only on grade C.
- **Thresholds cluster at 3 to 6 repeats and are unevaluated.** OpenHands stops at the 4th repeat, Gemini CLI at the 5th, OpenRouter blocks at 3 and stops at 6, and Reflexion's rule is more than 3. Rests only on grade C, plus one fixed setting in Reflexion.
- **Sources disagree on whether telling the model works.** OpenHands, Gemini CLI and OpenRouter all send a "you are repeating" message. In the small-model study, "do not repeat" moved repeat probability by +0.07 nats (interval includes zero), yet raised rollout success from 0.42 to 0.58. Gemini CLI's recovery message quotes the looping call, which that study found raises repeats. Rests on grade C against one B study of models up to 1.7B.
- **What raised success added information or a stronger model.** Reflexion gained with GPT-4 lessons and not with starchat-beta. The expert reviewer solved 24 of 108 failed issues, against 7 for a single Claude 4 Sonnet agent. OpenRouter offers escalation but shows no data. Rests on A and B sources; the escalation rung is C only.
- **Self-checking needs a trustworthy evaluator.** Reflexion lost to the baseline on MBPP (77.1 against 80.1) when 16.3% of its own test results were false passes. MAST finds verifiers that check only compilation. The issue-solving study names validation retreat, where the agent edits the test. Rests on A and B sources.

## Gaps

- No source measures any loop detector's precision, recall or effect on task success.
- No study covers models between 2B and 30B, or a model fine-tuned on one language. The small-model effect at 9B is untested.
- No source compares response policies head to head, for example nudge against block against escalation, on the same tasks.
- No detector handles near-repeats where one argument changes each time, such as an invented file path, except through hand-written per-tool keys.
- No source measures what a recovery message should contain beyond the small-model study's toy environment.
