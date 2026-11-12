# Error-Masked and Context-Masked Loss for Agent Trajectories

A method note based on the ROME technical report [1].

- **Evidence:** D. Industry technical report. The masking rules are described and given as a formula, but no ablation measures their effect; benchmark results are self-reported.
- **Numbers checked against the source:** partly. Checked 2026-11-11 against the arXiv HTML (v3), covering the abstract, §3.1-3.2 (data and supervised training) and the headline results in §3.3. The reinforcement-learning sections (§3.2.4) and the benchmark tables beyond the headline rows were not checked.

## 1. Problem

Agent trajectories contain turns where a tool call or its execution failed: type mismatches, timeouts, syntax errors. Standard supervised fine-tuning puts loss on every assistant token, so it also teaches the failed calls. Harnesses also rewrite history (summaries, truncation, pruned tool output), so some turns were produced from a context the training example no longer shows. [1, §3.2.2.2-3]

## 2. Method

ROME is a Qwen3-MoE model (30B total, 3B active) trained by continued pre-training, two supervised stages and RL. [1, §1, Table 1] This note covers the supervised loss.

The supervised loss is a masked maximum-likelihood objective, normalised by the number of unmasked tokens. [1, §3.2.2.4, Eqs. 1-2]

- Each assistant turn *k* is predicted from the state *s_k*, which includes history and tool outputs.
- A per-turn mask *m_k* = *m_k^err* · *m_k^task* decides which turns carry loss.
- *m_k^err* is 0 if the turn triggered a tool-call or execution failure, as recorded in runtime logs (error-masked training).
- *m_k^task* is 0 if the turn is redundant, highly similar to another, or belongs to pruned history, judged by pattern heuristics such as tool-call triggers and loop-entry markers (task-aware context masking).

### Key decisions

1. **Mask by turn, using the environment's own error log.** No model judgement is needed to find failed turns. [1, §3.2.2.2]
2. **Mask turns whose context was altered.** Loss is removed where summarisation, truncation or pruning changed what the turn was conditioned on. [1, §3.2.2.3]
3. **Normalise by unmasked tokens,** so heavily masked trajectories are not down-weighted. [1, Eq. 1]

### Implementation details that generalise

The filtering pipeline around the masked loss: [1, §3.1.3.3, §3.2.2.1]

- **Four filter stages:** rule checks for malformed tool calls; an LLM judge of whether the trajectory addresses the task; re-execution of tests; human audit of borderline cases.
- **Supervised-data filters** remove repeated tool-call sequences, truncated runs and trajectories "trapped in self-repair loops", and flag "fake positives".
- **A later supervised stage** re-trains on a stricter subset: execution-verified traces, engineer-reviewed demonstrations (debugging, failure recovery, minimal changes), and candidates ranked by rules (syntax validity, loop detection) plus an LLM judge.

## 3. Evidence

- **Data scale:** the coding pipeline produced 76K instances and trajectory records totalling 30B tokens. The model was trained on over a million trajectories overall. [1, §3.1.3.2, Abstract]
- **Supervised mix:** about 70% agentic, 15% reasoning and 15% general instructions, across about 15 languages. [1, §3.2.2.1]
- **Data findings, stated without numbers** from what the authors call a systematic ablation: [1, §3.2.2.1]
  - Verbose or self-contradictory reasoning hurt tool use.
  - Reasoning data without tool interaction led to redundant or repeated tool calls.
  - "A non-negligible fraction" of expert demonstrations pass the tests but contain logic errors.
- **Recovery in pre-training:** the second continued-pre-training stage (about 300B tokens of teacher trajectories) includes "corrected failure paths" to improve error recovery. No ablation is given. [1, §3.2.1.2]
- **Final model:** 57.40% on SWE-bench Verified and 24.72% on Terminal-Bench 2.0, as Pass@1 averaged over 3 runs. [1, §3.3.1, §3.3.3.1, Table 1]

No number in the report isolates the effect of error masking or context masking.

## 4. Evidence boundaries

- **The masking rules are untested in the report.** Training stability and efficiency gains are asserted in the section titles, not measured.
- **It is not stated whether a masked turn stays in the context of later turns.** The formula conditions each turn on its full prior state, which suggests it does, but the text does not say so. [1, Eq. 1]
- **The context-masking heuristics are not specified** beyond examples.
- **All benchmark numbers are self-reported** on the authors' own harness (iFlow CLI).
- **The model is a 30B MoE with 3B active parameters,** trained at a scale (hundreds of billions of tokens) far beyond ours.

## 5. What we take from it

Our interpretation, not the paper's claims.

- Error masking gives a concrete rule for recovery examples. The failed call and its error stay visible in the input. The failed assistant turn gets zero loss. The fix that follows is trained. The model learns how to recover without being trained to make the mistake. This matters because only 10 of our 2,082 training replies show a fix after a syntax error.
- Context masking applies directly to folding. If a training turn's reasoning depends on content our fold removed, we should render that turn unfolded (with an explicit unfold call before it) or mask its loss. Otherwise the model learns conclusions from evidence it cannot see.
- A cheap structural filter (valid Qwen XML tool call, tool allowed in this phase) should run before any test- or LLM-based filter.
- Since the report has no ablation, we should run our own small one: the same data with and without error masking, measuring repeated failing calls.

## Reference

[1] ROCK & ROLL & iFlow & DT Joint Team. *Let It Flow: Agentic Crafting on Rock and Roll, Building the ROME Model within an Open Agentic Learning Ecosystem.* arXiv:2512.24873 (v3). <https://arxiv.org/html/2512.24873>. Accessed 2026-11-11.
