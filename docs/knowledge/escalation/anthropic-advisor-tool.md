# Anthropic Advisor Tool (API documentation)

- **Source:** https://platform.claude.com/docs/en/agents-and-tools/tool-use/advisor-tool
- **Authors / org:** Anthropic
- **Date:** undated documentation page; tool version `advisor_20260301` (beta); fetched 2026-11-11
- **Type:** docs
- **Read:** first ~100k of ~125k characters (the end of the model compatibility table and anything after it were not read)

## Summary

The advisor tool lets a cheaper "executor" model consult a stronger "advisor" model in the middle of a task. The executor does the work and decides when to ask. When it calls the tool (with empty input), the platform runs the advisor on the executor's full transcript: system prompt, tool definitions, all prior turns and tool results. The advisor has no tools and returns only advice text, such as a plan or a correction. Typical advice is 400-700 tokens.

The docs position this for long agentic work in which most turns are mechanical but the plan matters. The built-in tool description asks the executor to consult near the start of a complex task and when stuck. For coding, the suggested system prompt asks for a consult after initial orientation and before substantive work, once more before declaring the task done, when stuck, and when considering a change of approach. It also tells the executor to give the advice serious weight and, if the advice conflicts with evidence, to raise the conflict in another consult instead of silently diverging.

The vendor's internal numbers (task-dependent, not independently verified): the smallest executor under-calls the advisor; a forced nudge early in the conversation raised its pass rate by about 7 points, had no effect on the mid-tier executor, and slightly hurt the top tier. A coding-specific timing prompt gave about +7.5 points on a coding benchmark and about -4 on a browsing benchmark. A rule forcing a consult before the first write helped under-calling tasks by 7-10 points but was flat overall because of over-calling. Capping advice at 2,048 tokens did not measurably change accuracy; 1,024 truncated about 10% of calls.

Controls include a per-turn `max_uses`, a `max_tokens` cap on advice, and caching of the advisor's view of the transcript (worthwhile from about three calls). There is no built-in per-conversation cap.

## Key points

- Advice, not takeover: the strong model reads everything, writes a short plan or correction, and the weak model keeps executing.
- The advisor is tool-less and sees the whole transcript.
- Weaker executors under-call; forcing consults helps them and can hurt stronger ones.
- Recommended consult points: before committing to an approach, before declaring done, when stuck.
- Short advice (hundreds of tokens) is the norm; a 2k cap cost nothing measurable.
- Call caps must be tracked by the client across a conversation.

## Relevance to JacKnife

(Our interpretation, not the source's claims.)

- This is an "advice" admin mode, cheaper than takeover: the admin reads the task transcript and returns a short directive that the harness injects.
- Our model will not reliably ask for help (even the vendor's small model under-calls), so the harness should trigger consults: at task start for planning, on stuck detection, and before accepting completion.
- Budget admin calls per task in the harness and cap advice length; long advice is not needed.
- The "surface conflicts, do not silently diverge" rule needs a harness equivalent: after advice, check that the next action is consistent with it, since a 9B model may ignore it.
- All numbers are vendor-internal and for Claude models; they indicate direction only.
