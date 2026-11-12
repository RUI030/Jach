# Trajectory data

How training data for agentic fine-tuning is built: making tasks with executable checks, collecting teacher trajectories, deciding which to keep, what to do with failures and error turns, how to format targets and mask the loss, and how to evaluate the result. Most sources are SWE-bench-style Python work with students from 7B to 32B. None trains a model near 9B inside a harness that owns the workflow, so every transfer to JacKnife is an inference. All notes were checked against the source text on 2026-11-11.

| Note | Grade | One-line takeaway |
|---|---|---|
| [swe-smith.md](swe-smith.md) | B | Bugs injected into shared per-repository environments; 5k trajectories took a 32B student to 40.2%, but it repeats actions far more than its teacher and scaffold nudges did not help. |
| [swe-gym.md](swe-gym.md) | B | 491 teacher trajectories lift 7B-32B from near zero; student-generated data hurt in a free scaffold and helped slightly in a fixed workflow. |
| [r2e-gym.md](r2e-gym.md) | B | Tasks mined from commits train as well as real issues; thoughts in the targets add 4 points; trajectory-reading verifiers can be fooled. |
| [trajectory-curation-lora.md](trajectory-curation-lora.md) | B | For a 7B LoRA, doubling data beats quality ranking up to 1,000 trajectories; a rare tool-call format was never learned. |
| [agent-flan.md](agent-flan.md) | B | Align targets with the chat template, weight slow-learned skills, and add "do not call a tool" examples. |
| [learning-from-failure-nat.md](learning-from-failure-nat.md) | B | Tagged failures from a strong teacher help when positives are scarce; a weak model's failures hurt; negatives raise tool errors. |
