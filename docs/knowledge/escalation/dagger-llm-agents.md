# Turn-Level Teacher Mixing for Small Coding Agents (DAgger for LLM Agents)

A method note based on "Revisiting DAgger in the Era of LLM-Agents" [1].

- **Evidence:** B. Controlled comparison against four post-training baselines at two model sizes; single-group preprint, one domain, no seeds or variance reported.
- **Numbers checked against the source:** yes, 2026-11-11, against the arXiv HTML (v1).

## 1. Problem

Supervised fine-tuning (SFT) on teacher trajectories gives dense labels but only on teacher-visited states, so the student meets unfamiliar states once it errs. Reinforcement learning on the student's own rollouts avoids that mismatch but gives only a sparse pass/fail reward. The paper asks whether classic DAgger gives both: on-policy states and dense teacher labels, for multi-turn coding agents. [1, Abstract, §1]

## 2. Method

Rollouts mix student and teacher; the teacher labels every state. [1, §3.2, Algorithm 1]

- **DAgger-style (turn-level).** At iteration i each turn is executed by the teacher with probability βᵢ, otherwise by the student. βᵢ = max(0.6, 1.0 − 0.2(i − 1)): 1.0, 0.8, 0.6, 0.6, 0.6. [1, App. F.1]
- **AggreVaTe-style (trajectory-level).** The student runs a prefix of sampled length κ, then the teacher finishes. The prefix support was set from the observation that student rollouts usually end within about 40 turns, and mass shifts toward longer prefixes over training. [1, §3.2, App. F.1]
- **Labels.** Whoever acts, the teacher's action at every visited state is the training label; training is cross-entropy on the teacher's action tokens. On-policy distillation, by contrast, uses the teacher's token-level distribution through a reverse-KL loss. [1, §3.2, §4.1]
- Five collect-then-update iterations of 512 tasks each. Trajectories without a valid final patch are dropped. [1, App. F.1, F.2]

### Key decisions

1. **Label every visited state, not only the ones the teacher executed.** This is what puts teacher supervision on student-induced states.
2. **Keep the teacher dominant.** β never drops below 0.6, so at least about 60% of executed turns are teacher turns. The paper argues student-only rollouts enter "unproductive states early" (cold start). [1, §4.3]
3. **Re-render trajectories** into each model's native chat and tool template, so data from one model trains another. [1, §4.1]

### Implementation details that generalise

- Transitions sharing a prefix can be packed into one sequence with a loss mask, giving the same gradient at lower cost. [1, §3.2]
- The teacher must be queried at every turn, including student turns, so teacher inference cost scales with total turns, not with interventions. [1, §3.2, App. B]

## 3. Evidence

Students Qwen3-4B-Instruct-2507 and Qwen3-8B; teacher Qwen3-Coder-30B-A3B-Instruct; OpenHands scaffold; trained on 2,338 SWE-Gym tasks; evaluated on a 100-task SWE-Gym holdout and on 466 of 500 SWE-bench Verified tasks (34 Matplotlib tasks did not build). [1, §4.1]

| Method | 4B Holdout | 4B Verified | 8B Holdout | 8B Verified |
|---|---|---|---|---|
| Base | 5.0% | 11.2% | 2.0% | 7.7% |
| GRPO | 8.0% | 11.6% | 4.0% | 8.2% |
| SFT (rejection-sampled teacher trajectories) | 15.0% | 22.9% | 12.0% | 23.4% |
| On-policy distillation (OPD) | 16.0% | 23.4% | 16.0% | 26.2% |
| DAgger-style | 17.0% | 27.3% | 19.0% | 29.8% |
| AggreVaTe-style | 16.0% | 24.5% | 17.0% | 27.3% |

[1, §4.2, Table 3]

- The strongest baseline is OPD; DAgger-style beats it by 3.9 (4B) and 3.6 (8B) points on Verified. [1, §4.2]
- At about 3K effective samples (4B), DAgger-style reached 20% on a 100-task Verified subset against 13% for OPD. SFT peaked at 20% on that subset and dropped to 19%, while DAgger-style reached 26%. [1, §4.3, Fig. 1]
- Reverse KL from teacher on student-visited contexts: SFT fell from about 0.27 to 0.10, then rose to about 0.126; both mixture methods stayed near 0.10. [1, §4.4]
- Failure analysis (4B, LLM judge): repetitive loops were 44.3% of OPD's no-submission failures; DAgger-style submitted a patch on 97.9% of tasks, and context overflow was 57.5% of its few no-submission failures. SFT had the highest syntax or runtime error rate among trained methods (20.3%) against 15.9% for DAgger-style. [1, §4.5, Table 4]

## 4. Evidence boundaries

- No seeds, variance or confidence intervals. Holdout differences of 1 to 3 points are 1 to 3 tasks out of 100; the SFT "decline" is one task.
- The β schedule and prefix distribution are not ablated.
- SFT used 684 successful trajectories; the mixture methods use their own online batches. The scaling figure matches "effective samples", but the main table compares recipes, not equal data. [1, App. F.2]
- The teacher (Qwen3-Coder-30B-A3B) is a mid-sized model. A much larger gap between student and teacher, as with our admin, is not tested.
- One domain (software-engineering tasks), one scaffold. [1, App. B]

## 5. What we take from it

Our interpretation, not the paper's claims.

- This is the closest published setup to ours (Qwen family, 8B, coding agent, stronger teacher). It supports admin interventions as the main source of training data, but at their scale the teacher was present on every turn, which our admin is not.
- An admin that fixes one step and hands control back is closer to the turn-level variant than a full takeover is. Each handback yields more student-visited states per run.
- Offline relabelling may approximate per-state labels: replay logged small-model states through the admin afterwards.
- Once loops fall, context overflow became the dominant residual failure here; context management should be watched once our loop rate drops.

## Reference

[1] Changhao Li, Rushi Qiang, Jiawei Huang, Chenxiao Gao, Chao Zhang, Niao He, Bo Dai (Georgia Institute of Technology; ETH Zurich). *Revisiting DAgger in the Era of LLM-Agents.* arXiv:2605.12913v1, May 2026. <https://arxiv.org/html/2605.12913v1>. Accessed 2026-11-11.
