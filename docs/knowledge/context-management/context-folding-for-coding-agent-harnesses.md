# Context Folding for Long-Lived Coding Agents

An implementation-oriented knowledge article based on billion-context [1].

## 1. Problem: Long Workflows, Finite Working Context

A coding agent may spend days investigating, editing, testing, and revisiting a repository. Its history contains user requirements, tool calls, file contents, errors, failed attempts, and decisions. That history eventually exceeds the model's context window.

Billions of *cumulative input tokens* do not mean billions of tokens are present in a single request. Cumulative accounting can include the same historical tokens read repeatedly across calls, including cache reads. The practical problem is to keep each request bounded while maintaining continuity across a much longer workflow. [1, §§1, 6–7]

Whole-history compaction can lose exact paths, significant tool arguments, error strings, test results, and the reasoning behind a decision. Repeatedly summarizing a previous summary can further erode details. Yet retaining every log line also creates cost and distraction. A detail that looks incidental now may become necessary later.

The useful design goal is therefore twofold: maintain a compact working representation, and preserve a reliable route back to the original evidence.

## 2. Core Method: Incremental Folding with Recoverable Sources

The paper calls its arrangement a **fold**: older, consumed work is represented by summary blocks, while recent work remains verbatim. A fold replaces a selected range in the model-visible history; it does not delete the underlying source records. [1, §§3.1–3.2]

Three properties matter:

1. **Incremental scope.** Fold selected completed work rather than rewriting the entire session on every compression.
2. **Task-aware judgment.** The model chooses useful compression boundaries and summary content based on the current task.
3. **Recoverable lineage.** Each summary identifies its source messages or source blocks, allowing later recovery.

The model writes summaries and makes semantic judgments. The harness manages identity, storage, eligibility, budgets, and rendering. A prompt alone cannot enforce these invariants.

In this article, *unfold* means recovering a block's sources. The paper's operation is named `decompress`; its file-based alternative is `decompress-to-file`.

## 3. When to Fold

### Routine checks are not routine compression

The harness may evaluate context on every turn without generating a summary on every turn. A turn can contain several assistant and tool messages; compression should address stable message IDs rather than rely on turn numbers.

Use three distinct paths:

| Path | Trigger | Decision |
| --- | --- | --- |
| Model-initiated | The agent recognizes a completed phase or obsolete investigation material | Model proposes a fold; harness validates eligibility |
| Harness nudge | Context pressure and sufficient growth since the last fold | Harness supplies candidates; model may fold or defer |
| Emergency protection | The next request risks exceeding the usable budget | Harness enforces its configured overflow policy |

The paper's normal nudge uses both a context floor and a growth gate. Its default context floor is approximately 45% of the window; its growth mechanism describes a roughly 50K-token threshold with a lower effective floor in some cases. These are reference settings, not universal constants. The paper also has separate emergency paths. [1, §§3.3–3.4, 4, 5]

**Crossing a normal threshold does not force immediate summarization.** A model can defer while a debugging or refactoring step still needs the source material. Conversely, it can initiate compression without a nudge. [1, §3.7]

For an independent harness, select thresholds from the usable input budget after reserving space for output, tool growth, and fixed instructions. Also set a minimum worthwhile range size so compression does not repeatedly interrupt the task for negligible savings.

### Candidate selection

Supply a short list of eligible ranges with their IDs, token estimates, message counts, and tool/text composition. The model should not have to guess which ranges exist or how large they are. Protect the current task, recent work, and key user instructions through harness rules; do not rely entirely on the model to respect exclusions. [1, §§3.3, 4]

Good boundaries include a finished investigation, a validated change, or a superseded approach with a recorded lesson. Age and size alone do not establish that a range is safe to fold. A growth gate is a useful timing signal, not proof that the work is complete.

## 4. What a Fold Produces

The paper stores summaries in structured compression blocks with stable IDs, tiers, source references, lifecycle state, and summary text. It does not require one summary per turn. [1, §3.2]

The following is a **suggested schema for an independent implementation**, not the paper's exact API:

```typescript
type ContextBlock = {
  id: string;
  tier: number;
  topic: string;
  summary: string;
  sourceMessageIds: string[];
  sourceBlockIds: string[];
  active: boolean;
  createdAt: string;
};
```

Keep immutable messages and block records outside the rendered request. Source references must resolve transitively: if block C summarizes A and B, recovering C must still reach the original messages behind A and B. A cached set of effective message IDs can speed this up but is not necessary for a first implementation.

A practical summary body can use these fields:

```markdown
### Task state
Current goal, completed scope, remaining work, and user constraints.

### Decisions and evidence
Decision, reason, significant alternatives, and supporting message IDs.

### Artifacts and verification
Exact paths, relevant symbols, significant commands/tool arguments,
results, and limitations of verification.

### Open issues
Unresolved questions, risks, and next required action.

### Recovery references
Block ID and source range or child-block IDs.
```

This template is a design suggestion. The paper's essential KEEP/DROP policy is to preserve task intent, exact technical anchors, decisions and rationale, and recovery references, while removing redundant logs and exploration whose useful conclusion has already been captured. [1, §4]

Preserve tool calls selectively: retain the operation and arguments when they explain or reproduce a result. A list of tool names without outcomes is insufficient; preserving every invocation defeats compression. Distinguish observed results from assumptions, and distinguish tests that passed from tests that were never run.

## 5. Fold Lifecycle

An independent harness can implement a fold as a transactional update:

1. Assign stable IDs when messages enter the session and persist their original content.
2. Compute eligible ranges, excluding protected messages and preserving valid tool-call/result structure.
3. Let the model select a range and write a summary while the source content is available.
4. Validate the references, protection rules, summary budget, and current state version.
5. Persist the block and its lineage before removing source content from the rendered view.
6. Activate the summary representation, deactivate the selected sources in that view, and update growth accounting.

The transaction and state-version check are implementation recommendations: they prevent a failed or stale compression from hiding evidence without a usable replacement. If validation fails, keep the existing view.

The active request now contains protected instructions, active summaries, and recent raw messages. Older blocks remain independently addressable; a subsequent fold normally adds another block instead of rewriting every existing block.

When summary mass itself becomes large, selected Tier 1 blocks can become a Tier 2 block; Tier 2 blocks can later become Tier 3. The parent keeps references to its children. This is the paper's multi-generational design. It reduces repeated whole-history rewriting, but does not make summaries immune to information loss during higher-tier consolidation. [1, §§3.2, 4]

## 6. Unfold and Recovery

Recovery has two useful forms:

| Mode | Operation | Trade-off |
| --- | --- | --- |
| In-context unfold | Reactivate a block's sources and deactivate its summary | Direct access, but increased input size and possible cache disruption |
| Restore to file | Write original source content to a file for targeted reading | Keeps the conversation layout stable; reading excerpts still consumes tokens |

Both are described in the paper. Recovery succeeds because the source text still exists, not because a summary can reconstruct omitted details. [1, §3.2]

For a custom harness, expose a small interface such as:

```typescript
searchHistory(query): BlockMatch[]
restoreBlock(blockId, { mode: "file" | "context" }): RestoreResult
```

These names and signatures are illustrative. Return source IDs and clear provenance with recovered content. Bound restoration so a large block cannot silently overflow the next request.

Teach the agent to recover when an exact identifier, conflicting decision, or missing constraint matters. Tool availability alone is insufficient: the paper observed successful recovery when explicitly requested, but no spontaneous adoption in its pilot. [1, §8.1]

## 7. Example: A Multi-Stage Repository Migration

The following sequence is illustrative; turn counts are not trigger settings. The initial user instruction remains protected throughout.

| Point | Model-visible working history |
| --- | --- |
| Turn 3 | Original messages from turns 1–2; no summaries yet |
| After first fold | Protected instruction + A summarizing eligible messages from turns 2–12 + remaining raw messages |
| After second fold | Protected instruction + A + B summarizing a later completed phase + recent raw messages |
| After tier promotion | Protected instruction + C summarizing A and B + recent raw messages |

Suppose A records an endpoint investigation:

```markdown
BLOCK A — Endpoint investigation complete
- Goal: migrate POST /orders while preserving legacy validation.
- Artifact: src/orders/OrderController.java, createOrder(...).
- Finding: the legacy route rejects missing customerId before DB access.
- Evidence: m00120–m00147; preserve exact error text in source.
- Decision: reproduce validation before moving persistence logic.
- Verification: inspection only; integration tests have not run.
```

B later records implementation and test evidence. It does not need to rewrite A. If C eventually combines A and B, it retains their IDs as lineage.

At turn 90, a test requires the exact legacy error string omitted from the active summary. The agent locates A, restores its source to a file, reads the relevant messages, and uses the original string. It does not guess from the summary or reopen an already completed investigation without checking the saved evidence.

## 8. Cache Behavior and Evaluation

The paper emphasizes avoiding whole-history rewrites to preserve a stable cacheable prefix. For a new harness, treat cache preservation as a property to measure, not a consequence of merely saving append-only logs. Provider caching operates on the actual serialized request: inserting or changing early summary text can invalidate the following prefix. File-based recovery avoids one form of history expansion, but does not make subsequent reads free. [1, §§3.6, 6.3]

A minimal implementation should measure:

- Mean/peak rendered context, overflow events, and compression overhead.
- Cached versus uncached input and actual billed cost.
- Task completion, execution errors, and preservation of early requirements.
- Repeated file/tool reads and successful recovery of exact source details.
- Compression deferrals, failed proposals, and restoration frequency.

Compare against ordinary compaction and full-history retention where feasible. Include phase-dependent tasks whose initial instructions are not repeated. Test recovery separately from recall through summaries, and exercise higher-tier folding explicitly.

## 9. Evidence Boundaries

The paper provides production observations and a controlled pilot, not a general guarantee of lossless task performance. Its large cumulative-token figures include repeated reads. Its 28.6B-token single-session capacity is a simulation using a 1M-token window, not an observed run. The pilot did not exercise Tier 2+ compression, and nearly all of the headline re-fetch reduction was reproduced by the doctrine and message tags without actual compression. [1, §§7–9]

The transferable engineering contribution is the combination of selective folding, explicit summary policy, protected working context, and recoverable lineage. Implement those invariants first; tune thresholds, tier counts, and prompt wording against the workloads of the new harness.

## Reference

[1] Xianglei Ran. *Model-Driven Incremental Hierarchical Compression: Training-Free Multi-Generational Context Management for Long-Lived Coding Agents*. Preprint v0.2, September 7, 2026. Living document, MIT-licensed. [Original article](https://github.com/ranxianglei/billion-context/blob/master/paper/model-driven-incremental-hierarchical-compression-training-free-multi-generational-context-management-for-long-lived-coding-agents.md). Accessed November 11, 2026. Section references refer to the version reviewed for this article.
