# 0008: Jac information at run time, tool descriptions, several calls per reply

- **Status:** Accepted, 2026-11-18
- **Layer:** context assembly, tool set, model interface
- **Builds on:** [0006](0006-tool-set.md), [0003](0003-target-jac-0-36.md), [jac CLI surface](../research/jac-cli-surface.md)
- **Changes:** 0006 "`guide` and loading documentation" and "Line numbers"

## Principle

The model gets Jac knowledge by reading the guides of the installed version, not from what it was trained on. An untrained model reads them before writing; a fine-tuned model is expected to read them mostly when an error names one. The harness does not force either: it makes the guides easy to find and points at the right one on an error.

## 1. Nothing is written for one version

| Value | Source |
|---|---|
| Jac version in the system prompt and the run log | `jac --version`, at run time |
| Guide names and one-line descriptions | `jac guide --json` |
| Page text | `jac guide <name>` (the guides ship inside the binary) |
| What changed in this version | `community/release_notes/jaclang`, section `jaclang <version>` |
| Removed or renamed syntax | `community/breaking-changes` |

## 2. Knowledge tools

| Tool | Given | Returns |
|---|---|---|
| `guide` | topic, optional section title | The page, or one section. A page or section over `JACH_GUIDE_CHARS` (12,000) comes back as its intro and the list of its sections with their sizes. Unknown topic: the closest names. |
| `guide_search` | text | Up to 12 guide sections containing the text, as `topic > section`, with the first matching line of each |
| `search` | text, optional path | Project lines containing the text, as `file: line`, up to 30 |
| `map` | optional path | With a path: what the file declares, what it imports, which files import it. Without: every file with its outline. |

0.36.1 has no `jac guide --section`; sections are cut from the page by markdown heading, outside code blocks.

A failed `guide` or `guide_search` does not count toward the step's failure limit (0010).

## 3. Where the model learns about them

- **System prompt**, built by the harness at run time: the version, the call rules (section 5), one line per skill (about 2,900 characters for 40 skills), and the two version-change pages.
- **On a check error**: the compiler ends each diagnostic with `→ run 'jac guide NAME'`. The harness keeps that name and adds `read it with guide(topic="NAME")` to the error.
- No rule forces a read before a write.

## 4. Tool descriptions

Each tool's description says what it does given its parameters, in the form "Given X, do Y", and states the mechanism exactly (for `edit`: exact text match, must occur once). Parameter descriptions say what each value is. The chat template renders these into the system message; the harness does not repeat them.

## 5. Several calls per reply

| Kind | Tools | Rule |
|---|---|---|
| Read | `read`, `search`, `map`, `guide`, `guide_search` | A failure does not stop the reply |
| Change | `write`, `edit`, `install` | A failure stops the reply; later calls are marked `not-run` |
| Run | `test`, `browse`, `submit` | Ends the reply: later calls are `not-run` |

Calls always run in order; nothing runs in parallel. A cut-off last call is reported after the complete calls before it have run. A reply's calls are shown together: one assistant message with all the calls, then their results; in older replies, calls that did not succeed fold to one line each.

## 6. Command tools

| Tool | Given | Runs | Returns |
|---|---|---|---|
| `test` | optional test name, optional file | `jac test <file or .> -v [-t name]` with `JAC_TEST_JOBS=0` (one worker: 0.5 s instead of 2.1 s and 32 workers for two tests) | `passed`/`failed` per test, the summary, and for the first failure the source lines around it (`> ` on the failing line) and the `E` lines |
| `install` | packages, kind (`python` or `npm`) | `jac install [--npm] <packages>`, which records them in `jac.toml` | The packages installed, or the installer's last lines |
| `browse` | steps, one per line: `open /path`, `click <label>`, `fill <label> \| <text>`, `press <key>`, `wait <s>`, `expect <text>`, `expect_not <text>` | The same runner as the submit gate, on a fresh copy of the app with no stored data | Each step `ok`, or the first failed step, the page snapshot, the first console error and the last error lines of the server log |

## 7. No line numbers

`read` returns the file exactly as stored, and the task card shows files the same way. pi does the same; opencode and Claude Code prefix line numbers and then need a rule telling the model not to copy them. `edit` finds its place by text, so the numbers served nothing. An error excerpt marks the reported line with `> ` and the others with two spaces, without numbers.

Measured before the change: 0 of 561 `edit` calls in `runs/` copied the old `N│ ` prefix, so this removes a risk, not an observed failure.
