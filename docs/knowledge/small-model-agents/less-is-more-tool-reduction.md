# Showing a Small Model Fewer Tools per Query

A method note based on Less-is-More [1].

- **Evidence:** B. Controlled comparison on two public benchmarks, accepted at DATE 2025; but no code is linked, baseline values appear only in figures, no error bars, and the baseline ran with a larger context window.
- **Numbers checked against the source:** partly, 2026-11-11, against the arXiv HTML. Values that appear only in Figures 2 and 3 (baseline success rates, Gorilla results) could not be read from the text and are not given.

## 1. Problem

Small quantised models running on edge hardware pick the wrong tool when shown many tools at once, and long tool lists slow them down. The paper asks whether exposing only a few relevant tools per query, with no fine-tuning, improves tool selection, latency and power use. [1, §I]

## 2. Method

Three parts. [1, §III]

1. **Offline search levels.** Tool descriptions are embedded (an MPNet sentence model). Level 1 indexes individual tools. Level 2 indexes clusters of tools that are used together, built by clustering GPT-4-generated example queries. Level 3 is the full tool set.
2. **Tool recommender.** At run time the model sees the user query with no tools and writes descriptions of the tools it thinks it needs.
3. **Tool controller.** A k-nearest-neighbour search matches those descriptions against Levels 1 and 2. The level with the higher average similarity supplies the top-k tools (k = 3 or 5). The model then makes the call with only those tools.

### Key decisions

1. **Let the model describe its need before seeing options.** The query alone drives the search, so the selector needs no labelled data.
2. **Search both single tools and tool groups.** Single-call queries matched Level 1 better; sequential queries on GeoEngine matched Level 2 better. [1, §IV]
3. **Fall back to the full set.** If both average similarities are below 0.5, or the model reports that the call failed after retrying, the next attempt uses all tools. [1, §III-C]

### Implementation details that generalise

- The recommender step sends no tool definitions, so its cost is small next to the call itself. [1, §III-B]
- Fewer tools allow a smaller context window, which saves time and memory on its own. [1, §I, Table II]

## 3. Evidence

Llama 3.1 8B on BFCL and GeoEngine, by precision. Full precision ran through Hugging Face, the quantised variants through Ollama. [1, §I, Table I]

| Benchmark | Full | q4_0 | q4_1 | q4_K_M | q8_0 |
|---|---|---|---|---|---|
| BFCL | 63.04% | 20.43% | 34.35% | 39.57% | 44.35% |
| GeoEngine | 63.91% | 43.04% | 59.57% | 56.96% | 53.04% |

Motivating case, Llama 3.1 8B q4_K_M on one GeoEngine query: with 46 tools at 16K context it failed, taking 30 s; with 19 tools it succeeded in 20 s (16K) or 17 s (8K). [1, §I, Table II]

Results with tool reduction, as stated in the text. Benchmarks used 230 queries each, with 51 tools (BFCL) and 46 (GeoEngine). [1, §IV]

| Model | BFCL success | BFCL time cut | GeoEngine success | GeoEngine time cut |
|---|---|---|---|---|
| Hermes2-Pro 8B | ~71% | up to 80% | 63% | 15% |
| Llama 3.1 8B | 44.2% | 72% | 56% | up to 40% |
| Mistral 8B | no gain | 77% | 46% | +10% on some variants |
| Phi3 8B | 55% | 55% | excluded | excluded |
| Qwen2 1.5B | ~40% | 48% | excluded | excluded |
| Qwen2 7B | 68% | up to 70% | 35% | 21% |

- Phi3 and Qwen2 1.5B were excluded from GeoEngine because their default success was about 10%. [1, §IV]
- The abstract says up to 70% time and 40% power saved; the body reports up to 80% and 45% for Hermes2-Pro on BFCL. [1, Abstract, §IV]

## 4. Evidence boundaries

- **The gains cannot be sized from the text.** Baseline success rates are only in Figures 2 and 3. Which quantisation variant and which k each stated figure refers to is not given.
- **The baseline is confounded.** Default runs used a 16K context; reduced runs used 8K. The authors say larger contexts did not raise default success. [1, §IV]
- Failures are not split into wrong tool, invented tool and wrong arguments. "Success" needs the correct tool and correct input types. [1, §IV]
- 230 queries per benchmark, one device, no repeat runs or intervals.
- Mostly single-turn calls; no multi-step agent loop of the kind a coding harness runs.
- The Table I comparison of full and quantised precision also changes the serving stack.

## 5. What we take from it

Our interpretation, not the paper's claims.

- Our state machine already knows the phase, so it can select tools exactly, without a learned recommender. The paper's evidence supports keeping the per-phase set small; it does not tell us how small.
- The quantisation table is the most useful result for us. If our 9B model is served at 4-bit in llama.cpp, tool-call accuracy should be measured at that precision, not at the precision used for fine-tuning evaluation.
- Falling back to a wider tool set after a failure is the opposite of narrowing the set after misuse. Which helps our model is an open question we would need to measure.

## Reference

[1] Varatheepan Paramanayakam, Andreas Karatzas, Iraklis Anagnostopoulos (Southern Illinois University), Dimitrios Stamoulis (University of Texas at Austin). *Less is More: Optimizing Function Calling for LLM Execution on Edge Devices.* arXiv:2411.15399; accepted at DATE 2025. <https://arxiv.org/html/2411.15399>. Accessed 2026-11-11.
