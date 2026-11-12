# Predicting Before the Small Model Runs Whether the Strong One Is Needed (RouteLLM)

A method note based on the RouteLLM paper [1].

- **Evidence:** B. Controlled comparison of four routers against a random baseline on three benchmarks; preprint (v4), one benchmark (MT Bench) of only 160 questions.
- **Numbers checked against the source:** yes, 2026-11-11, against the arXiv HTML (v4, 23 February 2025).

## 1. Problem

A cascade runs the weak model first and judges its answer. A router decides before any model runs, so there is no wasted weak-model call and no verification step. Can such a router be learned from preference data, and does it transfer? [1, §1, §3.1]

## 2. Method

A router estimates P(strong model's answer wins | query). If the estimate is below a threshold α, the query goes to the weak model. α is the only knob between cost and quality. [1, §3.1]

Four routers: [1, §4.2]

- similarity-weighted ranking: a Bradley-Terry fit weighted by embedding similarity to training queries, no training;
- matrix factorisation over query embeddings;
- a BERT-base classifier;
- a Llama 3 8B classifier predicting the win label as a next token.

Training data: about 65k Chatbot Arena pairwise human preferences across 64 models, grouped into 10 tiers to reduce sparsity, optionally augmented with in-domain labels. [1, §4.1, §5]

### Key decisions

1. **Route on the query alone.** Cheaper than a cascade, but it cannot see how the weak model actually did.
2. **Measure quality as share of the gap recovered.** PGR = (router score − weak score) / (strong score − weak score); CPT(x%) is the share of strong-model calls needed to reach PGR x%. [1, §3.2]
3. **Augment with in-distribution labels.** Either about 1,500 MMLU validation questions labelled by correctness, or about 120k queries labelled by a GPT-4 judge for about $700. [1, §4.1.1]

### Implementation details that generalise

- A benchmark-dataset similarity score tracked how well a router would do: low similarity between training data and benchmark went with poor routing, and augmentation raised both. [1, §5.3, Table 5]
- Performance between routers trained on the same data "can vary widely" on the same benchmark without a clear explanation, so router choice must be validated per workload. [1, §6]

## 3. Evidence

Strong model gpt-4-1106-preview, weak model Mixtral 8x7B; baseline is a random router under the same call budget. [1, §5]

MT Bench (160 questions), trained on Arena plus judge labels: [1, §5.1, Table 1]

| Router | CPT(50%) | CPT(80%) | APGR |
|---|---|---|---|
| Random (95% CI) | 49.03% (±4) | 78.08% (±3) | 0.500 (±0.02) |
| Matrix factorisation | 13.40% | 31.31% | 0.802 |
| BERT | 19.58% | 34.02% | 0.751 |
| SW ranking | 23.21% | 36.04% | 0.759 |
| Llama 3 8B classifier | 31.50% | 48.75% | 0.679 |

- Trained on Arena data alone, all routers were near random on MMLU and GSM8K; in-domain augmentation fixed this. [1, §5.1, Tables 2, 3]
- Cost-saving ratio of the best router, at CPT(50%): MT Bench 3.66× (95% of GPT-4's score), MMLU 1.41× (92%), GSM8K 1.49× (87%). At CPT(80%): 2.49×, 1.14×, 1.27×. [1, §5.4, Table 6]
- These ratios are computed against the random router's GPT-4 call count, not against always calling GPT-4. [1, §5.4]
- Routers transferred without retraining to Claude 3 Opus/Sonnet and Llama 3.1 70B/8B on MT Bench. [1, §5.2, Table 4]
- Overhead: matrix factorisation handled about 155 requests per second at $3.32 per million requests; the most expensive router added no more than 0.4% to GPT-4 generation cost. [1, §5.5, Table 7]

## 4. Evidence boundaries

- Two-model routing only; the authors list multi-model routing as future work. [1, §6]
- Single-turn queries. The cost model assumes short prompts (95 input, 264 output tokens on average). [1, App. D]
- MT Bench has 160 questions; the random baseline's CI is ±4 points of CPT, so small router differences are not resolved.
- The judge-augmented data and MT Bench both use GPT-4 as judge.
- The largest savings are on chat; on knowledge and maths benchmarks they are below 1.5×.

## 5. What we take from it

Our interpretation, not the paper's claims.

- Predictive routing could act at the task level: before the small model starts a task, estimate from the task spec whether it will fail, and send the task (or only its planning) to the admin.
- A router for Jac tasks needs Jac labels. Our run logs (task features, pass/fail by the small model) are that data; generic preference data did not transfer even between public benchmarks.
- With few labelled runs, the no-training similarity approach (nearest past tasks) is the realistic first version.
- Expect modest gains on hard workloads. Because a router cannot see the attempt, it complements, not replaces, mid-task triggers from the checker and loop detector.

## Reference

[1] Isaac Ong, Amjad Almahairi, Vincent Wu, Wei-Lin Chiang, Tianhao Wu, Joseph E. Gonzalez, M Waleed Kadous, Ion Stoica (UC Berkeley, Anyscale, Canva). *RouteLLM: Learning to Route LLMs with Preference Data.* arXiv:2406.18665v4. <https://arxiv.org/html/2406.18665>. Accessed 2026-11-11.
