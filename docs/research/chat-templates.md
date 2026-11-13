# Chat templates: how earlier reasoning is rendered

Read on 2026-11-12 from files on the development machine.

| Template | File | Reasoning of earlier assistant turns | Generation prefix |
|---|---|---|---|
| Qwen 3.5 (as shipped with llama.cpp) | `~/.unsloth/llama.cpp/models/templates/Qwen3.5-4B.jinja` | Kept only for turns after the last real user message (the current tool loop). Older turns are rendered without a think block. | `<think>\n`, or an empty think block when `enable_thinking` is false |
| Ornith 1.5 9B (base) | HF cache, `ornith-ai/Ornith-1.5-9B/chat_template.jinja` (both cached snapshots identical) | **Kept for every turn.** Each assistant turn is rendered as `<think>\n{reasoning}\n</think>\n\n{content}`; with no reasoning the think block is empty. | Same as Qwen 3.5 |
| JacLLM v1.35 and the trajectory SFT model | `JacLLM/output/model/JacLLM-SFT-Ornith-9B-v1.35-*/chat_template.jinja` | Ornith template plus two lines that force `enable_thinking = false` | Always the empty think block |
| JacLLM CPT v1.3A | `JacLLM-CPT-Ornith-9B-v1.3A-bf16/chat_template.jinja` | Identical to Ornith base | |

The only difference between the Ornith and Qwen 3.5 templates is the one condition on earlier reasoning (line 100 of the Ornith file).

Consequences for Jach:

- An agent run is one user message followed by many tool turns, so every turn is "after the last user message". Under both templates all reasoning of the run stays in the prompt by default. Nothing in the templates removes it.
- The harness decides what it sends. If it sends an earlier assistant turn without reasoning, the Ornith template renders an empty think block for it.
- Dropping earlier reasoning (0007) is therefore a change from what the existing adapters saw in training. It is safe only if the training trajectories are rendered the same way: earlier turns with an empty think block, the target turn with its reasoning.
- The 1112 adapter's template is on the training machine and was not read here.
