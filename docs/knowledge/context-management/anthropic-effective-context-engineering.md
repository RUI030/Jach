# Treating Context as a Budget: Retrieval, Compaction, Notes and Sub-Agents

A method note based on Anthropic's "Effective context engineering for AI agents" [1].

- **Evidence:** D. Vendor engineering blog; practice-based guidance with no controlled comparisons.
- **Numbers checked against the source:** yes, 2026-11-11, against the HTML page text.

## 1. Problem

Agents run many turns, and each turn adds instructions, tool output and history to what the model sees. The article argues that recall falls as the window fills, so the design question is which tokens the model should see at each step, not how to fit more in. [1, "Why context engineering is important"]

## 2. Method

The guiding rule is the smallest set of high-signal tokens that produces the wanted outcome. [1, "The anatomy of effective context"]

| Component | Guidance |
|---|---|
| System prompt | A middle "altitude": neither hard-coded if-else logic nor vague guidance; sectioned with tags or headers; start minimal and add instructions from observed failures |
| Tools | Small, self-contained, non-overlapping; token-efficient output |
| Examples | A few diverse, canonical examples rather than a list of edge cases |
| Retrieval | "Just in time": keep lightweight references (paths, queries, links) and load content with tools when needed |

For tasks longer than the window it names three techniques [1, "Context engineering for long-horizon tasks"]:

| Technique | What it does | Suggested fit |
|---|---|---|
| Compaction | Summarise the history near the limit and continue from the summary | Long back-and-forth |
| Structured note-taking | Write state to files outside the window and read it back | Iterative work with clear milestones |
| Sub-agents | Explore in a clean window and return a condensed result | Research with parallel exploration |

### Key decisions

1. **Context is finite with diminishing returns.** The stated reasons are that attention relates every token to every other (n² pairs) and that training data contains fewer long sequences, giving a gradient rather than a cliff. [1, "Why context engineering is important"]
2. **Tool result clearing is called one of the safest, lightest forms of compaction**: once a tool result is deep in the history, the raw result is rarely needed again. [1, "Compaction"]
3. **Tune compaction for recall first, then precision.** Over-aggressive compaction can lose context whose importance shows only later. [1, "Compaction"]
4. **Ambiguous tool sets are a common failure.** If an engineer cannot say which tool applies, the model will not do better. [1, "The anatomy of effective context"]

### Implementation details that generalise

- In Claude Code, compaction keeps architectural decisions, unresolved bugs and implementation details, drops redundant tool output, and continues with the summary plus the five most recently accessed files. [1, "Compaction"]
- Claude Code is a hybrid: project instruction files are loaded up front; everything else is found with glob and grep. [1, "Context retrieval and agentic search"]
- File names, folder structure and timestamps act as signals that help the agent decide what to load. [1, "Context retrieval and agentic search"]

## 3. Evidence

- Sub-agents may use tens of thousands of tokens but return a summary of often 1,000 to 2,000 tokens. [1, "Sub-agent architectures"]
- A multi-agent research system is said to show a substantial improvement over a single agent on complex research tasks; the figure is in a separate post and is not given here. [1, "Sub-agent architectures"]
- A Claude agent playing Pokémon kept tallies and maps in notes across thousands of steps and context resets. This is an anecdote. [1, "Structured note-taking"]

## 4. Evidence boundaries

- **No measurements** support any of the recommendations in this article.
- **Frontier models only.** The guidance assumes a strong model that can judge relevance, write notes and summarise well.
- **The compaction prompt is not given**, so its slot list cannot be reused.
- The context-rot claim rests on cited needle-in-a-haystack studies, not on new data.

## 5. What we take from it

Our interpretation, not the paper's claims.

- Folding each completed execution to a short line with an id is tool result clearing with a pointer left behind, the family the article calls safest.
- The "fewer long sequences in training" argument applies with more force to a model trained only to 16k: treat 16k as the real budget.
- Task files with scope and acceptance criteria play the role of structured notes, and the harness, not the model, should write them, since our model rarely takes such steps unprompted.
- `unfold(id)` should be one obvious tool, not several overlapping retrieval variants.

## Reference

[1] Prithvi Rajasekaran, Ethan Dixon, Carly Ryan, Jeremy Hadfield (Anthropic Applied AI team). *Effective context engineering for AI agents.* Anthropic Engineering blog, 2025-09-29. <https://www.anthropic.com/engineering/effective-context-engineering-for-ai-agents>. Accessed 2026-11-11.
