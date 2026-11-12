# Less is More: Optimizing Function Calling for LLM Execution on Edge Devices

- **Source:** https://arxiv.org/html/2411.15399
- **Authors / org:** Varatheepan Paramanayakam, Andreas Karatzas, Iraklis Anagnostopoulos (Southern Illinois University), Dimitrios Stamoulis (University of Texas at Austin)
- **Date:** 23 November 2024
- **Type:** paper
- **Read:** full text

## Summary

The paper tests a simple idea for small local models: show the model fewer tools. It requires no fine-tuning. At run time the model is first given the user query with no tools and asked to describe the tools it would ideally need. Those descriptions are embedded and matched by nearest-neighbour search against two precomputed indexes: individual tools, and clusters of tools that tend to be used together. The harness then exposes only the top matches (k of 3 or 5). If similarity is low (below 0.5), or the resulting function call fails, it falls back to the full tool set.

Experiments ran on an NVIDIA Jetson AGX Orin through Ollama with quantised models of about 1.5B to 8B parameters (Hermes-2-Pro, Llama 3.1, Mistral, Phi-3, Qwen2) on two benchmarks: BFCL (51 functions, mostly single calls) and GeoEngine (46 functions, sequential calls).

A motivating example: Llama 3.1 8B (4-bit) given all 46 GeoEngine tools picked the wrong one; with 19 tools it succeeded, and it ran faster. Quantisation alone was costly for tool use: on BFCL the same model scored 63.0% at full precision and between 20.4% and 44.4% across four quantised variants.

With tool reduction, reported BFCL success rates were about 71% for Hermes-2-Pro 8B, 68% for Qwen2 7B, 55% for Phi-3, 44% for Llama 3.1 8B and 40% for Qwen2 1.5B, with execution time reduced by 48-80%. Mistral gained speed but not accuracy. On the sequential-call benchmark gains were smaller, and two models were excluded because their baseline success was only about 10%.

The paper does not break failures into wrong tool, invented tool or wrong arguments, and baseline and reduced runs used different context sizes (16K and 8K), which confounds the comparison.

## Key points

- Reducing visible tools at run time improved tool selection for most small models and cut latency substantially.
- Selection uses the model's own description of what it needs plus embedding search; no training.
- Fallback to the full set on low confidence or on a failed call.
- 4-bit quantisation roughly halved function-calling accuracy for one 8B model on BFCL.
- Benefits were weaker on multi-step tool sequences.
- Small sample (230 queries per benchmark), one device, a confounded baseline.

## Relevance to JacKnife

(Our interpretation, not the source's claims.)

- JacKnife does not need a learned tool recommender: the state machine knows the phase and task, so it can expose only the tools valid for that state. This is the same intervention with a more reliable selector.
- Aim for a handful of tools per state; the paper's working range was 3 to 19 against a failing 46.
- Check which quantisation we deploy. If the 9B model runs at 4-bit, tool-call accuracy may be well below what was measured at higher precision during fine-tuning evaluation.
- Removing a tool after it has been misused (narrowing the set on retry) is a harness response to loops that needs no model cooperation.
