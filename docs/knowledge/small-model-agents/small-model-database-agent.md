# What Stops a Small Language Model From Driving a Database Agent

- **Source:** https://arxiv.org/html/2609.21341
- **Authors / org:** Cevheri Bozoğlan, Yusuf Gündoğdu, Abdullah Kaya, Koray Şirin (independent researchers; contributors to the evaluated software, LibreDB Studio)
- **Date:** 18 September 2026
- **Type:** paper
- **Read:** full text

## Summary

A field study of 39 locally served open-weight models (about 1.7B to 35B parameters, through Ollama) and one hosted control, driving a read-only database agent across six task types on a small SQLite database. The corpus is 8,199 runs. The authors test the assumption that small models fail for lack of reasoning ability.

They classify 2,100 failed agent runs attributable to the model. The largest class, 36.2%, is "transport": the model tried to call a tool but the call never executed, because it was written as prose or malformed JSON in the text channel, or because arguments were placed in the wrong fields (for example a SQL statement in a field with another name, or `reason` where `rationale` was required). Time limits accounted for 25.8%, failed verification of the final report for 20.7%, and runs where no tool was ever invoked, the class closest to incapacity, for 17.3%. About three quarters of failures came from runs that did call at least one tool. One model resent the same misplaced-field call four times after being told which fields were missing.

Some failures were the server's fault: one tool required a field that its sibling tool forbade, and one error message misled models. With no context cap, a 7 GB model ran at a 262k-token window, used 51 GB of memory and timed out, which looked like model failure.

The authors then changed only the server: parse tool calls written in the text channel, accept near-miss field names, tolerate displaced fields, and fix the misleading message. Models, prompts and sampling were unchanged. Pass counts out of 30 rose from 10 to 24 for llama3.1:8b, 0 to 21 for cogito:8b, 21 to 28 for granite4.2:3b, and 18 to 26 for mistral-nemo:12b. The argument-shape fixes drove most of the gain.

Stated limits: uncontrolled observations from one machine and one harness; possible regression to the mean; the authors maintain the software under test.

## Key points

- The most common small-model failure was a tool call that did not execute, not a lack of ability to attempt the task.
- Tolerant parsing and repair of near-miss arguments moved 8B models from failing to mostly passing with no model change.
- Inconsistent tool schemas and misleading error text caused repeated invalid calls.
- An uncapped context window produced timeouts that were misread as model failure.
- Evidence is observational, with a disclosed conflict of interest.

## Relevance to JacKnife

(Our interpretation, not the source's claims.)

- Before blaming the 9B model for a parameter misuse, audit the tool: is the parameter named consistently across tools, and does the error text say exactly what to send?
- Add a repair layer in the harness: accept unambiguous near-miss parameter names and tool calls emitted as text, execute the repaired call, and log the repair. This removes a class of loops without the model needing to self-correct.
- Logged repairs are training data: (malformed call, canonical call) pairs for the next fine-tuning round.
- Classify our 22 failed runs the same way (call never executed / ran out of steps / failed acceptance / never tried) to see how many are interface failures.
- Set an explicit context cap for the local model.
