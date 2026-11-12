# Aider: Separating Code Reasoning and Editing (Architect / Editor)

- **Source:** https://aider.chat/2024/09/26/architect.html
- **Authors / org:** Aider project (aider.chat)
- **Date:** 26 September 2024
- **Type:** engineering blog
- **Read:** full text

## Summary

Aider normally asks one model to solve a coding problem and, in the same response, emit the edits in a strict format. The post describes splitting this into two calls. An Architect model describes the solution in whatever form it likes. An Editor model receives that description and produces well-formed file edits. The motivation was OpenAI's o1 models, which reasoned well but often produced malformed edit instructions; the general argument is that solving and formatting compete for the model's attention.

Results are on Aider's code-editing benchmark. Every model improved when paired with an editor, including when paired with itself:

- o1-preview alone 79.7%; with o1-mini or DeepSeek as editor (whole-file format) 85.0%, the best result at the time.
- Claude 3.5 Sonnet alone 77.4%; as architect and editor 80.5%.
- GPT-4o alone 71.4%; with itself as editor 75.2%.
- o1-mini alone 61.1%; with DeepSeek as editor 71.4%.
- GPT-4o-mini alone 55.6%; with itself 60.2%.

The strongest configurations pair a strong reasoner with a cheaper, fast editor. Self-pairing gains (3 to 5 points) show that part of the benefit comes from the separation itself rather than from adding a second, different model.

Caveats in the post: the top scores use the "whole" format, in which the editor rewrites the entire file, which is slow; results come from one benchmark; the feature was experimental at the time. The benchmark is single-shot editing, not a multi-step agent loop.

## Key points

- Two calls: free-form solution description, then mechanical conversion to edits.
- Gains of 3-10 points across all tested models, including self-pairing.
- A cheap model is adequate as editor when given a clear description of the change.
- Whole-file output scored highest but is slow; diff formats are cheaper and slightly lower.
- Evidence is one benchmark, single-turn edits.

## Relevance to JacKnife

(Our interpretation, not the source's claims.)

- This is the "large model plans, small model executes" pattern at the level of one edit. The admin can write a natural-language description of the fix and the 9B model applies it, which keeps most tokens on the small model.
- The self-pairing result suggests a no-admin variant: have the small model first state the intended change in prose, then make the edit in a second call. This directly targets failed-edit loops caused by doing reasoning and edit formatting together.
- For small Jac files, a whole-file rewrite tool may be more reliable for our model than search/replace edits, at higher token cost. Worth measuring.
- The admin's output should be written for an executor: explicit file, location and change, not a discussion.
