# The Complexity Trap: Simple Observation Masking Is as Efficient as LLM Summarization for Agent Context Management

- **Source:** https://arxiv.org/html/2508.21433
- **Authors / org:** Tobias Lindenbauer, Igor Slinko, Ludwig Felder, Egor Bogomolov, Yaroslav Zharov (JetBrains Research, TU Munich)
- **Date:** 2025 (arXiv v3 dated 2025-10-27); workshop paper, Deep Learning for Code in the Agentic Era
- **Type:** paper
- **Read:** main text (first ~100k characters of the HTML; the tail of the appendix was not read)

## Summary

The paper asks whether LLM summarisation of agent history is worth its complexity compared with simply hiding old tool outputs. It notes that observations (file contents, listings, test logs) make up about 84% of a typical SWE-agent turn.

Three strategies are compared on SWE-bench Verified using SWE-agent with a 250-turn limit. The raw agent keeps everything. Observation masking replaces observations older than the last M=10 turns with a placeholder while keeping all reasoning and actions. LLM summarisation condenses older turns with a separate model call once N=21 turns have accumulated beyond a tail of 10 unaltered turns. Models: Qwen3-32B, Qwen3-Coder 480B and Gemini 2.5 Flash, with and without thinking.

Both strategies cut per-instance cost by roughly 41% to 57% in most settings. With Qwen3-Coder 480B, masking cut cost by 52.7% and solve rate went from 53.4% to 54.8%; summarisation cut cost by 50.4% with 53.8%. Masking was the cheapest option in four of five setups. One exception: with Gemini 2.5 Flash in thinking mode both strategies lowered solve rate (40.4% raw, 36.4% masking, 31.4% summary).

Summarisation made trajectories longer (about 15% longer than raw for Qwen3-Coder); the authors suspect that summaries encourage the agent to keep going. Summary calls added up to 7.2% of cost. A hybrid (mask first, summarise much later) on a 50-instance subset gained 2.6 points over raw and was 7% cheaper than masking, but only after tuning. On OpenHands the masking window had to be retuned to M=58 to match.

## Key points

- Hiding old observations while keeping reasoning and actions matches summarisation on solve rate in most tested settings and costs less.
- Summaries lengthen trajectories; the authors suspect they encourage the agent to continue.
- The window size is scaffold-specific (10 turns for SWE-agent, 58 for OpenHands).
- Results are not uniform: one model/mode lost solve rate with both strategies.
- Only software engineering tasks were tested, where observations are verbose.

## Relevance to JacKnife

(Our interpretation.)

- This is the strongest evidence found for the JacKnife design choice: mask or fold observations, keep the model's own reasoning and actions, skip whole-conversation summaries.
- Folding to a one-line summary sits between masking (placeholder only) and summarisation. Keep the action line verbatim and make the fold deterministic where possible (exit code, test counts, file paths), so it does not need an LLM call.
- The number of recent turns kept unfolded must be tuned for this harness and model; do not copy 10.
- Track trajectory length as a metric when changing fold rules; a rule that hides failure signals may make runs longer.
