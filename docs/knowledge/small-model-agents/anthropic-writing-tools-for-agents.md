# Writing Effective Tools for Agents - with Agents

- **Source:** https://www.anthropic.com/engineering/writing-tools-for-agents
- **Authors / org:** Ken Aizawa and contributors (Anthropic)
- **Date:** 11 September 2025
- **Type:** engineering blog
- **Read:** full text

## Summary

The post describes how Anthropic develops tools for agents and what properties make tools work. It is written about Claude models, not small models, and most claims are qualitative.

The process is evaluation-driven. Build a quick prototype of the tools, then write realistic multi-step tasks with verifiable outcomes, run the agent on them, and record accuracy, runtime, number of tool calls, tokens and tool errors. Read the transcripts to see where the agent is confused: many redundant calls suggest missing pagination or limits; frequent invalid-parameter errors suggest unclear descriptions or missing examples. Use a held-out task set to avoid overfitting the tools to the evaluation.

The design principles:

- Choose few, purposeful tools rather than one per API endpoint. Prefer a search tool to a list-everything tool, and merge common multi-step sequences into one tool. Overlapping tools distract the agent.
- Namespace tools with consistent prefixes so their boundaries are clear.
- Return meaningful context. Human-readable names beat opaque identifiers; replacing arbitrary IDs with natural-language names or simple indexed IDs reduced hallucination in their tests.
- Let the agent pick verbosity with a response-format parameter. In their example a detailed response was 206 tokens and a concise one 72.
- Bound output with pagination, filtering and truncation and say when output was truncated and how to narrow the request. Claude Code caps tool responses at 25,000 tokens.
- Make error messages actionable: state what was wrong and show a correctly formatted input instead of a code or a traceback.
- Treat tool descriptions as prompts. Name parameters unambiguously (`user_id`, not `user`) and spell out formats. The post reports that small description changes produced large gains, including on SWE-bench Verified, without giving figures.

## Key points

- Tool quality is measured with task evaluations and transcript reading, not by inspection.
- Fewer, higher-level tools; consolidate frequent call chains.
- Opaque identifiers invite hallucination; return names the model can reason about.
- Errors should say how to fix the call and show a valid example.
- Parameter names and descriptions are part of the prompt.
- Evidence is mostly anecdotal and specific to Claude.

## Relevance to JacKnife

(Our interpretation, not the source's claims.)

- Our model "never self-corrects misuse of a tool parameter". The first fix to try is on the tool side: rename the parameter, tighten its type, and make the error show a valid call for that tool.
- Hallucinated file paths are the identifier problem. Tools should return exact paths the model can copy, and a missing-path error should list the nearest real paths rather than only saying "not found".
- Track tool-error rate per tool and per parameter in our run logs; a parameter that fails often is an interface defect to fix, not a model behaviour to prompt around.
- Combine sequences the harness always wants (edit then check) into one tool so the model cannot skip or misorder them.
- Note the tension with `stuck-in-a-loop/feedback-that-backfires.md`: show a valid example call, but do not echo the failed call.
