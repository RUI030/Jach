# Ideas

Raw ideas land here first, so nothing said in discussion is lost and nothing unexamined slips into the design.

## How an idea moves

```
said in discussion → inbox.md → discussed → decisions/NNNN-*.md
                                         ↘ parked or dropped (with the reason)
```

1. **Capture.** Every idea goes into [inbox.md](inbox.md) as one row, close to the original wording, even if half-formed.
2. **Link.** Each row points at the open decision it bears on (the numbers in [../README.md](../README.md)). An idea that fits none of them means a decision is missing from the list.
3. **Resolve.** When a decision is recorded, every idea that fed it is marked `decided` with a link. Ideas that were rejected are marked `dropped` with one line on why.

## Status values

| Status | Meaning |
|---|---|
| `new` | Captured, not yet discussed |
| `discussing` | Being discussed now |
| `decided` | Settled; see the linked decision record |
| `parked` | Worth keeping, not needed yet |
| `dropped` | Rejected; the reason is in the row |

## Rules

- Rows are never deleted. A dropped idea stays, with its reason, so it is not proposed again.
- The inbox holds ideas, not conclusions. Reasoning and trade-offs belong in the decision record.
