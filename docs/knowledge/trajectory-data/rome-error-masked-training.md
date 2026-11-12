# Let It Flow: Agentic Crafting on Rock and Roll, Building the ROME Model within an Open Agentic Learning Ecosystem

- **Source:** https://arxiv.org/html/2512.24873
- **Authors / org:** "ROCK & ROLL & IFLOW & DT Joint Team" (no individual authors listed in the text read)
- **Date:** 2025-12 (arXiv v3 dated 2026-03-12)
- **Type:** paper (technical report)
- **Read:** data and supervised-training sections (first ~100k of ~218k characters). The reinforcement-learning section and most evaluation detail were not read.

## Summary

The report describes an end-to-end pipeline for training a coding-agent model (ROME, built on a Qwen3 MoE base) and is useful here mainly for how it treats loss on imperfect trajectories.

Data. Tasks are bundles of a prompt, a Dockerfile and unit tests. Four agent roles build them: one drafts tasks from pull requests and issues, one builds and validates the Docker environment, one reviews solvability and test weaknesses, and one runs several scaffolds and models to produce trajectories. The coding pipeline yields 76K task instances; the authors report over one million trajectories across all synthesised data. Trajectories pass a four-stage filter: heuristics for malformed tool calls, an LLM judge for relevance, re-execution of tests, and expert review of borderline cases. The authors warn that some demonstrations are "fake positives": they pass the tests but contain logical errors.

Training. Continued pre-training on atomic coding tasks and teacher trajectories is followed by two supervised stages with a mix of roughly 70% agentic, 15% reasoning and 15% general instruction data. Two masking rules are applied to the supervised loss:

- Error-masked training: for any assistant turn whose tool call or execution produced an error, the token loss is set to zero, so gradients come only from valid, executable turns. (That the error turn remains visible as context for later turns is our reading of "masking"; the text read did not spell it out.)
- Task-aware context masking: loss is also removed on turns whose history has been pruned or altered, so the model learns from causally relevant interactions and not from altered contexts.

The loss is normalised by the number of unmasked tokens.

Reported results are 57.40% on SWE-bench Verified and 24.72% on Terminal-Bench 2.0, self-reported.

## Key points

- Multi-stage filtering: format heuristics, LLM relevance judge, test re-execution, human spot checks.
- Passing tests does not guarantee a correct trajectory.
- Erroneous turns are kept as context but excluded from the loss.
- Turns whose context was pruned are excluded from the loss.
- Agentic data is mixed with reasoning and general data (70/15/15).

## Relevance to JacKnife

(Our interpretation.)

- Error masking resolves the question of how to include recovery examples: keep the failed call and its error in the input, set loss to zero on the failed assistant turn, train on the fix. The model sees how to recover without being taught to make the mistake.
- Context masking matters for folding. If a training turn's reasoning depends on content that the fold removed, either render that turn with the content unfolded (and an explicit `unfold` call before it) or mask its loss. Otherwise the model is trained to produce conclusions from evidence it cannot see.
- Normalise loss by unmasked tokens so heavily masked trajectories are not under-weighted.
- Add a cheap structural filter (valid tool-call syntax, allowed tool for the state) before any LLM or test-based filter.
