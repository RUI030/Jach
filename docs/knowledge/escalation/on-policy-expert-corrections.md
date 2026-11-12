# Imitation Learning for Multi-turn LM Agents via On-policy Expert Corrections (OEC)

- **Source:** https://arxiv.org/html/2512.14895v1
- **Authors / org:** Niklas Lauffer (UC Berkeley, work done at Scale AI), Xiang Deng, Srivatsa Kundurthy, Brad Kenstler, Jeff Da (Scale AI)
- **Date:** 16 December 2025
- **Type:** paper
- **Read:** first ~100k characters of the HTML (main text and most appendices; the final ~10k characters were not read). Some ablation numbers exist only in figures.

## Summary

The paper adapts DAgger to coding agents. Students are Qwen2.5-Coder 7B and 32B, already fine-tuned on Claude 3.7 Sonnet trajectories in the SWE-agent scaffold. The authors first show the problem: comparing embeddings of student and expert histories turn by turn, the distributions diverge sharply between about turn 10 and turn 30 and keep diverging, even after behaviour cloning.

The method: the student starts a SWE-smith task and runs for a number of turns drawn uniformly from 0 to 30. The expert then takes over from that state and finishes. The history is reformatted for the expert, which is not told another model produced it. Only trajectories whose final patch passes the unit tests are kept. Training loss is applied only to the expert's part; the student's prefix is context but is masked out. Trajectories with the same action three times in a row, or 20 or more consecutive file reads, are discarded.

Results on SWE-bench Verified: the 7B model reached 20.8% against 15.2% for the comparable SWE-smith 7B model; the 32B model reached 40.0% against 36.4% for the authors' re-evaluation of SWE-smith 32B (reported elsewhere as 40.2%). The abstract states 14% and 13% relative gains over standard imitation learning.

Ablations carry the practical lessons. Fine-tuning on the student's own successful trajectories did little at 7B and clearly hurt at 32B; the authors partly blame loops that still pass tests. Without the repetition filter the 7B model fell from 17% to 11% on SWE-bench Lite, below its untrained 13.3%. Without masking the student prefix, the 32B model lost almost all the gain (31.8% against 40.0%). Later switch points gave slightly better data than early ones. The best mix combined correction trajectories with ordinary expert trajectories.

## Key points

- Student rolls out, expert takes over mid-task, train only on the expert's continuation.
- Passing tests is not a sufficient data filter; repetitive trajectories must be removed explicitly.
- Do not train on the student's own actions, even from successful runs.
- Mix correction data with pure expert data.
- Gains: about +5 points at 7B, +3.6 at 32B on SWE-bench Verified.
- Single domain, single round of data collection (not iterated).

## Relevance to JacKnife

(Our interpretation, not the source's claims.)

- An admin takeover in JacKnife produces exactly this data shape: small-model prefix, then expert continuation. It can be logged and used for fine-tuning without extra expert calls.
- Training-data rules to adopt: mask the small model's prefix in the loss; keep only tasks that end with acceptance criteria met; drop any trajectory containing repeated identical actions.
- The 7B ablation is a warning for our scale: unfiltered repetitive data made the model worse than no training.
- Their expert is not told it is taking over. Our admin is called because the small model is stuck, so its first action may be explicit recovery; that should make our data richer in recovery examples than theirs, but this is untested.
