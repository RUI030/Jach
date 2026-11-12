# The Constraint Tax: Measuring Validity-Correctness Tradeoffs in Structured Outputs for Small Language Models

- **Source:** https://arxiv.org/html/2605.26128
- **Authors / org:** Jaideep Ray (no affiliation listed)
- **Date:** 20 May 2026
- **Type:** paper
- **Read:** full text

## Summary

A single-author preprint that asks whether grammar- or schema-constrained decoding makes small models more correct, or only more valid. It defines the constraint tax as the accuracy lost when a hard output constraint is applied, with model and task held fixed, and it tracks a second metric: the rate of outputs that are schema-valid but wrong.

Models are Qwen2.5 0.5B, 1.5B and 3B and SmolLM2 1.7B, served with vLLM and SGLang. Tasks are five synthetic families (two-step arithmetic, string manipulation, object tracking, boolean logic, tool-call arguments) with 1,000 instances each, plus a calendar tool-call task scored by executing the call.

Across the sub-3B models, prompting for JSON without enforcement gave 61.5% valid output and 19.7% answer accuracy. Enforcing an answer-only schema gave 100% validity and 11.0% accuracy; valid-but-wrong outputs rose from 49.5% to 88.9%. The 3B model showed the same pattern (39.0% to 23.7%). SmolLM2 was an exception: its unconstrained baseline was weak and the constraint helped.

The tool-call experiment is the most relevant. Qwen2.5-1.5B produced 100% schema-valid calendar calls both with a JSON prompt and under schema-constrained decoding, but executable accuracy fell from 91.5% to 48.0% under the constraint. Of 104 constrained failures, 102 were a wrong value in one field (the duration), for example a 30-minute request producing 180.

In a smaller follow-up (four models, 20 examples per family, no confidence intervals), schemas with a rationale field before the answer, and "delayed" constraints (reason freely, then package under the constraint), restored accuracy while keeping validity near 100%: 36.5% and 40.7% against 26.8% for the answer-only schema.

The author's advice is to measure unconstrained JSON first, track the valid-but-wrong rate, and apply structure after the model has worked out the answer. Limitations: synthetic tasks, models at or below 3B, and backend-dependent results for one model.

## Key points

- Constrained decoding guarantees syntax and can lower correctness in small models.
- Failures move from visible (parse error) to silent (valid, wrong value).
- On one tool-call task, accuracy fell from 91.5% to 48.0% with validity at 100% in both cases.
- A rationale field first, or a free-reasoning step before the constrained step, removed most of the loss.
- Results depend on model and serving backend; no data above 3B.

## Relevance to JacKnife

(Our interpretation, not the source's claims.)

- Grammar-constrained tool calls will fix malformed calls but not wrong arguments, and may hide them. Our parameter-misuse failure needs argument validation by the harness (does the path exist, does the old string occur in the file), not only a grammar.
- Record three numbers per tool: parse-valid rate, schema-valid rate, and semantically-valid rate. Adopt constraints only if the third does not drop.
- If we use constrained decoding, apply it after a free-text reasoning span, consistent with `let-me-speak-freely-format-restrictions.md`.
- A parse error is a useful stuck signal for the harness. Constraining it away removes that signal, so replace it with semantic checks.
- Evidence is preliminary and from models much smaller than ours; test on our 9B model before deciding.
