# MetaGPT: Meta Programming for a Multi-Agent Collaborative Framework

- **Source:** https://arxiv.org/html/2308.00352
- **Authors / org:** Sirui Hong, Mingchen Zhuge, Jiaqi Chen and co-authors; corresponding author Chenglin Wu (DeepWisdom, KAUST and others)
- **Date:** 2023-08 (arXiv v7 dated 2024-11-01)
- **Type:** paper
- **Read:** main text (first ~100k characters of the HTML; the end of the appendix was not read)

## Summary

MetaGPT encodes a software team's standard operating procedure (SOP) as a fixed sequence of role-specific prompts. The claim is that free-form multi-agent chat lets errors compound, while a pipeline with defined hand-off documents contains them.

Five roles act in order. The Product Manager writes a product requirements document (PRD). The Architect turns it into a system design: file list, data structures, interface definitions and a sequence diagram. The Project Manager breaks the design into a task list. The Engineer implements the files. The QA Engineer writes tests. Agents exchange structured documents, not conversation. A shared message pool with publish-subscribe lets each role receive only the message types it needs.

An "executable feedback" loop is added to the Engineer: after writing code it writes and runs unit tests and debugs against the results, for up to three retries.

Results reported: pass@1 of 85.9% on HumanEval and 87.7% on MBPP, with executable feedback contributing 4.2 and 5.4 points. On the authors' SoftwareDev benchmark (70 tasks, seven used for the comparison), MetaGPT scored 3.75 on the paper's executability scale against 2.25 for ChatDev and needed 0.83 human revisions against 2.5. It used more tokens in total (about 31k versus 19k) but fewer per line of code produced. A role ablation shows that an Engineer alone scores 1.0 on executability with 10 human revisions; adding the upstream roles raises this to 4.0 with 2.5 revisions at higher cost.

Limitations stated: no UI or front-end capability, no learning across projects, and strong dependence on the backend model (GPT-4 did clearly better than GPT-3.5 or Deepseek Coder 33B).

## Key points

- A fixed procedure with typed documents between stages beats open-ended agent dialogue on their benchmarks.
- Each stage's output has a schema (PRD, design with interfaces, task list).
- Roles see only the messages they subscribe to.
- Running tests and feeding results back gives a measurable gain; retries are capped at three.
- The planning roles matter: the engineer-only ablation is much worse.

## Relevance to JacKnife

(Our interpretation.)

- JacKnife's states correspond to MetaGPT's roles, with one model and a harness in place of multiple agents. What transfers is the typed hand-off: each state consumes named input files and must produce a named output file with a fixed schema.
- Publish-subscribe is the same idea as per-state context selection: the implement state gets the task and interface definitions, not the requirements discussion.
- The interface-definition step before coding is valuable for task splitting: tasks that share an agreed signature can be implemented and resumed independently.
- A hard cap on debug retries (three here) is a simple loop guard that the harness should own.
- The model-dependence finding means results with GPT-4 do not predict results with a 9B model; the SOP reduces but does not remove that gap.
