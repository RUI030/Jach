# Schema-Constrained Decoding in Small Models: Valid Output, Wrong Values

A method note based on "The Constraint Tax" [1].

- **Evidence:** B. Paired comparison with bootstrap intervals; single-author preprint, synthetic tasks, models up to 3B, no code link in the text.
- **Numbers checked against the source:** yes, 2026-11-11, against the arXiv HTML (v1).

## 1. Problem

Hard output constraints (a grammar, regex or JSON schema enforced during decoding) guarantee that a tool call parses. The usual assumption is that they change only the wrapper. The paper asks whether, in models below about 3B, the constraint also changes the answer inside the wrapper. [1, Abstract, §1]

## 2. Method

The constraint tax is the clipped accuracy loss of a constrained mode against a baseline, with model, task and instances held fixed. A gain is reported as a gain, not a negative tax. [1, §4.2]

Every output gets four measures: schema validity, answer accuracy, executable accuracy, and the **wrong-valid-schema rate**, the share of outputs that pass the schema but fail the checker. [1, §4.1]

Settings [1, §5]:

- **Main suite:** Qwen2.5 0.5B and 1.5B, SmolLM2 1.7B; five synthetic task families, 1,000 instances per model; vLLM; 15,000 generations.
- **Calendar tool call:** Qwen2.5-1.5B-Instruct builds a `create_calendar_event` object (title, date, start time, duration, attendee, topic), checked by execution; 200 examples per mode.
- **3B boundary:** Qwen2.5-3B-Instruct.
- **Backend replication:** vLLM against SGLang.
- **Expanded study:** four models, 20 examples per family, adds rationale-first schemas and delayed constraints; no intervals.

### Key decisions

1. **Separate validity from correctness.** A parser sees only validity; the checker decides correctness.
2. **Use prompt-only JSON as the baseline,** so the comparison is the same object with and without enforcement.
3. **Classify errors.** Parser retries fix invalid JSON; they do nothing for a valid wrong answer. [1, §4.4]

### Implementation details that generalise

- The paper's design rule is "reason free, constrain late": let the model solve, then package the result into the required object. [1, §1, §6.6]
- Pin model, tokenizer, decoding engine and schema when reporting; constrained decoding is a property of the serving path. [1, §7.3]

## 3. Evidence

Main suite, prompt JSON against answer-only schema, with 95% intervals. [1, §6.1, Table 3]

| Mode | Answer acc. | Valid | Exec. acc. | Wrong-valid |
|---|---|---|---|---|
| Prompt JSON | 19.7 [18.3, 21.1] | 61.5 | 12.0 [10.9, 13.2] | 49.5 |
| Answer-only schema | 11.0 [9.9, 12.2] | 100.0 | 11.0 [9.9, 12.2] | 88.9 |

Executable accuracy nearly ties (−1.0 point), because prompt JSON loses many correct answers to malformed objects. [1, §6.1]

Calendar tool call, Qwen2.5-1.5B. [1, §6.3, Table 6, Table 7]

| Mode | Exec. acc. | Valid | Wrong-valid |
|---|---|---|---|
| Prompt JSON | 91.5 [87.5, 95.0] | 100.0 | 8.5 |
| Hard schema | 48.0 [41.0, 55.0] | 100.0 | 52.0 |

- 102 of the 104 hard-schema failures were a single wrong field, `duration_minutes`, for example 180 for a 30-minute request. [1, Table 7]
- Tax by model on the main suite: Qwen2.5-0.5B 11.9 answer points, Qwen2.5-1.5B 20.0, SmolLM2-1.7B 0.0. SmolLM2 gained from the constraint because its prompt-JSON baseline was weak. [1, §6.2, Table 5]
- Qwen2.5-3B: answer accuracy 39.0% to 23.7%, a tax of 15.3 [11.2, 19.2]; validity 82.6% to 98.9%. [1, §6.5, Table 9]
- Backends: Qwen results were identical on vLLM and SGLang; SmolLM2 scored 18.7% against 25.7%. [1, §6.4, Table 8]
- Expanded study, answer accuracy: prompt JSON 31.5%, answer-only schema 26.8%, rationale-then-answer schema 36.5%, delayed constraint 40.7% at 100% validity. [1, §6.6, Table 10]

## 4. Evidence boundaries

- **No model above 3B.** The author states the study gives no scaling law. [1, §9]
- **The calendar "delayed packaging" row is not a model run.** It deterministically re-serialises the prompt-JSON outputs, so its 0.0 tax is true by construction. [1, §5, Table 6]
- The rationale and delayed-constraint gains come from the small study without intervals; the author calls them design evidence. [1, §4.3, §9]
- Synthetic tasks. In the main suite the tool-call family scored 0.0% in both modes, so it shows nothing. [1, Table 4]
- The baseline models are not fine-tuned on the target format.

## 5. What we take from it

Our interpretation, not the paper's claims.

- Our model's calls are already mostly well-formed, which is the calendar setting: validity saturated, so constraining could only move value errors. Our failure is a wrong value (an offset), which a grammar cannot catch and, on this evidence, may make more frequent.
- Validate argument values in the harness (does the line exist, is the offset in range), and log parse-valid, schema-valid and value-valid rates per tool.
- If we adopt constrained decoding, measure the wrong-valid rate on our 9B model first. The tax persisted at 3B and nothing shows where, or whether, it stops.
- With thinking disabled, "reason first" needs a free-text span or a rationale field before the arguments.

## Reference

[1] Jaideep Ray. *The Constraint Tax: Measuring Validity-Correctness Tradeoffs in Structured Outputs for Small Language Models.* arXiv:2605.26128, 20 May 2026. <https://arxiv.org/html/2605.26128>. Accessed 2026-11-11.
