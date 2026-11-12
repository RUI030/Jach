# Let Me Speak Freely? A Study on the Impact of Format Restrictions on Performance of Large Language Models

- **Source:** https://arxiv.org/html/2408.02442
- **Authors / org:** Zhi Rui Tam, Cheng-Kuang Wu, Yi-Lin Tsai, Chieh-Yen Lin (Appier AI Research); Hung-yi Lee, Yun-Nung Chen (National Taiwan University)
- **Date:** August 2024 (v3 revised 14 Oct 2024)
- **Type:** paper
- **Read:** full text

## Summary

The paper measures what happens to answer quality when a model is required to produce structured output. Three levels of restriction are compared: constrained decoding (provider JSON mode or a constrained inference server), format-restricting instructions (a prompt asking for JSON, XML or YAML with a schema, not enforced), and a two-step approach in which the model answers in natural language and a second call converts the answer to the format. Models include GPT-3.5 Turbo, Claude 3 Haiku, Gemini 1.5 Flash, LLaMA-3 8B and Gemma-2 9B.

On reasoning tasks, tighter restriction lowered accuracy. On GSM8K with a JSON schema instruction, LLaMA-3 8B fell from 64.7 to 48.9 and GPT-3.5 Turbo from 74.7 to 49.3; Gemini 1.5 Flash was unaffected. A specific cause was found for one large drop: in JSON mode GPT-3.5 always emitted the answer key before the reason key, which removes the benefit of reasoning first.

On classification tasks the effect reversed. Restricting the answer space helped: on a medical diagnosis dataset LLaMA-3 8B went from 12.0 to 23.4 and Gemini from 41.6 to 60.3 with JSON output.

The two-step approach matched free-text performance for most models; LLaMA-3 8B was slightly lower because of occasional errors in the conversion call. Parsing failures were not the main cause of the reasoning gap: for LLaMA-3 8B on one task, a 0.15% parse-error rate coexisted with a 38-point accuracy gap. Unenforced formats could still fail to parse often for some models (up to 33% for LLaMA-3 8B with YAML).

The authors recommend the loosest format that meets the need, placing reasoning fields before answer fields, and separating reasoning from formatting. Schemas tested were deliberately simple (a reason and an answer), and larger models were not included.

## Key points

- Format restrictions reduce accuracy on reasoning tasks, more for some models than others (about 16 points for an 8B model on GSM8K).
- They improve accuracy when the task is choosing from a fixed set.
- Field order matters: answer-before-reason removes the reasoning benefit.
- Reason in free text, then convert, recovers nearly all of the loss.
- The loss is semantic, not a matter of parse errors.
- Only simple two-field schemas were tested.

## Relevance to JacKnife

(Our interpretation, not the source's claims.)

- Let the 9B model write a short free-text rationale before the tool call, and constrain only the call itself. Do not force a tool call as the first tokens of a turn.
- In any structured output we define, put the reasoning field before decision fields.
- Use tight constraints where the choice is from a closed set, which is where they help: tool name, a file path chosen from the paths that exist, an enumerated option.
- The two-step pattern matches `escalation/aider-architect-editor.md`: describe the change, then format it.
- Check together with `constraint-tax.md`, which measures the same effect on smaller models and a tool-call task.
