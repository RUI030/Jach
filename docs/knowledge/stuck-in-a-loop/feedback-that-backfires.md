# Feedback That Backfires: Why Small Language Model Agents Repeat the Call They Just Watched Fail

- **Source:** https://arxiv.org/html/2608.23651
- **Authors / org:** Esmail Gumaan (University of Passau)
- **Date:** 24 August 2026
- **Type:** paper
- **Read:** first ~100k characters of the HTML (main text and part of the appendices; the final ~60k characters were not read)

## Summary

Harnesses normally append a failed tool call and its error to the transcript and assume this discourages a repeat. The paper measures the opposite for small models. It defines a corrective gain: the change in log-probability of re-emitting the failed call once the failure is in context. Across six models from 135M to 1.7B parameters (SmolLM2, Qwen2.5, Qwen3, Llama-3.2) and two environments (a 12-tool office simulator and MBPP program repair), the gain is negative on 90-100% of items. The normalised probability of repeating, over a four-action candidate set, rises from about 0.06 before the failure to about 0.54 after. Under greedy decoding the exact failed call is reproduced on 19% of items.

A decomposition attributes about 83% of the effect to surface form: the failed call's tokens are in context and get copied. The error message content hardly matters; terse versus verbose wording changes little, echoing the failed call inside the error makes it worse, and repeated failures compound. An explicit "do not repeat" instruction has no measurable effect on the repeat probability.

In rollouts with Qwen2.5-0.5B on 24 tasks, the standard verbatim harness had a 31% exact-repeat rate. Replacing the verbatim call with a runtime-generated abstract description cut it to 16%; banning previously failed strings at decode time cut it to 8%; both together gave 7% and loops fell from 29% to 4%. Deleting the failed step and retrying from a clean context was worst (80% repeats), since a deterministic policy in the same state does the same thing. None of the repetition fixes raised task success in this small test.

The authors caution that the models are very small, the rollout sample is one model and 24 tasks, and a fitted trend suggesting the effect vanishes near tens of billions of parameters is unreliable.

## Key points

- For sub-2B models, a failed call in context raises the probability of repeating it.
- The cause is mostly copying of the call string, not misunderstanding the error.
- "Do not repeat" instructions do not reduce repetition; echoing the bad call in the error increases it.
- Removing the failed step and retrying unchanged gives the highest repeat rate.
- Abstracted failure notes plus a decode-time ban on failed strings reduce loops most.
- Less repetition did not translate into more success here.

## Relevance to JacKnife

(Our interpretation, not the source's claims.)

- This matches our observation closely: repetition after a failed edit or failed check. Our model is 9B, outside the tested range, so the size of the effect for us is unknown and should be measured.
- Error observations should describe the failure abstractly and state what a valid call looks like, rather than quoting the failed call back.
- A harness-level block on re-issuing an identical failed call (or logit ban if we control decoding) is cheap and independent of the model's cooperation.
- Rolling back to the pre-failure context and retrying at temperature 0 is a trap; a retry needs changed context (a hint, a narrowed tool set, a different sampler).
- Since stopping repetition did not raise success, loop-breaking must be paired with real help (admin hint or takeover), not treated as the fix.
