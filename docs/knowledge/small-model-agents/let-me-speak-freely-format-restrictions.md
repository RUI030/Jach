# Does Forcing a Structured Output Format Cost Reasoning Accuracy?

A method note based on "Let Me Speak Freely?" [1].

- **Evidence:** B. Controlled comparison over nine prompt variants per setting with standard deviations, public code; a preprint with no venue stated, simple two-field schemas, and models no larger than GPT-3.5 class.
- **Numbers checked against the source:** yes, 2026-11-11, against the arXiv HTML (v3), including Appendix F tables.

## 1. Problem

Applications ask models for JSON, XML or YAML so the answer can be parsed. The paper asks whether that requirement changes the quality of the answer, not only its shape. [1, §1]

## 2. Method

Three levels of restriction, from strict to loose, compared with plain natural language (NL). [1, §2]

| Level | What happens |
|---|---|
| JSON mode | Constrained decoding: the provider or server only allows valid JSON tokens. |
| Format-restricting instructions (FRI) | The prompt asks for JSON, XML or YAML with a schema; nothing enforces it. |
| NL-to-Format | The model answers in free text; a second call converts the answer to the format. |

Schemas have two fields, a reasoning field and an answer field. Each setting is run with three task descriptions and three schema wordings; scores are averaged with a standard deviation. An LLM (Claude 3 Haiku) extracts the final answer, so format slips do not count as wrong answers. [1, §3.2, §3.4]

Models: GPT-3.5 Turbo, Claude 3 Haiku, Gemini 1.5 Flash, LLaMA-3-8B-Instruct, Gemma-2-9B-Instruct; GPT-4o-mini for a later schema test. Tasks: reasoning (GSM8K, Last Letter, Shuffled Objects) and classification (DDXPlus, MultiFin, Sports, Task 280). [1, §3]

### Key decisions

1. **Separate format failure from answer failure.** A perfect-parser LLM pulls out the answer, so the measured loss is in the content.
2. **Vary the prompt wording.** Nine variants per cell expose how sensitive each format is.
3. **Include a decoupled baseline.** NL-to-Format tests whether reasoning first and formatting second avoids the loss.

### Implementation details that generalise

- Key order matters. In JSON mode, 100% of GPT-3.5 Turbo responses on Last Letter put "answer" before "reason", which turns reasoning-then-answer into direct answering. [1, §4.1]
- Parse errors, where present, were mostly fixed by a second prompt asking a model to repair the syntax. [1, §5.3, Fig. 5]

## 3. Evidence

GSM8K, FRI, mean (std) over prompt variants. [1, §5.1, Table 1]

| Model | NL | JSON, no schema | JSON with schema |
|---|---|---|---|
| Gemini 1.5 Flash | 89.33 (0.8) | 89.66 (0.3) | 89.21 (1.5) |
| Claude 3 Haiku | 86.51 (0.8) | 86.99 (0.2) | 23.44 (22.9) |
| GPT-3.5 Turbo | 75.99 (3.1) | 74.70 (1.1) | 49.25 (12.0) |
| LLaMA-3-8B | 75.13 (0.9) | 64.67 (2.23) | 48.90 (6.7) |

- JSON mode on Last Letter scored 7.56 for LLaMA-3-8B, against 70.1 in NL. [1, Table 11, Table 9]
- Gemma-2-9B, the model nearest our size: Last Letter 56.8 NL against 39.0 JSON; GSM8K 86.5 against 84.2. [1, Table 9]
- Classification went the other way. DDXPlus with JSON FRI: LLaMA-3-8B 12.04 (15.2) to 23.37 (0.7); Gemma-2-9B 22.9 to 53.0; Gemini 41.6 to 60.3. [1, Table 10]
- Real grammar-constrained decoding (GPT-4o-mini structured outputs) did much better than JSON mode: GSM8K NL 94.57, JSON schema 91.71, JSON mode 86.95; Last Letter NL 83.11, JSON schema 86.07, JSON mode 76.00. [1, §5.4, Table 2]
- NL-to-Format matched NL for most models; LLaMA-3-8B was slightly lower because of conversion errors. [1, §4.1]
- Parse errors do not explain the gap: LLaMA-3-8B had a 0.148% JSON parse-error rate alongside a 38.15-point gap. [1, §5.3] Where they did occur, they were large: Claude 3 Haiku JSON on GSM8K 60.07%; LLaMA-3-8B YAML up to 34.40%. [1, Table 3]

## 4. Evidence boundaries

- Only two-field schemas; no tool calls with typed arguments. [1, §3.2]
- The steep losses are mostly under FRI with a schema, which is prompting, not enforced decoding. Grammar-constrained decoding was tested on one model only, and there it was close to NL.
- No model above GPT-3.5 class (the authors cite cost). [1, App. A]
- §5.3 refers the 38.15-point gap to Table 1, which reports GSM8K, not Last Letter; the pairing of the two numbers is unclear in the source.
- No fine-tuned models. A model trained on one format may not show these losses in that format.

## 5. What we take from it

Our interpretation, not the paper's claims.

- Our baseline runs with thinking disabled, so the tool call may be the first thing the model writes. Any reasoning we want before an argument has to come from the format: a short free-text line before the call, or a reasoning field before the arguments.
- Constraints help on closed choices. That supports constraining tool names and enumerated arguments, and leaving free-form arguments to validation.
- The large gap between JSON mode and real schema decoding warns against generalising "constraints hurt". The implementation matters, as `constraint-tax.md` also finds.
- Our model was fine-tuned on one XML tool format. The format-change losses here may not apply to it, and only a local test can show that.

## Reference

[1] Zhi Rui Tam, Cheng-Kuang Wu, Yi-Lin Tsai, Chieh-Yen Lin (Appier AI Research), Hung-yi Lee, Yun-Nung Chen (National Taiwan University). *Let Me Speak Freely? A Study on the Impact of Format Restrictions on Performance of Large Language Models.* arXiv:2408.02442. <https://arxiv.org/html/2408.02442>. Code: <https://github.com/appier-research/structure-gen>. Accessed 2026-11-11.
