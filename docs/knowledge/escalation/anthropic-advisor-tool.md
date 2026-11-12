# A Strong Model That Advises but Does Not Act (Advisor Tool)

A method note based on Anthropic's advisor tool documentation [1].

- **Evidence:** C for how the tool behaves (official product docs). The effect sizes quoted are vendor-internal tests on Claude models with small or unstated samples, so treat them as D.
- **Numbers checked against the source:** yes, 2026-11-11, against the page's full Markdown source (tool version `advisor_20260301`, beta).

## 1. Problem

Long agent tasks have many mechanical turns and a few turns where the plan decides the outcome. Running a strong model throughout is expensive; running a cheap one throughout loses quality at those few turns. The docs position the tool for long-horizon agentic work, not single-turn Q&A. [1, intro, §When to use it]

## 2. Method

An executor model works on the task and may call a tool named `advisor` with empty input. The platform then runs a separate advisor model on the executor's full transcript: system prompt, tool definitions, prior turns, tool results, and the executor's text so far in this turn. The advisor has no tools and no context management; its thinking is dropped, and only its advice text returns as a tool result. The executor continues. [1, §How it works]

### Key decisions

1. **Advice, not takeover.** The executor keeps control; the advisor never acts in the environment.
2. **The executor decides when to call.** The executor signals timing; the server supplies the context. [1, §How it works]
3. **Full transcript in, short text out.** Typical advice is 400 to 700 text tokens, or 1,400 to 1,800 including thinking. [1, §Usage and billing]

### Implementation details that generalise

- Suggested consult points for coding: after initial orientation and before substantive work; when the task seems complete (after making the result durable); when stuck; when considering a change of approach. [1, §Suggested system prompt for coding tasks]
- How the executor should treat advice: give it serious weight; adapt only on empirical failure or primary-source contradiction; on a conflict, raise it in another consult instead of silently diverging. The docs add that a passing self-test is not evidence the advice is wrong. [1, same section]
- If other planner tools exist (a todo list), call the advisor first so its plan feeds them. [1, §Prompting for coding and agent tasks]
- Advice length can be steered by an instruction addressed to the advisor in the user message (for example, under 80 words); this is a soft limit. [1, §Trimming advisor output length]
- `max_uses` caps calls per turn; there is no built-in conversation-level cap, so the client counts calls and removes the tool at its limit. [1, §Tool parameters, §Cost control]

## 3. Evidence

All results are Anthropic-internal and reported without full detail.

- Weaker executors under-call. Appending a reminder before the second turn, if no call had happened, raised Haiku 4.5 pass rates by roughly 7 points; it had no measurable effect on Sonnet and slightly lowered Opus. [1, §Mid-conversation nudge]
- A coding-specific prompt for Haiku raised pass rates on an internal coding benchmark by roughly 7.5 points. A close variant cost roughly 4 points on a browse-comprehension benchmark (n = 1,266). [1, §Alternative system prompt for Haiku]
- A rule forcing a consult before the first state-changing call raised Opus pass rates on under-calling tasks by roughly 7 to 10 points, but caused over-calling elsewhere; the net effect on a mixed workload was roughly flat. [1, §Increasing advisor calls on Opus executors]
- Capping advice at `max_tokens` 2048 cut mean advice length about 7× with near-zero truncation; the minimum 1024 cut it about 10× and truncated about 10% of calls. Accuracy differences were within noise, at n = 40 per configuration. [1, §Capping advisor output]
- Advisor-side caching is recommended only when three or more calls per conversation are expected. [1, §Cost control]

## 4. Evidence boundaries

- No benchmark names (other than the browse task's size), no baselines, no variance. The docs themselves say results are task-dependent.
- Executors are Claude Haiku, Sonnet and Opus models, trained for tool use; sizes are not stated. Under-calling was worst in the weakest one. How a 9B model would behave is not measured.
- The advisor sees the transcript the executor already has. It cannot see files the executor has not opened.
- Nothing is said about whether advice-guided runs make good training data.

## 5. What we take from it

Our interpretation, not the source's claims.

- This defines the cheapest admin mode: read the task transcript, return a short directive, let the small model keep working. It fits cases where the small model can execute but chose a bad approach.
- Our model will not reliably ask (it rarely loads documentation on its own: 3 of 12 tasks), so the harness, not the model, should trigger consults: at task start, on stuck signals, and before accepting completion.
- Budget admin calls per task in the harness and cap advice length; a few hundred tokens is the norm.
- After advice, the harness can check that the next action is consistent with it, as a stand-in for "surface conflicts, do not silently diverge". Advice will not help where our model cannot write the fix; that case needs rewrite or takeover.

## Reference

[1] Anthropic. *Advisor tool.* Claude Platform documentation, tool version `advisor_20260301` (beta header `advisor-tool-2026-03-01`). <https://platform.claude.com/docs/en/agents-and-tools/tool-use/advisor-tool>. Markdown source fetched from the same URL with `.md`. Undated page; accessed 2026-11-11.
