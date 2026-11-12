# A Fixed Role Pipeline with Typed Hand-off Documents

A method note based on MetaGPT [1].

- **Evidence:** B. Peer-reviewed (ICLR 2024) with public code, but the software-project results rest on seven tasks scored by humans and a role ablation on two tasks; no error bars.
- **Numbers checked against the source:** yes, 2026-11-11, against the arXiv HTML (v7), including Appendices C and D.

## 1. Problem

Multi-agent systems that talk in free-form chat lose and distort information as it passes between agents, much like a game of telephone. The paper asks whether encoding a software team's standard operating procedure (SOP) as a fixed pipeline of roles, each producing a structured document, gives more workable software. [1, §1, §3.2]

## 2. Method

Five roles act in a fixed order. [1, §3.1, Fig. 1]

| Role | Produces |
|---|---|
| Product Manager | Product requirements document: user stories, requirement pool |
| Architect | System design: file list, data structures, interface definitions, sequence diagram |
| Project Manager | Task list, distributed to engineers |
| Engineer | Code for the assigned classes and functions |
| QA Engineer | Test cases |

### Key decisions

1. **Documents, not dialogue.** Every role has a schema for its output, and agents exchange those documents. [1, §3.2]
2. **Publish-subscribe message pool.** All documents go to a shared pool; each role subscribes to the types it needs, and acts only when all its prerequisite documents are present. [1, §3.2]
3. **Interfaces are fixed before coding.** The Architect's interface definitions and file list are what the Engineer implements. [1, §3.1]
4. **Executable feedback for the Engineer.** After writing code, the Engineer writes and runs unit tests and debugs against the results, up to three retries. [1, §3.3]

### Implementation details that generalise

- The executable feedback loop was added because earlier versions missed errors during LLM-only code review. [1, §3.3]
- The authors list as a user-side limitation that a person cannot interrupt a running agent or restart from a chosen checkpoint. [1, App. D.1]

## 3. Evidence

- Pass@1 with GPT-4: 85.9% on HumanEval and 87.7% on MBPP. Executable feedback added 4.2 and 5.4 points. [1, §4.2, §4.4, Fig. 4]
- SoftwareDev is the authors' own set of 70 tasks; the comparison with ChatDev uses seven of them. [1, §4.1, App. C.1]

SoftwareDev, seven tasks. Executability is a human rating from 1 (fails) to 4 (flawless); revisions count manual fixes. [1, §4.2, Table 1]

| | ChatDev | MetaGPT without feedback | MetaGPT |
|---|---|---|---|
| Executability | 2.25 | 3.67 | 3.75 |
| Human revisions | 2.5 | 2.25 | 0.83 |
| Tokens | 19,292 | 24,613 | 31,255 |
| Tokens per code line | 248.9 | 126.5 | 124.3 |
| Total code lines | 77.5 | 194.6 | 251.4 |

Role ablation, averaged over two tasks. [1, §4.4, Table 3]

| Roles present | Executability | Revisions | Expense |
|---|---|---|---|
| Engineer only | 1.0 | 10 | $0.915 |
| + Product Manager | 2.0 | 6.5 | $1.059 |
| + Product Manager, Architect | 2.5 | 4.0 | $1.204 |
| + Product Manager, Project Manager | 2.0 | 3.5 | $1.251 |
| All four | 4.0 | 2.5 | $1.385 |

Backend model, five SoftwareDev tasks. [1, App. C.2, Table 5]

| Backend | Executability | Revisions |
|---|---|---|
| GPT-4 | 3.8 | 1.2 |
| GPT-3.5 | 2.8 | 2.4 |
| Deepseek Coder 33B | 1.4 | 2.6 |

## 4. Evidence boundaries

- **Tiny samples for the main claim.** Seven tasks for the framework comparison, two for the role ablation, five for the backend comparison. No variance is reported.
- **Human scoring.** Executability and revisions are rated by people, and the scale is coarse.
- **Inconsistent summaries.** Table 4 gives per-task executability averaging 3.9 for MetaGPT and 2.1 for ChatDev [1, App. C.2, Table 4], while Table 1 gives 3.75 and 2.25 for what appears to be the same comparison.
- **The smallest backend, Deepseek Coder 33B, scored 1.4 of 4.** The pipeline did not make a weaker model produce working projects. [1, Table 5]
- **No front-end or UI work** is supported. [1, App. D.1]
- **The HumanEval and MBPP numbers are single-function results** and say little about the SOP itself.

## 5. What we take from it

Our interpretation, not the paper's claims.

- What transfers to one model plus a harness is the typed hand-off: each phase reads named input documents and must produce a named output with a fixed schema that the harness can check.
- Subscription by role is the same idea as per-phase context selection; the implement phase should get the task and the interface it touches, not the requirements discussion.
- Agreeing interfaces before coding is what lets tasks be implemented and resumed separately.
- The 33B result is a warning that procedure alone does not close the gap for a small model; harness-side checks have to carry more of the load.

## Reference

[1] Sirui Hong, Mingchen Zhuge, Jiaqi Chen, Xiawu Zheng, Yuheng Cheng, Ceyao Zhang, Jinlin Wang, Zili Wang, Steven Ka Shing Yau, Zijuan Lin, Liyang Zhou, Chenyu Ran, Lingfeng Xiao, Chenglin Wu, Jürgen Schmidhuber. *MetaGPT: Meta Programming for a Multi-Agent Collaborative Framework.* ICLR 2024. arXiv:2308.00352v7. <https://arxiv.org/html/2308.00352>. Code: <https://github.com/geekan/MetaGPT>. Accessed 2026-11-11.
