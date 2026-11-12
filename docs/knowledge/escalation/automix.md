# Escalation on a Noisy Self-Check, with a Learned Router (AutoMix)

A method note based on the AutoMix paper [1].

- **Evidence:** B. Controlled comparison on five datasets and three small models against two published baselines; preprint (v5), costs modelled, no variance in the main table.
- **Numbers checked against the source:** yes, 2026-11-11, against the arXiv HTML (v5, 19 January 2025).

## 1. Problem

A cascade needs to know when the small model's answer is good enough. Trained verifiers need labelled data and model access. Can the small model's own self-check, used with black-box access only, drive the decision? [1, §1, §3]

## 2. Method

Three steps per query. [1, §4]

1. **Answer** with the small model.
2. **Self-verify** with the same small model, using one fixed 4-shot prompt for all tasks. Verification is framed as entailment: is the answer consistent with the provided context? The check is sampled k > 1 times at high temperature; the fraction of "correct" votes is the confidence. [1, §4.1]
3. **Route.** A router decides whether to keep the answer or call a larger model. [1, §4.2]
   - *Threshold:* keep if confidence ≥ t.
   - *POMDP:* hidden state is how well each model would do on this query; the vote fraction is a noisy observation; the reward is performance minus λ·cost. Observation probabilities are estimated from training data with kernel density estimates. [1, §4.2, App. A.3]

### Key decisions

1. **Check against the context, not "are you sure?".** An answer that contradicts the supplied text is easy to flag. [1, §1, §4.1]
2. **Treat the self-check as noisy.** The router acts as a meta-verifier, so a low score can mean "hard for everyone" as well as "small model wrong". [1, §4.2]
3. **Keep routing out of the LLM.** The router is a non-LLM component, which the authors chose to avoid the known weaknesses of LLM self-correction. [1, §4.2]

### Implementation details that generalise

- The POMDP router can learn not to escalate queries that no model will solve, saving cost; on qasper with mistral-7b it returned the small model's answer at low confidence. [1, §5.4]
- The router adds under 1 ms per query. [1, §5.4]
- The method needs a cost ratio between models; gains appeared from a ratio as low as 1:10 and grew as it widened. [1, §5.4, Fig. 5]

## 3. Evidence

Small models mistral-7b, llama2-13b and gpt-3.5; large model gpt-4. Datasets qasper, quality, coqa, mutual and diplomat, all context-grounded. Modelled cost ratios 1:200, 1:100 and 1:60 respectively. Eight verification samples per question. [1, §5.2, App. B]

The metric is ΔIBC: incremental benefit per cost relative to always using the large model; positive means better than linear mixing. [1, §5.1]

| Method | Configurations with ΔIBC < 0 (of 15) |
|---|---|
| FrugalGPT | 4 |
| HybridLLM | 1 |
| AutoMix, threshold | 1 |
| AutoMix, POMDP | 0 |

Counted from [1, §5.3, Table 1].

- The abstract reports more than 50% cost reduction at comparable performance. [1, Abstract]
- Best gains were on diplomat, averaging 122% ΔIBC across models. [1, §5.3]
- With 50 training examples, AutoMix kept 15% ΔIBC and beat both baselines by more than 20 points absolute. [1, §5.4]
- Self-verification was not informative everywhere. With llama2-13b, higher verifier confidence went with more correct answers on all datasets except quality and qasper. [1, App. A.1, Fig. 12]
- In a three-model setup (llama2-13b, llama2-70b, gpt-4), cases where the middle model's self-check was poor gave no significant gain over FrugalGPT. [1, §5.5, App. C.2.4]

## 4. Evidence boundaries

- Costs are fixed units, not measured bills. The FrugalGPT and HybridLLM routers were assigned zero cost, which favours them. [1, §5.2, §5.2 Baselines]
- The verification temperature is given as 1 in one appendix paragraph and 0.7 in another. [1, App. B]
- The authors limit the method to context-grounded tasks and say it does not cover factual QA or commonsense reasoning without context. [1, Limitations]
- All tasks are single-turn QA with a short answer and a supplied context.

## 5. What we take from it

Our interpretation, not the paper's claims.

- For code, the strongest "context-grounded" check is execution: the Jac checker and acceptance tests. Asking the 9B model to judge its own work should be at most a secondary signal, and should not gate escalation alone.
- The meta-verifier idea applies: treat each harness signal (checker result, repeated calls, steps used, LOOP DETECTED) as noisy, and learn the escalation rule from labelled runs rather than one hand-set threshold.
- About 50 labelled examples sufficed here, a scale our own run logs can reach.
- The "unsolvable for everyone" case matters for cost: if the admin also fails on a task class, escalating it is waste.

## Reference

[1] Pranjal Aggarwal, Aman Madaan, Ankit Anand, Srividya Pranavi Potharaju, Swaroop Mishra, Pei Zhou, Aditya Gupta, Dheeraj Rajagopal, Karthik Kappaganthu, Yiming Yang, Shyam Upadhyay, Manaal Faruqui, Mausam (CMU, xAI, Google, Google DeepMind, IIT Delhi, USC). *AutoMix: Automatically Mixing Language Models.* arXiv:2310.12963v5. <https://arxiv.org/html/2310.12963>. Accessed 2026-11-11.
