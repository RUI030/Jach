# Cascades with a Learned Accept-or-Escalate Scorer (FrugalGPT)

A method note based on the FrugalGPT paper [1].

- **Evidence:** B. Controlled cost/accuracy comparison on three datasets with 12 APIs; preprint, single train/test split, no variance reported.
- **Numbers checked against the source:** yes, 2026-11-11, against the full arXiv v1 PDF (13 pages, via `pdftotext`).

## 1. Problem

Commercial LLM APIs differ in price by up to two orders of magnitude, and the most expensive one is not always right where cheaper ones are wrong. How can a user spend less without losing accuracy? [1, §1, §2]

## 2. Method

The paper lists three strategies (prompt adaptation, approximating an expensive model with a cache or a fine-tuned cheaper model, and the LLM cascade) and implements the third. [1, §3]

A cascade sends a query to a list of models in order. After each answer, a scoring function g(query, answer) ∈ [0, 1] estimates reliability. If the score clears that stage's threshold τᵢ the answer is returned; otherwise the next model is called. [1, §3, Strategy 3]

### Key decisions

1. **The scorer is a small separate model**, a DistilBERT regressor trained to predict whether an answer is correct from the query and the answer. It is cheaper than any of the LLMs. [1, §4, case study]
2. **Model order and per-stage thresholds are learned jointly** as a budget-constrained optimisation on a training split. It is mixed-integer and expensive, so the search prunes model lists with little answer disagreement and interpolates the objective from a few samples. [1, §3]
3. **Cascade length 3**, to keep the search small. [1, §4]

### Implementation details that generalise

- Thresholds differ by stage. In the case study the cheapest model's answer needed a score above 0.96, the second model's only above 0.37. [1, §4, Fig. 3]
- The scorer and the cascade need labelled data from the same or a similar distribution as the queries they will see; this is a one-time cost that pays off only for workloads larger than the training set. [1, §5]
- A known failure: when all models in the chain agree, the cascade may still call all of them because the scorer is unsure of the early ones. [1, §4, Fig. 5]

## 3. Evidence

Datasets: HEADLINES (gold-price direction from financial headlines, 10,000 examples), OVERRULING (legal classification, 2,400), COQA (reading comprehension recast as direct QA, 7,982). [1, §4, Table 2]

- Case study, HEADLINES: cascade GPT-J → J1-L → GPT-4 at a $6.5 budget, one fifth of GPT-4's $33.1. Accuracy 0.872 against 0.857 for GPT-4 alone. [1, §4, Fig. 3]

| Dataset | Best single model | Its cost | Cascade cost at equal accuracy | Saving |
|---|---|---|---|---|
| HEADLINES | GPT-4 | 33.1 | 0.6 | 98.3% |
| OVERRULING | GPT-4 | 9.7 | 2.6 | 73.3% |
| COQA | GPT-3 | 72.5 | 29.6 | 59.2% |

[1, §4, Table 3]

- Complementarity: on about 6% of HEADLINES queries GPT-4 is wrong while GPT-J, J1-L or GPT-C is right; on COQA, 13% of queries have GPT-4 wrong and GPT-3 right. [1, §4, Fig. 4]
- At equal cost the cascade improved accuracy by up to 5% (Fig. 5 caption); the abstract says 4%. [1, Abstract, §4, Fig. 5]
- On OVERRULING it gained 1% accuracy while cutting cost 73% against GPT-4. [1, §4]

## 4. Evidence boundaries

- Single-turn classification and short-answer QA, where correctness is cheap to judge. The scorer predicts correctness of one short answer, not progress in a multi-step task.
- One random split per dataset, no error bars. The text says savings range "from 50% to 98%", but the table's lowest is 59.2%.
- The savings are largest on the classification task with many easy items (98.3%) and smallest on the more open one (59.2%).
- The APIs and prices are from early 2023, and all models are general-purpose APIs; no small fine-tuned model sits at the bottom of the cascade.

## 5. What we take from it

Our interpretation, not the paper's claims.

- Jach is already a two-stage cascade: small model first, admin on failure. The paper's point is that the accept-or-escalate decision is the component to engineer.
- For many of our steps we have something better than a learned scorer: the Jac checker and the task's acceptance checks, which the model cannot influence.
- Where those checks are silent (planning, design), a small learned "will this attempt succeed" scorer over harness features (failed-edit count, repeated calls, steps used) could be trained later from our own run logs, as FrugalGPT trains its scorer from task data.
- The savings do not transfer: our tasks are multi-turn, and escalating mid-task costs the admin a long context read, unlike a fresh single query.

## Reference

[1] Lingjiao Chen, Matei Zaharia, James Zou (Stanford University). *FrugalGPT: How to Use Large Language Models While Reducing Cost and Improving Performance.* arXiv:2305.05176v1, May 2023. <https://arxiv.org/pdf/2305.05176>. Accessed 2026-11-11.
