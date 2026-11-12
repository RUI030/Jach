# RouteLLM: Learning to Route LLMs with Preference Data

- **Source:** https://arxiv.org/html/2406.18665
- **Authors / org:** Isaac Ong, Amjad Almahairi, Vincent Wu, Wei-Lin Chiang, Tianhao Wu, Joseph E. Gonzalez, M Waleed Kadous, Ion Stoica (UC Berkeley, Anyscale, Canva)
- **Date:** June 2024 (v4 dated 23 Feb 2025)
- **Type:** paper
- **Read:** full text

## Summary

RouteLLM decides, before any model runs, whether a query goes to a strong model or a weak one. A router predicts the probability that the strong model would give the better answer; if it is below a threshold the weak model is used. The threshold is the single knob trading cost for quality.

Four routers are trained: similarity-weighted ranking over embeddings (no training), matrix factorisation, a BERT classifier, and a fine-tuned Llama 3 8B classifier. Training data is about 65k human pairwise preferences from Chatbot Arena, with models grouped into tiers. Arena data alone was not enough: routers trained only on it were near random on MMLU. Adding in-distribution labels fixed this. Roughly 1,500 MMLU validation questions with correctness labels, or about 120k queries labelled by a GPT-4 judge (around $700), raised performance substantially.

Results are reported as the share of strong-model calls needed to recover a given fraction of the quality gap. On MT Bench the best router achieved about 95% of GPT-4 quality with a 3.66x cost reduction. On MMLU and GSM8K the reductions were much smaller (1.41x at 92% quality and 1.49x at 87%). The routers transferred to unseen pairs (Claude 3 Opus/Sonnet, Llama 3.1 70B/8B) without retraining. Router overhead is small: matrix factorisation handles 155 requests per second at about $3 per million requests.

Stated limitations: only two-model routing, benchmark distributions may not match real use, and no single router wins everywhere.

## Key points

- Routing is predictive (before the weak model runs), unlike a cascade, which judges the weak model's answer.
- One threshold controls the cost/quality trade-off.
- A small amount of in-distribution labelled data matters more than a large amount of generic preference data.
- Gains range from 3.66x (chat) to about 1.4x (MMLU, GSM8K): benefit depends on how separable easy and hard queries are.
- Routers transfer across strong/weak pairs.

## Relevance to JacKnife

(Our interpretation, not the source's claims.)

- Predictive routing could apply at the task level: before the small model starts a task, estimate whether it is likely to fail and send the task (or just its plan) to the admin directly.
- The data lesson applies: a router for Jac tasks needs labels from Jac tasks. Our run logs (task features, pass/fail by the small model) are that data; a generic router will not transfer.
- With few labelled runs, the similarity-weighted approach (nearest past tasks, no training) is the realistic first version.
- Expect modest savings; on harder reasoning-style workloads the paper's gains were under 1.5x.
