# Agent-Computer Interface Design: Few Commands, Bounded Output, Edit Guardrails

A method note based on SWE-agent [1].

- **Evidence:** A. Controlled ablations with public code and data, peer-reviewed (NeurIPS 2024; venue from general knowledge, not confirmed in the source text) and used as the base of much later work; but every ablation is one run with one closed model on 300 tasks.
- **Numbers checked against the source:** yes, 2026-11-11, against the full arXiv HTML (v3), including the appendix.

## 1. Problem

A model driving a plain shell explores inefficiently, floods its context with long `grep` output, and edits through `sed` or redirection with no feedback on whether the edit worked. The paper asks whether an interface built for the model, with the model fixed, changes how many software-engineering tasks it solves. [1, §1, §5.1]

## 2. Method

The agent-computer interface (ACI) is a small command set on top of the shell. At each step the model writes a thought and one command, then sees the result. [1, §3]

| Component | Design |
|---|---|
| Search | `find_file`, `search_file`, `search_dir` return a summary list; more than 50 hits returns nothing and asks for a narrower query. |
| File viewer | Shows at most 100 lines with line numbers, the file path, total length and lines omitted above and below. |
| Editor | `edit start end text` replaces a line range in the open file, then shows the updated region. |
| Guardrail | After each edit a linter runs; an edit that introduces a syntax error is reverted and the model is told why. |
| Context | Observations older than the last 5 are collapsed to one line; an empty output becomes an explicit "ran successfully and did not produce any output". |

### Key decisions

1. **Few, simple commands with short documentation.** Each command does one meaningful step, so the model does not chain many shell calls.
2. **Ground edits in what the model sees.** The edit takes the line numbers printed by the viewer, which the authors say removes the arithmetic models get wrong with `sed`. [1, §A.1]
3. **Reject bad edits before they land.** The linter checks only syntax-level codes (undefined names, indentation, syntax errors), on the assumption that the original code was well-formed. [1, §A.1]
4. **Show three things on rejection.** The error, the edit as it would have looked, and the original snippet. In development, dropping the proposed-edit snippet made the agent reissue the same command more often; dropping the original snippet led to edits against stale content. [1, §A.1, Fig. 11]
5. **Bound every output.** Capped search and a fixed viewer window keep observations short.

### Implementation details that generalise

- Malformed generations get an error and a retry; once a valid one arrives, all but the first error message are removed from history. [1, §3]
- The edit command's own documentation says that issuing the same command will return the same error. [1, Table 4]

## 3. Evidence

GPT-4 Turbo, SWE-bench Lite (300 tasks) unless stated. [1, §4, Table 1, Table 3]

| Setting | % resolved |
|---|---|
| RAG, no interaction | 2.67 |
| Shell only | 11.00 |
| SWE-agent (full ACI) | 18.00 |
| SWE-agent, full SWE-bench (2,294 tasks) | 12.47 |

Ablations from 18.0 [1, §5.1, Table 3]:

| Change | % resolved |
|---|---|
| No edit command | 10.3 |
| Edit without linting | 15.0 |
| Iterative search (one hit at a time) | 12.0 |
| No search commands | 15.7 |
| 30-line viewer / whole-file viewer | 14.3 / 12.7 |
| Full history instead of last 5 observations | 15.0 |
| No demonstration | 16.3 |

- Six repeat runs of the full configuration gave 17.94 ± 0.49; pass@6 was 32.67. [1, §B.5, Table 10]
- The 64% relative gain over shell-only is with the same model. [1, §5]
- 51.7% of full-benchmark trajectories (1,185 of 2,294) had at least one failed edit. Any edit attempt eventually succeeded 90.5% of the time; after one failed edit, 57.2%. [1, §5.2]
- Of 248 unresolved Lite runs, 52.0% were incorrect or overly specific implementations and 23.4% cascading failed edits. Labels came from GPT-4o, which agreed with the authors on 87% of a hand-labelled set. [1, §5.2, Fig. 8]

## 4. Evidence boundaries

- **Only two closed models were reported** (GPT-4 Turbo, Claude 3 Opus). Llama 3 and DeepSeek Coder were tried and called "subpar"; no numbers are given. [1, §4]
- Each ablation is a single run. With a six-run spread of about ±0.5, the larger drops (3 to 8 points) are clear; the 1.7-point demonstration effect is less certain.
- The 90.5% to 57.2% recovery figures describe GPT-4 Turbo, not a 9B model. The paper does not measure recovery after the guardrail was removed.
- Python only; the linter assumes the starting code parses.

## 5. What we take from it

Our interpretation, not the paper's claims.

- Our model misuses a zero-based offset. SWE-agent avoids that arithmetic altogether: the edit takes the line numbers the viewer prints. Making our edit and view tools take displayed line numbers, not offsets, is the first fix to try.
- Rejecting an edit that does not parse, inside the edit tool, fits our unfixed-syntax-error failure. The rejection should show the error, the would-be result and the original.
- The drop in recovery after one failed edit says the first failure is when the harness should act. For a model that never self-corrects, waiting for a third failure gains nothing.

## Reference

[1] John Yang, Carlos E. Jimenez, Alexander Wettig, Kilian Lieret, Shunyu Yao, Karthik Narasimhan, Ofir Press (Princeton University). *SWE-agent: Agent-Computer Interfaces Enable Automated Software Engineering.* arXiv:2405.15793. <https://arxiv.org/html/2405.15793>. Code: <https://swe-agent.com>. Accessed 2026-11-11.
