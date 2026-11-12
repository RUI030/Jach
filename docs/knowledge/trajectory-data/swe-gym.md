# Training Software Engineering Agents and Verifiers with SWE-Gym

- **Source:** https://arxiv.org/html/2412.21139
- **Authors / org:** Jiayi Pan, Xingyao Wang, Graham Neubig, Navdeep Jaitly, Heng Ji, Alane Suhr, Yizhe Zhang (UC Berkeley, UIUC, CMU, Apple)
- **Date:** 2024-12 (arXiv v2 revised 2025-06)
- **Type:** paper
- **Read:** full text

## Summary

SWE-Gym is a training environment of 2,438 real Python tasks from 11 repositories, each with an executable environment, tests and an issue description. Building the environments took about 200 hours of annotation and the images total 6 TB.

Trajectories were sampled with two scaffolds: OpenHands, a general agent with free-form planning, and MoatlessTools, a constrained workflow agent. Teachers were GPT-4o and Claude 3.5 Sonnet at varied temperatures. Only trajectories that passed the tests were kept: 491 for OpenHands, averaging about 19 turns and 19,000 tokens.

Fine-tuning Qwen2.5-Coder-32B on those 491 raised its OpenHands resolve rate from 3.0% to 15.3% on SWE-bench Lite and from 7.0% to 20.6% on Verified. Fine-tuning also reduced the "stuck in loop" rate (same action three times in a row) and the rate of empty patches. Performance was still rising at 491 trajectories with no sign of saturation.

Self-improvement behaved differently by scaffold. Adding the student's own successful OpenHands trajectories and retraining made the 32B model worse (15.3% to 8.7% on Lite). With the constrained MoatlessTools workflow, iterating rejection sampling helped the 7B model (7% to 10%) and gave the 32B model a small gain before plateauing.

Repeated sampling over-represents easy tasks. Capping the number of trajectories kept per task corrected this; a cap of two matched or slightly beat using everything while training faster.

A verifier (a model trained on 2,636 balanced successful and failed trajectories to predict success) was used to pick the best of k attempts. With 16 attempts the oracle rate was 42.8% and verifier-selected rate 32.0% on Verified.

Limitations stated: only 11 repositories, expensive manual set-up, modest self-improvement.

## Key points

- A few hundred successful teacher trajectories already give a large gain to a model that starts near zero in the scaffold.
- Keep only test-passing trajectories; cap per task (two worked best) to counter easy-task bias.
- Self-generated data hurt in the open-ended scaffold and helped modestly in the constrained workflow.
- Failed trajectories are useful for training a verifier, even though they were excluded from policy training.
- Fine-tuning reduced loop and empty-patch rates.

## Relevance to JacKnife

(Our interpretation.)

- Start small: a few hundred verified JacKnife-format trajectories are enough to see whether the format is learnable before investing in thousands.
- The self-improvement result favours constrained workflows: on-policy data from a harness-owned state machine is more likely to be usable than data from a free agent loop. Still validate before mixing student trajectories into training.
- Keep the failed trajectories. They are not policy training data here, but they train a success predictor that could later gate task completion or choose among retries.
- Report loop rate and empty-output rate alongside task success when evaluating each fine-tune.
- Average trajectory length here (19k tokens) already exceeds a 16k context; training examples must be rendered through the same folding the harness applies at inference.
