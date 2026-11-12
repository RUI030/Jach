# Typed State, Conditional Edges and Checkpoints at Step Boundaries

A method note based on the LangGraph documentation [1, 2, 3].

- **Evidence:** C. Official framework documentation. Reliable for how LangGraph behaves; not evidence that structuring an agent this way works better.
- **Numbers checked against the source:** yes, 2026-11-11, against the Markdown versions of the three pages served by docs.langchain.com. The only numbers are defaults and limits.

## 1. Problem

An agent workflow with several stages needs a shared state, rules for what runs next, and a way to stop and resume: after a crash, after a human approves a step, or to replay history. LangGraph is a framework that provides these as a graph with persisted state. [1, "Graphs"; 2]

## 2. Method

A graph has three parts. [1, "Graphs"]

- **State**: a shared, usually typed, schema.
- **Nodes**: functions that read state, do work and return a partial update.
- **Edges**: fixed (A then B) or conditional (a routing function reads state and names the next node). A node can also return a `Command` that carries a state update and the next node together. [1, "Edges", "Command"]

The graph must be compiled before use; compilation checks structure, for example orphaned nodes, and attaches the checkpointer. [1, "Compiling your graph"]

### Key decisions

1. **Every state key has a merge rule.** By default a node's update overwrites the key. A reducer, a function of (current value, update), can combine them instead, for example by appending to a list. [1, "Reducers"]
2. **Execution runs in super-steps.** Nodes that run in parallel share a super-step; sequential nodes use separate ones. The run ends when no node has pending input. [1, "Super-steps"]
3. **Checkpoints at super-step boundaries, not inside a node.** A checkpointer saves the state of a thread, keyed by `thread_id`, after each super-step. [1, "Re-execution and idempotency"; 3, "Checkpoints"]
4. **Thread state and cross-thread memory are separate.** Checkpointers hold one thread's state; stores hold application data shared across threads. [2, "Checkpointer vs. store"]

### Implementation details that generalise

- **A resumed node restarts from its beginning.** After an interrupt or retry, side effects before the pause run again, so node logic should be idempotent (idempotency keys, upserts, read-before-write). [1, "Re-execution and idempotency"]
- **A node is the checkpoint and retry boundary.** The docs advise making a step its own node when a routing decision may follow it or when it needs an interrupt or resume point; deterministic work can stay inside a node. [1, "Choose the unit of work"]
- **Completed parallel work is kept.** If one node fails in a super-step, writes from the nodes that succeeded in that step are stored and not re-run on resume. [3, "Why use checkpointers"]
- **Resume, new input and replay are different calls.** Invoking with no input continues unfinished work; new input is merged into saved state through the reducers; replay from an earlier checkpoint re-runs every later node, including model calls. [3, "Choose how to continue a thread", "Replay"]
- **Durability is a choice.** `exit` writes only when the run ends, `async` writes while the next step runs, `sync` writes before the next step starts. Only `sync` guarantees every checkpoint is written before continuing. [3, "Durability modes"]
- **Recursion limit.** A cap on super-steps per run raises `GraphRecursionError` when exceeded; the default is 10,007 from version 1.1.4. [1, "Recursion limit"]
- **Checkpoints grow without bound** on long threads and need pruning or a retention policy. In-memory checkpointers lose everything on restart. [2, "Troubleshooting common issues"]
- **Subgraphs have their own checkpoint namespace**, so a parent may not see a subgraph's state change at once. [2, "Troubleshooting common issues"; 3, "Checkpoint namespace"]

## 3. Evidence

None in the sense of this folder. The pages describe behaviour and defaults; they report no comparison of agents built this way against agents built otherwise.

## 4. Evidence boundaries

- **Framework semantics only.** Nothing here says which graph shape, state design or step granularity gives better agent results.
- **Model-agnostic.** The docs do not address small models, tool-call formats or how a model should be prompted at each node.
- **The default step limit is a safety net, not a loop guard.** At about ten thousand super-steps it stops runaway graphs, not an agent repeating itself a dozen times.
- **Version-dependent.** Defaults such as the recursion limit changed between releases. [1, "Recursion limit"]

## 5. What we take from it

Our interpretation, not the documentation's claims.

- The six JacKnife phases map onto nodes, and transitions onto conditional edges decided by harness checks (tests passed, file exists), not by model output alone.
- The harness state should be declared with explicit merge rules: task list updated by id, fold index appended, current task overwritten. That makes checkpoint and resume mechanical.
- Checkpoint at each phase transition and after each tool execution, and make every step safe to re-run. Re-running tests is; appending to a file is not unless guarded.
- A per-task step limit in the tens, not thousands, is our loop guard; LangGraph's default is far too high for that role. JacKnife does not need LangGraph itself; these concepts are small enough to implement directly in Jac.

## Reference

[1] LangChain. *Graph API overview.* <https://docs.langchain.com/oss/python/langgraph/graph-api> (Markdown at `graph-api.md`). Undated. Accessed 2026-11-11.

[2] LangChain. *Persistence.* <https://docs.langchain.com/oss/python/langgraph/persistence>. Undated. Accessed 2026-11-11.

[3] LangChain. *Checkpointers.* <https://docs.langchain.com/oss/python/langgraph/checkpointers>. Undated. Accessed 2026-11-11.
