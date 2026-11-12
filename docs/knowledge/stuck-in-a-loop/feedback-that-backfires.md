# Why a Failed Call in Context Makes Small Models Repeat It, and What Breaks the Copy

A method note based on "Feedback That Backfires" [1].

- **Evidence:** B. Controlled probe and rollout experiments with public code and data; single-author preprint, models of 1.7B and smaller, rollouts on one 0.5B model and 24 tasks.
- **Numbers checked against the source:** yes, 2026-11-11, against the arXiv HTML (v1), full text.

## 1. Problem

Harnesses append a failed tool call and its error to the transcript and assume this discourages a repeat. The paper tests whether, for small models, the record lowers or raises the chance of the same call, and why.

## 2. Method

The **corrective gain** of a failure record is the change in log-probability of re-emitting the failed call once the call and its error are in context. A positive gain means the record works as intended [1, §3.2]. The gain is split into two terms by scoring the same call after a failure message, a success message and a neutral acknowledgement [1, §3.3]:

- a **copy** term: the effect of the call's tokens being present at all;
- a **semantic** term: the effect of marking the call as failed.

Two environments are used [1, §5.1]. ToolShed is the authors' own office simulator with 12 tools, where failing calls come from 8 perturbation operators. CodeRepair uses MBPP with real Python interpreter output. Six instruction-tuned models from 135M to 1.7B are tested (SmolLM2, Qwen2.5, Qwen3, Llama-3.2) [1, §5.2]. Intervals are 95% cluster-bootstrap intervals over tasks [1, §5.3].

### Key decisions

1. **Fix the failing action rather than sample it, and change one thing per condition,** so every model is scored on identical items [1, §4.1, §11].
2. **Test harness variants end to end.** Six harnesses are compared in free rollouts: verbatim (standard), verbatim plus a "do not repeat" instruction, drop (delete the failed step and retry), abstract (replace the failed call with a description generated from the runtime's error metadata), verbatim plus a decoder ban on previously failed strings, and abstract plus ban [1, §8.1].

### Implementation details that generalise

- The abstract description is built deterministically from runtime error data, with no extra model call [1, §7].
- A runtime that quotes the failed call inside its error message, as Python tracebacks do, puts the string in context twice [1, §7].
- The authors' design rule: the context after a failure must differ from the context before it, and the difference must not be the failed action [1, §8.3].

## 3. Evidence

Probe results [1, Abstract, §1, §6, §7]:

- The gain is negative for all 6 models, averaging −17.38 nats on ToolShed. That is about −1.03 nats per action token in both environments, and holds on 90% to 100% of items.
- Over four candidate actions, the probability of the failed call rises from 0.06 to 0.54. Greedy decoding reproduces it exactly on 19% of items after the failure, against 0% before [1, Table 4].
- The copy term is 83% of the effect. The semantic term is small, slightly positive on ToolShed and slightly negative on CodeRepair [1, §6.2].
- Rewording the error barely matters: terse −0.28 [−0.68, +0.11] nats, verbose with a hint −0.20 [−0.48, +0.08] [1, §7].
- An echoed call in the error makes repeats more likely: +0.71 [+0.45, +0.97]. Failing twice adds +3.33 and three times +4.03 [1, §7].
- "Do not repeat" moves the gain by +0.07 [−0.07, +0.21] nats. Abstraction moves it by −13.22 [−15.30, −11.34], removing 76% of the inversion [1, Abstract, §7].
- Within each family the larger model is less affected. A log-linear fit crosses zero at 37.6B, but leaving one model out moves the crossing from 20B to 79B, and the authors reject it as a prediction [1, §6.4].

Rollouts, Qwen2.5-0.5B, 24 tasks, up to 6 steps, greedy [1, §8.3, Table 8]:

| Harness | Success | Exact repeat rate | Runs ending in a loop |
|---|---|---|---|
| verbatim | 0.42 | 0.31 | 29% |
| + "do not repeat" | 0.58 | 0.24 | 17% |
| abstract | 0.33 | 0.16 | 8% |
| drop | 0.33 | 0.80 | 67% |
| verbatim + ban | 0.42 | 0.08 | 12% |
| abstract + ban | 0.33 | 0.07 | 4% |

- Neither surface-form fix raised success: abstract −8 [−21, +0] points, ban +0 [+0, +0] [1, §8.3].
- The instruction raised success by +17 [+4, +33] points without a clear drop in repeats (−17 [−44, +12]). The authors do not offer a mechanism for this [1, §8.3].
- 18% of all actions were prose where a call was expected, a failure no transcript change fixes [1, §10].

## 4. Evidence boundaries

- The largest model is 1.7B. Nothing is measured at 9B, and the authors call the 8B question untested [1, §6.4, §11].
- Rollouts cover one model, 24 tasks and greedy decoding. Drop is worst partly because a greedy policy in an identical context repeats itself; sampling may change that [1, §8.3].
- ToolShed, its operators and error messages are the authors' own [1, §11].
- The paper contradicts itself in two places. §8.4 says the rollouts show abstraction raising success and the instruction raising repetition, but Table 8 shows the reverse. §10 says the ban pushes repetition into paraphrase, but §8.3 says canonical and exact repeat rates are equal in every harness.

## 5. What we take from it

Our interpretation, not the paper's claims.

- Our model repeats after LOOP DETECTED messages in 6 of 12 tasks, which fits the copy mechanism. The size of the effect at 9B must be measured; the probe is cheap enough to run on our model.
- Error observations should describe the failure and what a valid call looks like, not quote the failed call back.
- A harness block on re-issuing an identical failed call, or a decoder ban if llama.cpp grammar allows it, is cheap and needs no cooperation from the model.
- Breaking the loop did not raise success here. Loop-breaking has to come with real help, such as an admin hint or takeover.

## Reference

[1] Esmail Gumaan (University of Passau). *Feedback That Backfires: Why Small Language Model Agents Repeat the Call They Just Watched Fail.* arXiv:2608.23651v1, 24 August 2026. <https://arxiv.org/html/2608.23651>. Code and data: <https://github.com/Esmail-ibraheem/feedback-that-backfires>. Accessed 2026-11-11.
