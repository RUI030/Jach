# Designing Tools for Agents with an Evaluation Loop

A method note based on Anthropic's "Writing effective tools for agents" [1].

- **Evidence:** D. Vendor engineering blog about Claude models; results are shown only as unlabelled charts and anecdotes, with no controlled comparison in the text.
- **Numbers checked against the source:** yes, 2026-11-11, against the raw HTML of the post. It contains very few numbers.

## 1. Problem

A tool is a contract between deterministic software and a non-deterministic agent. Tools written like ordinary APIs, one per endpoint, returning everything, waste the agent's context and invite wrong calls. The post describes how Anthropic builds and tunes tools so that agents use them well. [1, "What is a tool?"]

## 2. Method

An iterative loop: prototype the tools, write realistic evaluation tasks, run an agent on them, read the transcripts, change the tools, repeat. A held-out task set guards against tuning the tools to the evaluation. [1, "How to write tools"]

### Key decisions

1. **Evaluate on realistic multi-step tasks with verifiable outcomes.** Strong tasks may need dozens of tool calls. Verifiers should not reject correct answers over formatting. [1, "Generating evaluation tasks"]
2. **Measure more than accuracy.** Record runtime, number of tool calls, tokens and tool errors. Many redundant calls suggest pagination or limits are wrong; many invalid-parameter errors suggest unclear descriptions or missing examples. [1, "Running the evaluation", "Analyzing results"]
3. **Build few tools, aimed at workflows.** Prefer `search_contacts` to `list_contacts`; merge chains that are always called together (find availability, then schedule) into one tool. Overlapping tools distract the agent. [1, "Choosing the right tools"]
4. **Namespace tools by service and resource.** The choice between prefix and suffix schemes had sizeable, model-dependent effects in their evaluations. [1, "Namespacing your tools"]
5. **Return meaningful context.** Drop low-level identifiers; resolving UUIDs to readable names, "or even a 0-indexed ID scheme", improved Claude's precision in retrieval tasks by reducing hallucinations. No figure is given. [1, "Returning meaningful context"]
6. **Treat descriptions as prompts.** Name parameters unambiguously (`user_id`, not `user`), make implicit formats explicit, and enforce inputs with strict data models. [1, "Prompt-engineering your tool descriptions"]

### Implementation details that generalise

- A `response_format` enum (`concise` or `detailed`) lets the agent choose verbosity. In their Slack example the detailed response was 206 tokens and the concise one 72. [1, "Returning meaningful context"]
- Give large outputs pagination, range selection, filtering or truncation with sensible defaults. When truncating, say how to narrow the request. [1, "Optimizing tool responses"]
- Error responses should state a specific, actionable fix and can show a correctly formatted input, instead of an error code or traceback. [1, "Optimizing tool responses"]
- The response format itself (XML, JSON, Markdown) affects results; the post says the best choice depends on the model's training data and the task. [1, "Returning meaningful context"]
- In evaluation prompts, ask the agent to write reasoning and feedback before the tool call. [1, "Running the evaluation"]

## 3. Evidence

- Claude Code limits tool responses to 25,000 tokens by default. [1, "Optimizing tool responses"]
- Concise against detailed response: 72 against 206 tokens, about a third. [1, "Returning meaningful context"]
- Claude Sonnet 3.5 reached a state-of-the-art SWE-bench Verified score after refinements to tool descriptions. The post gives no figure for the change. [1, "Prompt-engineering your tool descriptions"]
- Anecdote: Claude's web search tool kept adding "2025" to queries. A change to the tool description fixed it. [1, "Analyzing results"]
- Held-out results for internal Slack and Asana tools are shown only as charts; their values are not in the page text. [1, "Running an evaluation"]

## 4. Evidence boundaries

- Every claim is about Claude models. Nothing is measured on a small or fine-tuned model.
- No ablation separates the principles. The claims of significant or dramatic improvement come with no numbers.
- Most of the advice came from Claude itself optimising the tools against the evaluation. [1, "Collaborating with agents"]
- Advice on what to return (names against IDs) assumes the model reasons well over natural language. A small model's behaviour may differ.

## 5. What we take from it

Our interpretation, not the post's claims.

- Our model's offset misuse is the `user` against `user_id` problem. Renaming the parameter to say its base (for example `start_line`, one-based, matching the viewer) and validating it strictly is a tool fix to try before any training fix.
- The post's tool-error rate per parameter is a cheap metric for our run logs. A parameter that fails often is an interface defect.
- Merging call chains the harness always wants (edit, then check) into one tool removes a step the model can skip.
- Showing a valid example in an error fits this post and SWE-agent. `../stuck-in-a-loop/feedback-that-backfires.md` warns against echoing the failed call, so show the valid form only.

## Reference

[1] Ken Aizawa, with contributors (Anthropic). *Writing effective tools for agents — with agents.* Anthropic Engineering blog, 11 September 2025. <https://www.anthropic.com/engineering/writing-tools-for-agents>. Accessed 2026-11-11.
