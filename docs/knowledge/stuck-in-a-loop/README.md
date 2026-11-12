# Stuck in a loop

Sources on why LLM agents repeat actions or stall, how shipped harnesses detect it, and which responses help. The folder holds two failure taxonomies built from annotated traces, the loop detectors of three harnesses (read from source code or official docs), reflection between attempts, and one study of why error feedback makes small models repeat a failed call. All sources were fetched and checked on 2026-11-11.

| Note | Grade | One-line takeaway |
|---|---|---|
| [mast-why-multi-agent-systems-fail.md](mast-why-multi-agent-systems-fail.md) | B | Step repetition is the most common of 14 failure modes (15.7% of labels), but it occurs about as often in successful runs as in failed ones. |
| [feedback-that-backfires.md](feedback-that-backfires.md) | B | For models of 1.7B and below, the failed call's tokens in context drive repeats; abstracting the call and banning it cut loops from 29% to 4% without raising success. |
| [reflexion.md](reflexion.md) | A | A harness rule ends a stuck attempt, the model writes a lesson, and the retry reads it; gains with strong models, none with a weak one or with wrong self-written tests. |
| [openhands-stuck-detector.md](openhands-stuck-detector.md) | C | Four deterministic patterns over the event log, one nudge at a 3-error streak, then the run stops. |
| [gemini-cli-loop-detection.md](gemini-cli-loop-detection.md) | C | Hash-based call cycles of length 1 to 5, text-chanting detection and a late LLM judge; one recovery turn, then stop. |

Related notes elsewhere: `trajectory-data/swe-smith.md` (repetition in a fine-tuned 32B agent) and `small-model-agents/swe-agent-aci.md` (recovery after a failed edit). Their numbers were not rechecked for this folder.
