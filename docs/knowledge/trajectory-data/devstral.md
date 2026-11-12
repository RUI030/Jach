# Devstral: Fine-tuning Language Models for Coding Agent Applications

- **Source:** https://arxiv.org/html/2509.25193v1
- **Authors / org:** Baptiste Rozière, Graham Neubig, Gauthier Guinet, Guillaume Lample, Joachim Studnia, Kush Jain, Luyu Gao, Siddharth Gandhi, Wen-Ding Li, Xingyao Wang and contributors (Mistral AI, All Hands AI)
- **Date:** 2025 (arXiv 2509.25193v1; the page carries an August 2025 date stamp)
- **Type:** paper (technical report)
- **Read:** full text

## Summary

The report describes Devstral-Small, a 24B model fine-tuned from Mistral Small 3 for use inside coding-agent scaffolds, with a 128k context. It is short on quantities: it gives no trajectory counts, filter thresholds or hyperparameters. What it does describe is the shape of the training process.

Trajectories are produced by running an agent in the OpenHands CodeAct scaffold on SWE-Gym environments, with the model alternating between reasoning and actions. Final patches are checked by running unit tests. Training is staged. First the model is trained on a larger pool of rollouts that pass a heuristic quality filter. Then it is fine-tuned only on trajectories that pass the strictest filters. After that, more rollouts are generated with the fine-tuned model and used for a further "policy optimization" step whose algorithm is not specified. General natural-language data is mixed in to preserve ordinary language ability.

A later version (Devstral-Small-2507) refined data generation and filtering, added "pseudo-scaffolds", and trained on both an XML prompt format and native function calling. The authors attribute the improvement mainly to data quality.

Evaluation uses OpenHands at a pinned commit with only bash and file-edit tools. To cope with nondeterminism, each task gets up to three attempts (temperature 0, then 0.1 twice), which raised the resolve rate on SWE-bench Verified from 43.0% to 45.8% to 46.8% and reduced empty patches from 7.6% to 0%. Raising the turn limit from 30 to 50 took the rate from 36.8% to 46.8%; 100 turns gave no further gain. The authors note results depend on the scaffold version and the function-calling template.

## Key points

- Two-stage supervised training: broad, loosely filtered data first, then strictly filtered data.
- A later round uses the fine-tuned model's own rollouts.
- Training on more than one scaffold and tool-call format was introduced in the improved version.
- General-purpose data is mixed in to avoid losing language ability.
- Evaluation numbers move by several points with turn limit, retry protocol and scaffold version.
- No data volumes or filter definitions are disclosed.

## Relevance to JacKnife

(Our interpretation.)

- Staged filtering is a practical answer to "quality or quantity": use loosely filtered trajectories for a first pass, then finish on the strictly verified set.
- Devstral moved toward format diversity so the model works across scaffolds. JacKnife has the opposite goal (one harness, one format). Training on the exact JacKnife format is consistent with their observation that results depend on the template, but it will make the model brittle if the format changes; version the format and keep it stable.
- Mix in some plain Jac question-answer and code-completion data so that harness-format training does not erode the existing Jac fine-tune.
- Fix the evaluation protocol early (turn limit, retries, temperature, harness version) and record it with every result.
