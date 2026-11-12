# A Failure Taxonomy for LLM Agent Systems, with Step Repetition at the Top

A method note based on MAST, "Why Do Multi-Agent LLM Systems Fail?" [1].

- **Evidence:** B. Taxonomy built from annotated traces with reported agreement and public data; most labels come from an LLM judge, and the intervention results rest on small task sets without significance tests for ChatDev.
- **Numbers checked against the source:** yes, 2026-11-11, against the arXiv HTML (v3), main text and appendices.

## 1. Problem

Multi-agent LLM systems often gain little over single agents on benchmarks, and aggregate success rates do not say why. The paper builds a shared vocabulary for agent-system failures, so that traces can be labelled and design changes compared by which failures they remove.

## 2. Method

This is a failure taxonomy, so this section holds the classification and the findings a design can act on.

Six experts applied grounded theory to 150 traces from five frameworks until no new modes appeared [1, §3.1]. Three annotators then refined the definitions over three rounds of five traces each, reaching an average Cohen's kappa of 0.88 in the final rounds [1, §3.2]. An o1-based judge with few-shot examples reached 94% accuracy and kappa 0.77 against human labels; without examples, 89% and 0.58 [1, §3.3, Table 2]. A human round on two systems outside the development set gave kappa 0.79 [1, §3.4]. The judge then labelled 1,642 traces [1, §3.4].

The result is 14 modes in 3 categories. Percentages are each mode's share of the failure labels across the 1,642 traces [1, Fig. 1, §4].

| Category | Mode | Share |
|---|---|---|
| FC1 System design | 1.1 Disobey task specification | 11.8% |
| | 1.2 Disobey role specification | 1.5% |
| | 1.3 Step repetition | 15.7% |
| | 1.4 Loss of conversation history | 2.8% |
| | 1.5 Unaware of termination conditions | 12.4% |
| FC2 Inter-agent misalignment | 2.1 Conversation reset | 2.2% |
| | 2.2 Fail to ask for clarification | 6.8% |
| | 2.3 Task derailment | 7.4% |
| | 2.4 Information withholding | 0.85% |
| | 2.5 Ignored other agent's input | 1.9% |
| | 2.6 Reasoning-action mismatch | 13.2% |
| FC3 Task verification | 3.1 Premature termination | 6.2% |
| | 3.2 No or incomplete verification | 8.2% |
| | 3.3 Incorrect verification | 9.1% |

### Findings a design can act on

1. **Repetition is common but not, on its own, a sign of failure.** In ChatDev, step repetition occurs in 20.0% of successful and 20.0% of failed runs; in MetaGPT, 16.7% and 22.2%. Unaware-of-termination occurs in 0% of successful runs and about 10% of failed ones in both [1, App. J.1, Table 7].
2. **Smaller models repeat almost everywhere.** In 400 traces with open models, step repetition was labelled 97 and 99 times for CodeLlama-7b (ChatDev, MetaGPT) and 96 and 35 times for Qwen2.5-Coder-32B [1, App. I, Table 6].
3. **Verifiers check too little.** Many verifiers only confirm that code compiles or that no TODO comments remain [1, §4, FC3].
4. **Profiles differ by system.** AppWorld often terminates early; OpenManus and HyperAgent lean towards step repetition [1, §5.1, Fig. 4].

## 3. Evidence

- Failure rates of the studied systems range from 41% to 86.7% [1, §1].
- ChatDev on ProgramDev-v0, 32 tasks: baseline 25.0%, improved role prompts 34.4%, new topology 40.6% [1, App. H.2, Table 5]. The main text reports these as +9.4% and +15.6% [1, §4].
- The same ChatDev changes on HumanEval: 89.6% to 90.3% and 91.5% [1, Table 5].
- AG2 MathChat on 200 GSM-Plus problems, six repetitions: with GPT-4, the improved prompt went from 84.75 ± 1.94 to 89.75 ± 1.44, and the new topology to 85.50 ± 1.18, which was not significant (Wilcoxon p = 0.4). With GPT-4o, both changes were significant (p = 0.03) [1, App. H.1, Table 5].

## 4. Evidence boundaries

- The +15.6 point gain is 5 of 32 tasks, with no interval or test reported.
- The paper describes that gain two ways. The main text calls it a high-level objective verification step [1, §4]. Appendix H.2 describes a change from a DAG to a cyclic graph that ends only when the CTO agent confirms all reviews.
- The paper says seven frameworks, but §3.4 lists eight names, including Manus [1, §1, §3.4].
- The shares come from the LLM judge, whose recall against humans is 0.77 [1, Table 2].
- The success/failure table (Table 7) rests on a few traces per cell. The percentages move in steps of 5 to 17 points.
- Systems are multi-agent frameworks with role-play prompts, not a single agent under a harness-owned task state machine.

## 5. What we take from it

Our interpretation, not the paper's claims.

- Repetition being the top mode even for strong models makes loop handling a harness responsibility, not only a small-model defect.
- Repetition appearing as often in successful as in failed runs means a loop detector should trigger help, not declare failure.
- "Unaware of termination" being nearly fatal supports the harness deciding when a task is done.
- The 14 modes can serve as a label set for our failed trajectories, to see whether a harness change shifts the distribution.

## Reference

[1] Mert Cemri, Melissa Z. Pan, Shuyi Yang, and 10 others (UC Berkeley; Intesa Sanpaolo). *Why Do Multi-Agent LLM Systems Fail?* arXiv:2503.13657v3. <https://arxiv.org/html/2503.13657>. Data: <https://huggingface.co/datasets/mcemri/MAST-Data>. Accessed 2026-11-11.
