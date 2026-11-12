# MemGPT: Towards LLMs as Operating Systems

- **Source:** https://arxiv.org/html/2310.08560v2 (abstract: https://arxiv.org/abs/2310.08560)
- **Authors / org:** Charles Packer, Sarah Wooders, Kevin Lin, Vivian Fang, Shishir G. Patil, Ion Stoica, Joseph E. Gonzalez
- **Date:** 2023-10-12 (v2 2024-02-12)
- **Type:** paper
- **Read:** full text

## Summary

MemGPT applies the operating-system idea of virtual memory to an LLM's prompt. The prompt ("main context") has three fixed regions: read-only system instructions that explain the memory system and its functions; a fixed-size, writable "working context" for durable facts; and a FIFO queue of recent messages, tool calls and results. The first item in the queue is a recursive summary of everything already evicted.

Outside the prompt there are two stores. Recall storage holds the complete message history; every message is written there automatically. Archival storage is a general read/write database for arbitrary text. The model moves data between tiers by calling functions (search recall, search archival, insert, edit working context). Search results are paginated so that a retrieval cannot overflow the window.

A queue manager enforces limits. At a warning threshold (about 70% of the window) it inserts a "memory pressure" system message so the model can save what matters. At the flush threshold it evicts a share of the queue (about 50%) and regenerates the recursive summary from the old summary plus the evicted messages. Evicted messages remain retrievable from recall storage. A `request_heartbeat` flag lets the model chain several function calls before yielding.

Evaluation covers multi-session chat and document analysis. On deep memory retrieval, accuracy rose from 32.1% to 92.5% with GPT-4. On nested key-value lookup, plain GPT-4 fell to 0% at three nesting levels while MemGPT stayed stable. With GPT-3.5 results were much weaker because of unreliable function calling, and the model often stopped paging through results too early. Test sets are small (tens of items).

## Key points

- Three tiers: in-prompt working memory, full searchable history, and a separate archive.
- Eviction never destroys data; the full history stays searchable.
- The harness warns the model before eviction so it can save state.
- Retrieval is paginated to protect the window.
- Quality of self-managed memory depends heavily on function-calling reliability; the weaker model did poorly.

## Relevance to JacKnife

(Our interpretation.)

- JacKnife's unfold-by-id is recall storage with direct addressing instead of search. Direct ids are simpler for a small model than composing search queries.
- Paginate or cap unfold output. Unfolding a 12k-token test log into a 16k budget would defeat the design; return a window with an offset parameter.
- A small fixed "working context" block (current task, acceptance criteria, key decisions) that is never folded is a useful complement to folded history.
- The GPT-3.5 result is a warning: a 9B model may under-use memory tools. Prefer harness-driven folding and reserve model-driven actions for unfold only.
