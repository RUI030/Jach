# AutoMix: Automatically Mixing Language Models

- **Source:** https://arxiv.org/html/2310.12963
- **Authors / org:** Pranjal Aggarwal, Aman Madaan, Ankit Anand, and 10 others (CMU, Google, Google DeepMind, IIT Delhi, USC, xAI)
- **Date:** October 2023 (v5 revised 19 Jan 2025)
- **Type:** paper
- **Read:** first ~100k characters of the HTML (main text and most appendices; the final ~14k characters were not read)

## Summary

AutoMix is a cascade that needs no trained verifier and only black-box access. The small model answers; the same small model is then asked, with a few-shot prompt, whether its answer is supported by the provided context. That check is sampled several times at high temperature, and the fraction of "correct" votes is used as a confidence estimate. A router then decides whether to keep the answer or call the large model.

Because self-verification is noisy, the router is treated as a "meta-verifier". The simple version is a threshold on the vote fraction. The stronger version is a POMDP that treats the vote fraction as a noisy observation of hidden question difficulty and optimises performance minus weighted cost; it can be fitted from about 50 labelled examples and adds under 1 ms per query.

Experiments pair mistral-7b, llama2-13b or gpt-3.5 with gpt-4 on five context-grounded tasks (qasper, quality, coqa, mutual, diplomat). The headline is more than 50% lower cost at comparable quality. Measured by incremental benefit per unit cost relative to always using the large model, the POMDP router was positive in all 15 configurations, while FrugalGPT-style and HybridLLM baselines were negative in several.

The authors report where it breaks. Verifier confidence was poorly related to correctness on two of five datasets (quality and qasper). In a three-model setup, the middle model's self-verification was sometimes uninformative. The method is designed for tasks where the answer can be checked against supplied context, and the authors say it is not suited to factual or commonsense questions without context.

## Key points

- Self-verification by the small model, sampled k times, gives a usable but noisy confidence.
- A learned router over that noisy signal beats a fixed threshold and needs only ~50 examples.
- Verification is framed as entailment against given context, not as "are you sure?".
- Calibration failed on 2 of 5 datasets.
- Gains grow with the cost ratio between models.

## Relevance to JacKnife

(Our interpretation, not the source's claims.)

- For code, the equivalent of "context-grounded verification" is execution: checker output and acceptance tests are stronger evidence than asking the 9B model to judge its own work. Self-verification should be at most a secondary signal.
- The meta-verifier idea still applies: treat each signal (checker pass, repeated call count, steps used) as noisy and learn the escalation rule from a small set of labelled runs rather than hand-setting one threshold.
- About 50 labelled examples sufficed for the router here, a scale we can reach from our own logs.
- Where no grounded check exists (for instance design or planning steps), a small model's self-assessment should not gate escalation.
