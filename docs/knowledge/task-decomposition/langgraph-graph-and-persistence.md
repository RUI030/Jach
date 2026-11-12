# LangGraph: Graph API and persistence

- **Source:** https://docs.langchain.com/oss/python/langgraph/graph-api and https://docs.langchain.com/oss/python/langgraph/persistence
- **Authors / org:** LangChain
- **Date:** undated living documentation (fetched 2026-11-11)
- **Type:** docs
- **Read:** both pages in full. The dedicated durable-execution page could not be retrieved (the URL served the persistence overview), so durability modes and replay rules are not covered here.

## Summary

LangGraph models an agent workflow as a graph with three parts: a shared state object, nodes that do work, and edges that choose what runs next.

State is a typed schema. Each key is a channel with a merge rule: by default a node's update overwrites the old value; a reducer function (for example list append, or the message reducer that appends and updates by id) combines old and new instead. Nodes are functions that read the state and return a partial update. Edges are either fixed (A then B) or conditional (a routing function inspects state and returns the next node). A node can also return a `Command` that carries a state update and the next node together. The graph is compiled before use; compilation checks structure (for example orphaned nodes) and attaches runtime options.

Execution proceeds in discrete "super-steps": nodes scheduled together run in one step, and the run ends when no node has pending input. A recursion limit caps the number of super-steps and raises an error when exceeded.

Persistence has two parts. A checkpointer saves the graph state for a thread (identified by a `thread_id`) at super-step boundaries; this provides conversation continuity, human-in-the-loop pauses, time travel and recovery after failure. A store holds application-defined key-value data across threads, for long-term memory. Backends named are in-memory (lost on restart), SQLite (local) and Postgres (production).

Two operational notes from the docs matter for design. After an interrupt or retry the affected node re-runs from its beginning, so side effects inside a node should be idempotent. Checkpoints accumulate without bound over long threads and need pruning or a retention policy. Subgraphs keep their own checkpoint namespace, so a parent may not see a subgraph's state immediately.

## Key points

- Workflow = typed shared state + nodes + fixed or conditional edges.
- Every state key has an explicit merge rule.
- State is checkpointed at step boundaries, keyed by a thread id.
- Resume restarts the interrupted node from its start, so nodes must be idempotent.
- A step limit guards against infinite loops.
- Thread-scoped checkpoints and cross-thread stores are separate mechanisms.

## Relevance to JacKnife

(Our interpretation.)

- The six JacKnife states are nodes; transitions are conditional edges decided by harness checks (tests passed, file exists), not by model output alone.
- Define the harness state explicitly with merge rules: task list (update by id), fold index (append), current task (overwrite). This makes checkpoint and resume mechanical.
- Checkpoint at each state transition and after each completed execution. On resume, restart the current step from its beginning, which requires steps to be idempotent (re-running tests is; appending to a file is not unless guarded).
- A per-task step limit is the simplest guard against a small model looping in debug.
- JacKnife does not need LangGraph itself; the concepts are small enough to implement directly in Jac.
