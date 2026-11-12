# Existing Jac harnesses and the fine-tuned model

Surveyed 2026-11-11 from `~/Documents/Jaseci/JacLLM` and the jac 0.36.1 install.

## The model

| Property | Value | Source |
|---|---|---|
| Base | `ornith-ai/Ornith-1.5-9B` (`qwen3_5_text`, a Qwen3.5 VLM loaded text-only) | `JacLLM/script/train/` |
| Position limit | 262,144 | model config |
| Training | Unsloth LoRA, r16 to r64, rslora | `script/train/{cpt,sft,grpo}.py` |
| Tool-call format | Qwen XML: `<tool_call><function=NAME><parameter=KEY>VALUE</parameter></function></tool_call>`; results in `<tool_response>`; tools listed in `<tools>` | `script/dataset/trajectory/README.md` |
| Thinking | Disabled. The v1.35 template always renders an empty `<think></think>` | `chat_template.jinja` of v1.35 |
| Serving | llama.cpp `llama-server --jinja`, GGUF Q4_K_M or Q8_0 | `script/eval/gguf_eval.sh` |

### Context lengths actually trained

| Stage | Tokens |
|---|---|
| CPT and single-turn SFT | 4,096 |
| GRPO | 2,048 |
| Trajectory SFT | 16,384 |
| Revdev v135 at 65,536 | Not trained: out of memory on a 16 GB GPU |

### Existing trajectory data

| Set | Harness that produced it | Tools seen |
|---|---|---|
| trajectory-bf16 | Codex (307 trajectories, 4,316 windows, 60.3M tokens) | `exec_command`, `write_stdin`, `apply_patch` |
| tool_fim | pi | `read`, `bash`, `edit`, `write` |
| revdev | JacCoder (53 accepted) | JacCoder schemas |
| prod | JacHammer production traces | JacCoder schemas |

The model has therefore seen three unrelated tool vocabularies and none of them is ours.

### Measured failure modes

| Failure | Evidence |
|---|---|
| Repeats the same call after a failed edit or `jac check` | 16 of 22 failed Tool-FIM runs looped; some used 50+ calls. Training data had no recovery examples. (`report/v1.3Tool/tool-fim-spike.md`) |
| Hallucinates file paths from training projects, does not list files first | Trajectory SFT in Codex wrote no code on the PaperJac task. Five projects held 68% of training tokens. |
| Misuses an ambiguous parameter and never corrects | `read_file(offset=1)` on one-line files (`docs/revdev/devlog/REVDEV_MODEL_EVAL.md`) |
| Keeps trying forbidden shell commands | Same eval: 2 of 6 correct next actions, 0 of 2 live tasks |
| Code looks like Jac but fails the checker | 88% `jac check` pass rate on single-turn tasks (`SPIKE.md`) |

Tool-FIM through pi: 71.5% solved, against 43.1% for v1.3.

## jacBuilder (JacCoder)

`JacLLM/jacBuilder`; internals in `.architecture/jac_coder_internal.md`.

- **Stack:** all Jac. LLM calls go through byLLM (litellm). Each user app runs in a Kubernetes sandbox pod.
- **Loop:** `MainAgent.respond(...) by llm(...)` in `jac_coder/core/nodes.jac`, which is byLLM's built-in ReAct loop with up to 100 iterations. No phase gating.
- **Fixed prompt cost:** system prompt about 10k tokens, plus about 24.8k characters of tool schemas. Roughly 16k tokens before the user speaks.
- **Tools (27):** `think`, `read_file`, `grep_search`, `find_files`, `list_files`, `analyze_project`, `find_symbol`, `load_jac_skill`, `plan_build`, `edit_code`, `write_code`, `delete_code`, `run_command`, `jac_run`, `browser_validate`, `browser_open`, `browser_do`, `browser_state`, `browser_close`, `preview_status`, `preview_restart`, `clarify_intent`, `update_todos`, `request_deploy`, `sandbox_logs`, `mcp_call`, `finish_tool`.
- **Checks on write:** `write_code` and `edit_code` run `jac check` on `.jac` files automatically and block known anti-patterns (`tool/write/checked.impl.jac`).
- **Jac knowledge:** pulled on demand. `load_jac_skill(name)` returns guide bodies bundled with the installed jac version.
- **Compaction:** deterministic, no LLM call. Keeps the system message, first user message and current turn opener; replaces the middle with one stub; truncates tool results over 3000 characters.
- **Workflow:** `plan_build` writes `.jaccoder/build_plan.json` (manifest, leaf-first write order, a verify flow), then load skills, write leaf-first, start the dev server, `browser_validate`, write a journal.
- **Browser:** the `agent-browser` CLI. Accessibility-tree snapshots with `@eN` refs, plus screenshots.

**Why it does not fit a 9B model:** the fixed prompt alone is the model's whole trained context; 27 tools; a long procedure in prose; skill bodies of 10 to 30 KB re-entering context; reliance on vision.

## `jac ai` (in 0.36.1, removed by 0.38)

Source in the install payload: `cli/ai_agent.jac`, `cli/impl/ai_agent.impl.jac`.

- A walker `AgentSession` traverses phase nodes **Plan → Build → QA → Done**.
- Each tool is tagged with the phases allowed to call it (`ToolSpec.phases`).
- `run_phase` is a byLLM function with 60 iterations and tool results capped at 4000 characters.
- `_progress_guard` limits rewrites of the same file to 5.
- A classifier skips Build for read-only questions.
- A `Ledger` carries notes between phases.
- Default model `local:gemma-4-e4b`: it was aimed at small local models.
- Tools: file tools, `find_symbol`, `find_uses`, `project_map`, `find_walkers`, `context_slice`, `jac_check`, `start_app`, `serve`, `stop_server`, `run_command`, ten `browse_*` tools, `search_guides`, `read_guide`, `note`.

## jac-mini-coder

`JacLLM/jac-mini-coder`, compared with JacProjectFactory in `JacLLM/DIFF.md`.

- An OSP graph of stations: Scaffold → Declare → Implement → Verify, each a typed byLLM slot.
- Gates are owned by code, not by the model.
- Mechanical repair is tried before LLM repair.
- Repair budget of 3 per station.

## What the three have in common

| | jacBuilder | `jac ai` | jac-mini-coder |
|---|---|---|---|
| Target model | Large (Claude Sonnet) | Small local | Small local |
| Who drives | Model | Harness phases | Harness stations |
| Tools per step | 27 | Phase-scoped | One typed slot |
| Stall guard | Iteration and cost caps | Rewrite limit 5 | Repair budget 3 |
