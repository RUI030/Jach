# Context Rot: How Increasing Input Tokens Impacts LLM Performance

- **Source:** https://www.trychroma.com/research/context-rot (redirected from https://research.trychroma.com/context-rot)
- **Authors / org:** Kelly Hong, Anton Troynikov, Jeff Huber (Chroma)
- **Date:** 2025-07-14
- **Type:** engineering blog (technical report)
- **Read:** full text

## Summary

A controlled study of 18 models (GPT-4.1, Claude 4, Gemini 2.5, Qwen3 families and others) showing that output quality falls as input length grows, even on tasks that stay equally easy. The tasks are deliberately simple so that length is the main variable.

Needle-in-haystack variants: when the question and the needle are semantically less similar, accuracy falls faster with length. Needle position had no notable effect. Adding one topically related distractor lowered accuracy and four lowered it further; distractors were not equally harmful, and some appeared repeatedly in wrong answers. Claude models tended to abstain when unsure; GPT models hallucinated most. Unexpectedly, haystacks with sentences shuffled into random order gave better retrieval than coherent essays across all models; the authors do not explain why.

On LongMemEval, 306 questions were asked with the full history (about 113k tokens) and with only the relevant part (about 300 tokens). Every model scored higher on the focused version, and thinking modes narrowed but did not close the gap.

In a repeated-words task (copy a sequence of repeated words containing one different word, up to 10,000 words), performance degraded with length across all model families. Qwen3-8B skipped about 4.21% of tasks, and some models began emitting random words at a few hundred words.

Caveats stated by the authors: the mechanisms are not explained, the haystack topics were limited, refusals were excluded from scoring, and an LLM judge was used (calibrated to over 99% agreement with human labels). The authors expect degradation on real tasks to be at least as large, but do not show it.

## Key points

- Models do not use their context uniformly; reliability declines with length on every model tested.
- Related-but-wrong content (distractors) hurts more as context grows.
- The same question answered from ~300 focused tokens beats the same question answered from ~113k tokens.
- Low lexical or semantic overlap between query and target makes long-context retrieval worse.
- A small Qwen model (Qwen3-8B) is in the test set and shows the degradation.

## Relevance to JacKnife

(Our interpretation.)

- Supports treating the usable budget as far smaller than the 262k hard limit, independently of the 16k training limit.
- Old tool outputs from superseded attempts are distractors: similar to the current state but wrong. Folding them is not only a token saving; it removes misleading near-duplicates (old file versions, old test output).
- Fold lines should reuse the vocabulary the model will later look for (file paths, test names, error class) so that the model can match its need to the right id.
- Long verbatim copying is itself unreliable in small models; edits should be diff- or range-based, not whole-file rewrites.
