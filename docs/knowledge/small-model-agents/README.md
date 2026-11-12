# Small-model agents

Sources on making small or local models reliable at tool use: the design of commands and tool schemas, how many tools to show, what constrained decoding and format restrictions do to answer quality, and repairing malformed calls at the harness boundary. Most of the evidence comes from models far from ours: closed frontier models (SWE-agent, Anthropic) or models of 3B and below (Constraint Tax). Only Less-is-More, Let Me Speak Freely and the database-agent study include 7-9B open models, and none includes a model fine-tuned on its own tool format. All numbers were checked against the source text on 2026-11-11.

| Note | Grade | One-line takeaway |
|---|---|---|
| [swe-agent-aci.md](swe-agent-aci.md) | A | Interface changes alone took GPT-4 Turbo from 11.0% to 18.0% on SWE-bench Lite; after one failed edit, eventual edit success fell from 90.5% to 57.2%. |
| [anthropic-writing-tools-for-agents.md](anthropic-writing-tools-for-agents.md) | D | Few workflow-level tools, unambiguous parameter names, readable identifiers, errors that show a valid input, all tuned by task evaluations. |
| [let-me-speak-freely-format-restrictions.md](let-me-speak-freely-format-restrictions.md) | B | Schema instructions cut GSM8K accuracy (LLaMA-3-8B 75.1 to 48.9) but helped closed-set classification; real schema decoding on GPT-4o-mini stayed close to free text. |
| [constraint-tax.md](constraint-tax.md) | B | In models up to 3B, hard schemas made output 100% valid and more often wrong; a calendar tool call fell from 91.5% to 48.0% executable accuracy. |
