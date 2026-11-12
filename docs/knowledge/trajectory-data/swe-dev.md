# SWE-Dev: Building Software Engineering Agents with Training and Inference Scaling

- **Source:** https://arxiv.org/html/2506.07636
- **Authors / org:** Haoran Wang, Zhenyu Hou, Yao Wei, Jie Tang, Yuxiao Dong (Tsinghua University, Zhipu AI)
- **Date:** 2025-06 (arXiv v2 dated 2025-06-23)
- **Type:** paper
- **Read:** full text

## Summary

SWE-Dev trains open models as coding agents and studies how results scale with training data and with the number of interaction rounds at inference.

Data construction starts from 240k PyPI packages, narrowed to about 10k downloaded repositories and 38k task instances from 4,413 repositories after rule-based filtering. Since most pull requests lack tests, an LLM pipeline writes them: extract repository context, write Gherkin scenarios describing expected behaviour, generate test cases from the scenarios, and optionally revise them using traceback errors. On a 26k-instance subset this yielded 2,097 fail-to-pass test functions, a low yield that the authors attribute largely to environment problems.

Trajectories were sampled with OpenHands using DeepSeek-V3: about 17k without execution-based evaluation and 2.3k verified correct. For the unverified set, a Llama-3.1-70B judge compared each trajectory's final patch with the reference patch and graded it identical, mostly identical, partially identical or different; only the first two grades were kept, about 65% of the set. Removing the other 35% cost little performance.

Results on SWE-bench Verified: 23.4% with a 7B model (Qwen2.5-Coder base) and 36.6% with a 32B model. Resolve rate rose roughly linearly in the logarithm of the number of training trajectories; for the 7B model, 13.0% at 574 trajectories and 22.8% at 16,639. Larger models benefited more from added data.

At inference, allowing more rounds in a single run helped: the 32B model went from 34.0% at 30 rounds to 36.6% at 75, with little gain past about 45. Extending the positional-encoding context from 32k to 160k slightly reduced the 7B model (22.8% to 21.8%).

Rejection-sampling fine-tuning beat two offline RL methods that also used negative trajectories, and beat a hybrid of the two approaches.

## Key points

- When tests are unavailable, similarity of the final patch to a reference patch (LLM-judged) is a workable filter.
- A 7B model kept improving up to about 16k trajectories, on a log scale.
- Plain fine-tuning on successful trajectories beat offline RL with negatives in their setting.
- More interaction rounds help up to a point; a longer context window did not help the small model.
- LLM test synthesis for arbitrary repositories has a low yield.

## Relevance to JacKnife

(Our interpretation.)

- For Jac tasks without runnable tests, comparing the final diff with a reference solution gives a second-tier filter; mark such trajectories as lower confidence.
- The 7B scaling curve disagrees with R2E-Gym's early saturation for 14B. The two used different scaffolds, teachers and data; treat the saturation point as unknown and measure it with a data-size ablation.
- The 7B model did slightly worse with a longer context. This supports staying inside the trained 16k range instead of relying on the 262k limit.
- Set per-task turn budgets from data: gains flattened near 45 rounds here.
- Gherkin-style scenarios as an intermediate between requirement and test fit JacKnife's acceptance-criteria format.
