# FrugalGPT: How to Use Large Language Models While Reducing Cost and Improving Performance

- **Source:** https://arxiv.org/abs/2305.05176 (PDF: https://arxiv.org/pdf/2305.05176)
- **Authors / org:** Lingjiao Chen, Matei Zaharia, James Zou (Stanford University)
- **Date:** 9 May 2023
- **Type:** paper
- **Read:** abstract page, and pages 1-9 of the v1 PDF (introduction through the main results; later pages not read)

## Summary

The paper surveys three ways to cut LLM cost (shorter prompts, approximating an expensive model with a cache or a fine-tuned cheaper model, and cascades) and implements the third. An LLM cascade sends a query to a list of models in order of cost. After each model answers, a scoring function estimates whether the answer is reliable; if the score clears that stage's threshold the answer is returned, otherwise the next model is called.

The scorer is a small separate model: a DistilBERT regressor that takes the query and the generated answer and predicts correctness. The order of models and the per-stage thresholds are learned jointly on a training split as a budget-constrained optimisation. Experiments use 12 commercial APIs and three datasets (HEADLINES financial news classification, OVERRULING legal classification, COQA reading comprehension) with cascades of length three.

In the HEADLINES case study the learned cascade is GPT-J, then J1-Large, then GPT-4, with acceptance thresholds 0.96 and 0.37. At one fifth of GPT-4's cost it scored 0.872 accuracy against GPT-4's 0.857. To match the best single model's accuracy, the cascade cut cost by 98.3% on HEADLINES, 73.3% on OVERRULING and 59.2% on COQA. The authors explain the accuracy gain by model diversity: on HEADLINES, cheap models are right on about 6% of the queries GPT-4 gets wrong.

The tasks are single-turn with a short checkable answer. Savings are much smaller on the more open task (COQA) than on classification.

## Key points

- Cascade = cheap model first, a learned scorer decides accept or escalate, thresholds differ per stage.
- The scorer is a small supervised model over (query, answer), trained on labelled data from the target task.
- Savings of 59-98% at equal accuracy, strongly task-dependent.
- A cascade can beat the largest model because cheap models are sometimes right where it is wrong.
- Evaluated only on single-turn question answering and classification.

## Relevance to JacKnife

(Our interpretation, not the source's claims.)

- JacKnife is already a cascade: small model first, admin on failure. The paper's point is that the accept/escalate decision is the component to engineer. We have something better than a learned scorer for many steps: the Jac checker and task acceptance criteria.
- A learned "will this task attempt succeed" scorer over harness features (failed-edit count, repeated calls, steps used) could be trained later from our own run logs, as FrugalGPT trains its scorer from task data.
- The savings do not transfer directly: agent tasks are multi-turn, and escalation mid-task costs a large context read, unlike a fresh single query.
