# Effective context engineering for AI agents

- **Source:** https://www.anthropic.com/engineering/effective-context-engineering-for-ai-agents
- **Authors / org:** Prithvi Rajasekaran, Ethan Dixon, Carly Ryan, Jeremy Hadfield (Anthropic Applied AI team)
- **Date:** 2025-09-29
- **Type:** engineering blog
- **Read:** full text

## Summary

The article frames context engineering as the successor to prompt engineering: the job is to decide which tokens (instructions, tools, message history, retrieved data) the model sees at each inference step. The motivating claim is that context is a finite resource. Recall drops as the window fills ("context rot"), partly because attention relates every token to every other token and partly because models have seen fewer long sequences in training. The decline is gradual, not a cliff. The stated goal is the smallest set of high-signal tokens that produces the wanted behaviour.

For system prompts it recommends a middle "altitude": neither hardcoded if-else logic nor vague guidance, organised into labelled sections, with a few diverse canonical examples instead of long lists of edge cases. For tools it recommends a small, non-overlapping set with token-efficient outputs; if a human cannot say which tool applies, the model will not either.

It describes "just in time" retrieval: the agent holds lightweight references (file paths, queries) and loads content with tools when needed, instead of loading everything up front. Claude Code is given as a hybrid: a project instruction file is loaded up front and everything else is found with glob and grep.

For long-horizon work it lists four techniques. Compaction summarises the conversation near the limit and restarts (Claude Code keeps the summary plus the five most recently accessed files). Tool result clearing removes old raw tool outputs and is called the lightest and safest form of compaction. Structured note-taking writes state to files outside the window (a NOTES.md or to-do list). Sub-agents explore in a clean window and return a condensed result, often 1,000 to 2,000 tokens.

## Key points

- Context is a budget; every added token reduces attention available for the rest.
- Tool result clearing is presented as the lowest-risk way to shrink history.
- When tuning a compaction prompt, first maximise recall, then trim for precision.
- Just-in-time loading through references (paths, ids) replaces pre-loading.
- Notes written to files survive context resets and let an agent resume.
- Sub-agents isolate token-heavy exploration and return 1-2k token summaries.

## Relevance to JacKnife

(Our interpretation.)

- Folding each completed turn to a short line while keeping an id to unfold is a form of tool result clearing with a reference left behind; the article treats this family as safer than whole-conversation summarisation.
- The model was trained only up to 16k tokens, so the "fewer long sequences in training" argument applies with more force: treat 16k as the real budget, not 262k.
- Keep the tool set small and non-overlapping; `unfold(id)` should be one obvious tool, not several retrieval variants.
- Task files with scope and acceptance criteria play the role of the article's structured notes; they should be written by the harness or by a dedicated step, not left to the model's memory.
