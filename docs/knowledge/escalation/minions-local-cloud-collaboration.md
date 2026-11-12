# Minions: Cost-efficient Collaboration Between On-device and Cloud Language Models

- **Source:** https://arxiv.org/html/2502.15964
- **Authors / org:** Avanika Narayan, Dan Biderman, Sabri Eyuboglu, Avner May, Scott Linderman, James Zou, Christopher Ré (Stanford University; Together AI)
- **Date:** 21 February 2025
- **Type:** paper
- **Read:** first ~100k characters of the HTML (main text and early appendices; the final ~59k characters were not read)

## Summary

The setting is a small local model that can read a long document for free and a cloud model that is expensive per token. Two protocols are compared on long-document question answering (finance, medical, scientific).

In Minion, the two models simply chat: the local model holds the document, the cloud model holds the question and asks for what it needs. This cuts cloud cost about 30x but recovers only 87% of the cloud model's accuracy. The authors trace the loss to two weaknesses of the small model. It handles multi-step instructions badly: splitting a compound instruction into separate requests improved its performance by about 56 points. And it degrades on long context: going from under 1K to over 65K tokens cost about 13% on a simple extraction task.

MinionS is designed around those weaknesses. The cloud model, without seeing the document, writes code that decomposes the task into single-step jobs over small chunks. The local model runs the jobs in parallel and may abstain on irrelevant chunks. The cloud model aggregates the filtered outputs and either answers or starts another round. With an 8B local model and GPT-4o this recovered 97.9% of cloud-only accuracy at 18.0% of the cost; a 3B local model reached roughly 91-93% (the paper's text and table differ slightly). At 1B the protocol recovered only about half.

Ablations show a cost-quality dial: more rounds, more jobs per round and smaller chunks all help up to a point (gains reverse beyond about 16 jobs or samples per round) and all raise cloud cost. Local compute is treated as free and latency is modelled rather than measured.

## Key points

- Free-form chat between a small and a large model underperforms structured decomposition.
- Two measured small-model weaknesses: compound instructions (about 56 points) and long context (about 13%).
- The large model never needs the full context; it writes the decomposition and aggregates.
- 8B local model: ~98% of cloud quality at ~18% of cost. Below about 3B the scheme stops being competitive.
- Letting the small model abstain, then filtering, is part of the protocol.

## Relevance to JacKnife

(Our interpretation, not the source's claims.)

- Supports the harness-owned state machine: give the 9B model one single-step task with a short, relevant context, and let something else do decomposition and aggregation.
- The admin can be used as planner (write the task list and acceptance criteria) without ever reading the whole repository, which keeps its token cost low.
- Task descriptions for the small model should be single-step. If an acceptance criterion needs "do A, then B, then verify C", split it.
- An explicit "cannot do this / not applicable" output for the small model, filtered by the harness, is preferable to forcing an answer; it is also a cheap escalation signal.
- The domain is document QA, not coding; the specific numbers do not transfer.
