# Tiered Agent Memory with Eviction, Pressure Warnings and Paged Recall

A method note based on MemGPT [1].

- **Evidence:** B. Controlled comparisons against the same base models without the memory system; preprint; small test sets (50 questions, 30 orderings); no error bars; API models only.
- **Numbers checked against the source:** yes, 2026-11-11, against the arXiv HTML (v2).

## 1. Problem

A fixed context window cannot hold a months-long conversation or a document set larger than the window. Recursive summarisation keeps something but loses detail. The paper borrows virtual memory from operating systems: keep a small working set in the prompt and page the rest in and out on demand. [1, §1, §2]

## 2. Method

The prompt ("main context") has three contiguous regions [1, §2.1]:

| Region | Contents | Writable |
|---|---|---|
| System instructions | How the memory tiers and functions work | No |
| Working context | Fixed-size block for durable facts | Only via function calls |
| FIFO queue | Recent messages, system warnings, function calls and results; first item is a recursive summary of evicted messages | Managed by the queue manager |

Outside the prompt are two stores. *Recall storage* holds every message; the queue manager writes each one there automatically. *Archival storage* is a read/write database for arbitrary text. The model moves data with function calls. [1, §2.2–2.3]

### Key decisions

1. **Eviction never destroys data.** Evicted messages stay in recall storage and can be searched back. [1, §2.2]
2. **Warn before evicting.** When the prompt passes a warning threshold (example given: 70% of the window), a "memory pressure" system message lets the model save what matters. [1, §2.2]
3. **Flush at the limit.** At the flush threshold (example: 100%), the manager evicts messages (example: 50% of the window) and writes a new recursive summary from the old summary plus the evicted messages. [1, §2.2]
4. **Memory management is self-directed.** The model decides what to store and retrieve, guided by the system instructions and function schemas. [1, §2.3]

### Implementation details that generalise

- Retrieval results are paginated so that a single retrieval cannot overflow the window. [1, §2.3]
- Runtime errors from memory functions (for example, writing to a full working context) are fed back to the model. [1, §2.3]
- A `request_heartbeat=true` argument lets the model chain several function calls before yielding, which multi-page retrieval needs. [1, §1, §2.4]

## 3. Evidence

Models: GPT-3.5 Turbo (16K), GPT-4 (8K), GPT-4 Turbo (128K). [1, §3]

Deep memory retrieval on Multi-Session Chat; the baselines see a lossy summary of the five earlier sessions, MemGPT sees full history through paginated search. [1, §3.1.1, Table 2]

| Model | Accuracy | + MemGPT |
|---|---|---|
| GPT-3.5 Turbo | 38.7% | 66.9% |
| GPT-4 | 32.1% | 92.5% |
| GPT-4 Turbo | 35.3% | 93.4% |

- **Document QA** (50 NaturalQuestions-Open questions): fixed-context baselines are capped near retriever quality; MemGPT can page further. MemGPT often stopped paging before exhausting the retriever results. MemGPT with GPT-3.5 was much worse, which the authors attribute to its function calling. [1, §3.2.1, Fig. 5]
- **Nested key-value lookup** (140 UUID pairs, about 8K tokens, 30 orderings, 0 to 4 nesting levels): GPT-3.5 hit 0% at one nesting level; GPT-4 and GPT-4 Turbo hit 0% by three. MemGPT with GPT-4 was unaffected by nesting depth. MemGPT with GPT-4 Turbo or GPT-3.5 improved on their baselines but began to drop at two levels, because they did not perform enough lookups. [1, §3.2.2, Fig. 7]

## 4. Evidence boundaries

- **Small test sets and no variance.** 50 questions for document QA and 30 configurations for nested KV.
- **The thresholds (70%, 100%, 50%) are examples**, not tuned or ablated.
- **No coding or tool-heavy agent tasks.** Results are chat memory and retrieval.
- **No open-weights models were run**; the weakest model, GPT-3.5, is where self-directed memory broke down.
- The DMR baseline gets a lossy summary, so the comparison is "search over full history" against "summary", not against a long context.

## 5. What we take from it

Our interpretation, not the paper's claims.

- Unfold-by-id is recall storage with direct addressing instead of search. Direct ids ask less of a small model than composing search queries.
- Unfold output should be paged or capped. A 12k-token test log unfolded into a 16k budget would defeat the design; return a window with an offset.
- A small never-folded block (current task, acceptance criteria, key decisions) corresponds to working context and should be written by the harness.
- The weakest model failed at self-directed paging. Folding should be harness-driven, with only unfold left to the model, and unfold use should be measured since our model already rarely loads documentation on its own.

## Reference

[1] Charles Packer, Sarah Wooders, Kevin Lin, Vivian Fang, Shishir G. Patil, Ion Stoica, Joseph E. Gonzalez (UC Berkeley). *MemGPT: Towards LLMs as Operating Systems.* arXiv:2310.08560v2, 2024-02-12. <https://arxiv.org/html/2310.08560v2>. Accessed 2026-11-11.
