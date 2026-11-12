# Training on the States the Learner Itself Reaches (DAgger)

A method note based on the original DAgger paper [1].

- **Evidence:** A for the core claim. Peer-reviewed (AISTATS 2011), theory plus controlled experiments on three tasks, one on a public dataset; no LLMs, small linear learners.
- **Numbers checked against the source:** yes, 2026-11-11, against the arXiv v3 PDF (full text via `pdftotext`).

## 1. Problem

A policy trained on expert demonstrations sees only the states the expert visits. Once the learner makes one mistake it reaches states the expert never produced, makes further mistakes there, and errors compound. The paper states the cost: a learner with error rate ε on the expert's state distribution can make up to T²ε mistakes over T steps on its own distribution. [1, §1, §2] Earlier fixes either trained one policy per time step or a stochastic mixture of policies, and needed many iterations. [1, §1]

## 2. Method

DAgger (Dataset Aggregation) is an iterative loop. [1, §3, Algorithm 3.1]

1. Run a mixed policy πᵢ = βᵢπ* + (1 − βᵢ)π̂ᵢ, where π* is the expert and π̂ᵢ the current learner.
2. For every state visited, record the expert's action as the label.
3. Add these (state, expert action) pairs to one growing dataset.
4. Train the next learner on the whole aggregated dataset.
5. Repeat; return the best learner on validation.

### Key decisions

1. **Label the learner's states, not the expert's.** The expert is asked "what would you do here?" in states the learner reached, including bad ones. This is what teaches recovery.
2. **Aggregate, do not replace.** Each learner is trained on all data so far. The paper frames this as Follow-The-Leader, a no-regret online learner. [1, §3]
3. **Mixing is optional.** βᵢ lets the expert act part of the time during collection. The only requirement is that the average of βᵢ goes to 0. The parameter-free version uses the expert only in iteration 1 (βᵢ = 1 for i = 1, else 0), which the authors say "often performs best in practice". [1, §3]
4. **One stationary deterministic policy** comes out, unlike the earlier mixture methods. [1, §1]

### Implementation details that generalise

- Early learners make many mistakes and may visit states that stop mattering once the learner improves; letting the expert act part of the time reduces that waste. [1, §3]
- Selecting the final policy on validation is part of the algorithm, not an afterthought. [1, Algorithm 3.1]
- The guarantee is that mistakes grow linearly in T rather than quadratically, for a strongly convex surrogate loss. [1, §1, §4]

## 3. Evidence

All experiments run 20 iterations; the Kart and Mario figures show 95% confidence intervals. [1, §5]

| Task | Baseline (train on expert data only) | DAgger |
|---|---|---|
| Super Tux Kart steering, falls per lap | Does not improve as data grows | No falls after 15 iterations; almost none after 5 [1, §5.1, Fig. 2] |
| Super Mario Bros., distance per stage (max about 4,300) | Stagnates; Mario gets stuck against obstacles | Best: 3,030 with βᵢ = 0.5^(i−1); 2,980 with the parameter-free version [1, §5.2, Fig. 4] |
| Handwriting recognition, character accuracy | 82% (no structure), 83.6% (supervised with true previous character) | 85.5% [1, §5.3, Fig. 5] |

- On Mario the authors explain the supervised failure directly: the expert always jumps early, so the learner never saw how to get unstuck when it was right next to an obstacle. [1, §5.2]
- A large β late in training (βᵢ = 0.9^(i−1)) converged much more slowly. [1, §5.2]
- Some expert help in later iterations beat the parameter-free version on Mario. The paper's explanation: with the indicator schedule, early data contained many samples of Mario stuck in one place. [1, §5.2]
- On handwriting, SEARN with pure policy iteration did about as well as DAgger. [1, §5.3]

## 4. Evidence boundaries

- Learners are linear models and SVMs; experts are a human driver (Kart) and a planner with full game state (Mario). Nothing involves language models or tool use.
- The expert is queried at every visited state. A pipeline that calls a strong model only when the learner is stuck labels a small, biased subset of states; the guarantee does not cover that.
- Results are on three tasks, with no comparison of data cost against expert cost.
- The no-regret argument assumes retraining on the full aggregate each round. A single round of fine-tuning on logged corrections is not DAgger in this sense.

## 5. What we take from it

Our interpretation, not the paper's claims.

- Our model's behaviour after a syntax error matches the Mario case: if training data never contains "I am in a broken state, here is the fix", the model does not learn to recover. Only 10 of 2,082 of our training replies show such a fix.
- Each admin intervention, logged with the full state the small model was in and the admin's action in our tool-call format, is a DAgger-style labelled pair. Logging should be training-ready from the first run.
- Plan for iteration (collect, fine-tune, redeploy, collect again) and keep a validation set to pick the best round.
- The two LLM-agent adaptations in this folder (`dagger-llm-agents.md`, `on-policy-expert-corrections.md`) show which of these assumptions survive at 4B to 32B.

## Reference

[1] Stéphane Ross, Geoffrey J. Gordon, J. Andrew Bagnell (Carnegie Mellon University). *A Reduction of Imitation Learning and Structured Prediction to No-Regret Online Learning.* AISTATS 2011. arXiv:1011.0686v3. <https://arxiv.org/pdf/1011.0686>. Accessed 2026-11-11.
