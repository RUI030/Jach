# Stuck in a loop

Sources on why LLM agents repeat actions or stall, how existing harnesses detect it, and what responses work. It covers failure taxonomies built from annotated traces, the loop detectors shipped in three open harnesses (read from source or official docs), retry-with-reflection, and one study of why error feedback fails to stop repetition in small models. All files were written from pages fetched on 2026-11-11; each file states how much of the source was read.

| File | One-line takeaway |
|---|---|
| [mast-why-multi-agent-systems-fail.md](mast-why-multi-agent-systems-fail.md) | In 1,642 annotated traces, step repetition is the most common single failure mode (15.7%); objective-level verification gave the largest fix (+15.6%). |
| [openhands-stuck-detector.md](openhands-stuck-detector.md) | Four deterministic patterns (same action+observation x4, same action+error x3, monologue x3, A-B alternation x6) with a one-time nudge before declaring stuck. |
| [gemini-cli-loop-detection.md](gemini-cli-loop-detection.md) | Hash-based cycle detection (period 1-5, repeated 5 times), text-chanting detection, and an LLM judge after 30 turns that needs 0.9 confidence twice. |
| [openrouter-doom-loop-detection.md](openrouter-doom-loop-detection.md) | A response ladder (observe 2, block 3, stop 6, optional steer and escalate-to-stronger-model) with per-tool definitions of "same call". |
| [reflexion.md](reflexion.md) | Stop on a detected stall, write a short lesson, retry with it; works with strong models and a reliable evaluator, gave nothing with a weak model or wrong tests. |
| [empirical-study-issue-solving-failures.md](empirical-study-issue-solving-failures.md) | Agentic coders fail mostly in iterate/validate, with failed runs 3.5x longer; an expert reviewer agent recovered 22% of failed issues. |
| [feedback-that-backfires.md](feedback-that-backfires.md) | For sub-2B models, putting the failed call in context raises the chance of repeating it; "do not repeat" does nothing, abstracted errors and decode bans help. |

Related material filed elsewhere: `small-model-agents/swe-smith.md` (repetition statistics for a fine-tuned 32B agent, and scaffold mitigations that reduced repetition but not failures) and `small-model-agents/swe-agent-aci.md` (recovery probability after a failed edit).

## Patterns across sources

- Repetition is common even with frontier models. MAST ranks it first among 14 failure modes, and the issue-solving study finds agentic tools fail mainly in late iteration. It is more severe in smaller fine-tuned models (see SWE-smith: over 25% of trajectories with a 10+ step repeated sequence against under 4% for the teacher).
- Production detectors are deterministic first. OpenHands, Gemini CLI and OpenRouter all hash or compare (tool, arguments) and count; only Gemini CLI adds an LLM judge, and only late and with a high confidence bar.
- Thresholds in shipped harnesses are 3 to 5 identical repeats, lower for error loops than for success-looking loops. None of the three publishes an evaluation of its thresholds; they are engineering defaults.
- Detectors differ on what counts as "the same". Gemini CLI uses exact argument hashes; OpenHands compares validation-error signatures for invalid calls; OpenRouter allows a per-tool key. Exact matching misses loops where an irrelevant field changes.
- Responses form a ladder: tell the model, block the call, escalate to a stronger model, stop. OpenHands nudges once and then flags; OpenRouter documents the full ladder.
- Sources disagree on whether telling the model helps. OpenHands and OpenRouter ship a "you are repeating yourself" message. The small-model study finds a "do not repeat" instruction has no effect on repeat probability, and that the failed call in context is itself the main cause.
- Breaking the loop is not the same as solving the task. SWE-smith's scaffold mitigations and the small-model decode ban both reduced repetition without improving success; SWE-smith's authors suggest repetition may be a symptom of difficulty. The interventions that did raise success added information or capability: a reflection from a strong model (Reflexion), or an expert reviewer (Expert-Executor).
- Self-reflection needs a capable model and a trustworthy evaluator. Reflexion gained nothing with a weak model and lost ground when its self-written tests were wrong.
