# A Reduction of Imitation Learning and Structured Prediction to No-Regret Online Learning (DAgger)

- **Source:** https://arxiv.org/abs/1011.0686
- **Authors / org:** Stéphane Ross, Geoffrey J. Gordon, J. Andrew Bagnell
- **Date:** 2 November 2010 (v3 16 March 2011); AISTATS 2011
- **Type:** paper
- **Read:** abstract only

## Summary

This is the paper that introduced the algorithm later known as DAgger (dataset aggregation). Only the abstract was read for this note, so the description of the algorithm itself is limited to what the abstract states; the algorithmic details used below come from the two LLM-agent papers in this folder that restate it (`dagger-llm-agents.md`, `on-policy-expert-corrections.md`).

The abstract sets out the problem. In sequential prediction, including imitation learning, the learner's own earlier predictions determine what it observes next. Training data collected from an expert therefore does not match the distribution of situations the learner meets when it acts by itself, which breaks the independence assumption of standard supervised learning and leads to poor performance in theory and in practice. Earlier remedies trained non-stationary or stochastic policies and needed many iterations.

The paper proposes an iterative algorithm that trains a single stationary deterministic policy and can be analysed as a no-regret online learning algorithm. The stated guarantee is that any no-regret learner used this way must find a policy that performs well under the distribution of observations that the policy itself induces. The abstract reports that the method outperformed earlier approaches on two imitation learning problems and a sequence labelling benchmark; it gives no numbers.

As restated by the later papers we read: the loop is to run the current learner, have the expert label the states the learner actually visited, add those labelled states to the dataset, retrain, and repeat.

## Key points

- Names the core problem: a policy trained only on expert trajectories never sees the states its own mistakes lead to.
- Fix: collect expert labels on learner-visited states, aggregate, retrain, iterate.
- Produces one stationary policy, with a no-regret guarantee on its own state distribution.
- Abstract-level claims only; no numbers were available in what we read.

## Relevance to JacKnife

(Our interpretation, not the source's claims.)

- Our model's loop after a failed edit is a textbook case: if training trajectories came from a strong model that rarely fails edits, the 9B model has seen few "what to do after a failure" states.
- The admin mechanism is an expert labelling learner-visited states. Every admin intervention is a (state the small model reached, expert action) pair of exactly the kind DAgger aggregates.
- Therefore log admin interventions in a training-ready format from day one: full context at the point of intervention, and the admin's action in the small model's tool-call format.
- Read the LLM-agent adaptations before designing the data loop; the original guarantee assumes conditions (expert labels at every visited state, iterated retraining) that a real pipeline only approximates.
