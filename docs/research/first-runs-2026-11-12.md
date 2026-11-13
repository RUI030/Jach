# First runs of the minimal harness

2026-11-12. Jac 0.36.1, JacLLM v1.35 Q4_K_M served locally by llama.cpp, code at `jach/core/`.

**Task (level 1):** on the template, add a server function `hello` and a "Hello" button that shows its reply. Pass means: in a real browser, clicking Hello shows "Hello from Jac" and clicking Ping still shows "pong".

**What exists:** run log, work tree, one session walker, raw completion with our own tool-call parser, tools `read`, `write`, `edit`, `submit`, check after every change, failures folded to one line, stall limits, wiring check at `submit`, browser action runner.

| Run | Wiring hint in the task | Wiring check | Turns | Harness said | Browser |
|---|---|---|---|---|---|
| 1 | Yes | Not built yet | 7 | passed | Not run. `main.jac` was left without the import, so by the wiring rule the call would return 405. The model sent an edit with identical old and new text, was refused, and submitted. |
| 2 | Yes | Yes | 7 | passed | Passed |
| 3 | No | Yes | 8 | passed | Passed |
| 4 | No | Yes | 9 | passed | Passed |
| 5 | No | Yes | 8 | passed | Passed |

Findings:

- **Without the hint the model forgot the entry-file import in 3 of 3 runs.** Each time `jac check` was clean. The wiring check refused the `submit`, named the file and the line to write, and the model fixed it on the next edit.
- **Run 1 reproduces the reported failure in miniature**: the harness reported a pass on an app whose button could not work. The difference between run 1 and the others is one check.
- Context stayed under 1,800 tokens. A turn took 1 to 3 seconds.
- `entry` cannot be a parameter name; the compiler's message for this case was clear (E0013).
- A directory named `.jac` matches `*.jac`; file scans must test for files.

Limits of this result: one task, the easiest level, five runs, no plan phase, no admin. It shows the loop and the checks work together, not how the model does on harder tasks.
