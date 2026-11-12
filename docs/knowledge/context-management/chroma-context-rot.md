# How Output Quality Falls as Input Length Grows

A method note based on Chroma's "Context Rot" report [1].

- **Evidence:** B. Controlled experiments that hold task difficulty fixed while varying length, across 18 models, with released datasets; vendor technical report, not peer reviewed; results shown as plots without error bars.
- **Numbers checked against the source:** yes, 2026-11-11, against the HTML page text. Results that appear only in plots were not read off.

## 1. Problem

Long-context models are usually assumed to use their window uniformly, and needle-in-a-haystack scores near 100% reinforce that. Those tests measure lexical retrieval. The report asks how performance changes with input length when the task itself stays equally easy. [1, Introduction, Related Work]

## 2. Method

This is a measurement study; the findings a design can act on are below.

| Experiment | What varies | Finding |
|---|---|---|
| Needle-question similarity | Cosine similarity of needle to question (8 needles per topic) | Lower similarity makes accuracy fall faster with length |
| Distractors | 0, 1 or 4 topically related wrong answers | One distractor hurts; four hurt more; distractors are not equally harmful |
| Needle-haystack similarity | Needle on- or off-topic for the haystack | Mixed: effect in one haystack, minimal in the other |
| Haystack structure | Coherent essays vs shuffled sentences | Shuffled haystacks gave better retrieval in all 18 models |
| LongMemEval | Full ~113k-token history vs ~300-token focused input | Every model did better on focused input |
| Repeated words | Copy a sequence of repeated words with one different word, up to 10,000 words | Accuracy fell with length in all models |

[1, NIAH Extension, LongMemEval, Repeated Words]

### Key decisions

1. **Hold difficulty fixed.** The needle-question pair stays the same; only irrelevant content is added, so length is isolated as the variable. [1, Needle-Question Similarity, Results]
2. **Separate distractors from irrelevant content.** Distractors are related to the needle but do not answer the question. [1, NIAH Extension]
3. **Calibrate the judge.** A GPT-4.1 judge was iterated until it agreed with human labels on more than 99% of about 500 NIAH and 600 LongMemEval outputs. [1, Appendix]

### Implementation details that generalise

- Needle position (11 positions tested) had no notable effect on this task. [1, Needle-Question Similarity, Results]
- In the distractor condition, Claude models tended to abstain and GPT models hallucinated most. [1, Impact of Distractors, Results]
- In the copy task, position accuracy was highest when the unique word was near the start. [1, Repeated Words, Results]

## 3. Evidence

- **Scale:** 18 models (5 Anthropic, 7 OpenAI, 3 Google, 3 Qwen: 235B-A22B, 32B, 8B); 8 input lengths and 11 needle positions per configuration; 194,480 LLM calls, of which 69 (0.035%) were refusals. Qwen models were extended from 32,768 to 131,072 tokens with YaRN. [1, Details, Appendix]
- **LongMemEval:** 306 questions after removing 38 ambiguous ones; full prompts average about 113k tokens, focused about 300. Thinking modes improved both conditions but did not close the gap. Claude models showed the largest gap, mostly through abstentions. [1, LongMemEval]
- **Repeated words:** Qwen3-8B was the only Qwen model that did not attempt some tasks (4.21%), and produced unrelated output from around 5,000 words. Gemini models produced words not in the input from around 500 to 750 words. Opus 4 refused 2.89% and GPT-4.1 2.55%. [1, Repeated Words, Results]

## 4. Evidence boundaries

- **Synthetic, simple tasks.** No agent, tool use or code. The authors expect real tasks to degrade at least as much but do not show it. [1, Limitations]
- **Two haystack topics only**; the authors say this is not enough to generalise the needle-haystack result. [1, Needle-Haystack Similarity]
- **No mechanism.** The shuffled-haystack effect is unexplained. [1, Limitations]
- **No numeric error bars**; most results are in figures.
- **Qwen3-8B is the closest model to ours** but is untuned for any domain and ran with YaRN extension; it says nothing about a model fine-tuned to 16k.
- **Not all 18 models ran every experiment**, because of context-window or thinking-budget limits. [1, Appendix]

## 5. What we take from it

Our interpretation, not the paper's claims.

- The usable budget is much smaller than the hard limit. For our model, trained to 16k, the training length is the stronger bound.
- Old outputs from superseded attempts (old file versions, old test logs) are distractors in the report's sense. Folding them removes misleading near-duplicates, not only tokens.
- Fold lines should reuse the words the model will later search for (file path, test name, error code), since low query-target similarity made retrieval worse.
- Long verbatim copying degrades in an 8B model; edits should be range- or diff-based rather than whole-file rewrites.

## Reference

[1] Kelly Hong, Anton Troynikov, Jeff Huber (Chroma). *Context Rot: How Increasing Input Tokens Impacts LLM Performance.* Technical report, 2025-07-14 (updated 2025-07-16). <https://www.trychroma.com/research/context-rot>. Accessed 2026-11-11.
