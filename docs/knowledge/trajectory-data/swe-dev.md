# Scaling Unverified Teacher Trajectories, and Filtering Without Tests

A method note based on SWE-Dev [1].

- **Evidence:** B. Controlled comparisons with public code, models and data; preprint; one teacher, one scaffold, most comparisons given only in figures.
- **Numbers checked against the source:** yes, 2026-11-11, against the arXiv HTML (v2).

## 1. Problem

Most real pull requests have no tests that check a fix, so most teacher trajectories cannot be verified by execution. The paper asks whether such unverified trajectories are still useful training data, how to filter them, how they compare with test-verified data and offline RL, and how many interaction rounds to allow at inference. [1, §1, §3]

## 2. Method

**Tasks.** 240k PyPI packages narrow to 10,416 downloaded repositories and 88k extracted instances. Rule-based filtering keeps 38k instances from 4,413 repositories. [1, §3.1]

**Tests.** An LLM pipeline writes tests in four steps: extract code context, write Gherkin-style behaviour scenarios, generate tests from the scenarios, and optionally revise them. From 26k instances this gave 2,097 fail-to-pass test functions. With existing tests the total was 4,630. The authors attribute most failures to environment problems. [1, §3.2]

**Trajectories.** DeepSeek-V3 in OpenHands (30 iterations, 32k tokens) produced about 17k unevaluated trajectories and 2.3k test-verified correct ones. [1, §4.1]

**Filter without tests.** Llama-3.1-70B compares each final patch with the reference patch and grades it identical, mostly identical, partially identical or different. Only the first two grades are kept, about 65% of trajectories. [1, §5.1]

### Key decisions

1. **Use unverified trajectories at scale**, since verified ones are scarce. [1, §5.1]
2. **Split test generation into stages.** Merging the first three steps gave "irrelevant or incoherent" tests. [1, §3.2]
3. **Compare against offline RL.** KTO and OREO used DeepSeek-V3 positives and negatives from DeepSeek-V3 and the student. [1, §4.3]

### Implementation details that generalise

- Splitting roles across models helped test synthesis: Llama-3.1-70B wrote the descriptions and Qwen-2.5-Coder-32B wrote the code. This gave 92 instances with fail-to-pass tests, against 73-83 for any single model. [1, §3.3, Table 1]
- Trajectories that did not finish within the iteration limit were removed before scaling. [1, §5.1]

## 3. Evidence

SWE-bench Verified, Qwen2.5-Coder base models.

- **Headline:** 23.4% (7B) and 36.6% (32B). [1, Abstract, §4.2]
- **Unverified data scales.** 7B resolve rose roughly linearly in log data size, from 13.0% at 574 trajectories to 22.8% at 16,639. The 32B model gained more from added data (figure only). [1, §5.1, Fig. 6]
- **The patch-similarity filter costs nothing measurable.** Keeping 65% gave "nearly identical" performance to the unfiltered set (figure only). [1, §5.1, Fig. 6]
- **Verified data is worth more per trajectory.** Rejection sampling on test-verified trajectories reached 16.2% with 1,000 and 18.0% with 2,000, "surpassing" a larger unfiltered set. [1, §4.3, Fig. 4] With all 2,300 verified trajectories, RFT reached 21.2%. [1, §4.3, Fig. 5]
- **Offline RL lost to plain fine-tuning.** KTO reached 17.2% and OREO 17.0% with 1,800 trajectories. Every RFT+OREO split was below RFT alone. [1, §4.3, Figs. 4-5]
- **Prompt filtering** (unevaluated trajectories): kept prompts 15.4%, discarded prompts 12.4%, SWE-Gym 13.8%, Nebius SWE-bench-extra 15.0%. [1, §3.3, Table 2]
- **Interaction rounds.** 32B went from 34.0% at 30 rounds to 36.6% at 75; the gain from 30 to 45 was much larger than from 45 to 75 (figure only). [1, §5.2, Fig. 7]
- **Longer RoPE context** (32k → 160k) lowered 7B from 22.8% to 21.8%; 32B showed no significant decline. [1, §5.2]

## 4. Evidence boundaries

- **The 16k-trajectory curve is unverified data.** It shows that more unfiltered teacher runs help a 7B model. It does not show how many verified trajectories a small model can use.
- **The model used in the RFT and offline-RL comparisons is not named** in the text read. No error bars are reported anywhere.
- **The offline-RL negatives were partly on-policy.** The authors suggest these on-policy negatives added noise. [1, §4.3]
- **The test pipeline's yield is low:** 2,097 fail-to-pass functions from 26k instances.
- **One teacher, one scaffold**, Python only.

## 5. What we take from it

Our interpretation, not the paper's claims.

- For Jac tasks without runnable tests, a diff-similarity judgement against a reference solution is a usable second-tier filter. Such trajectories should be tagged lower confidence.
- Verified trajectories gave more per example than unverified ones. Unverified ones still added value at volume. A mix with the verified set trained last fits both results (compare [devstral.md](devstral.md)).
- Plain fine-tuning on good trajectories beat offline RL with mixed negatives. This fits the negative-data results in [learning-from-failure-nat.md](learning-from-failure-nat.md).
- Behaviour-scenario descriptions between requirement and test resemble our task acceptance criteria and could be generated the same way.

## Reference

[1] Haoran Wang, Zhenyu Hou, Yao Wei, Jie Tang, Yuxiao Dong (Tsinghua University; Zhipu AI). *SWE-Dev: Building Software Engineering Agents with Training and Inference Scaling.* arXiv:2506.07636 (v2). <https://arxiv.org/html/2506.07636>. Code: <https://github.com/THUDM/SWE-Dev>. Accessed 2026-11-11.
