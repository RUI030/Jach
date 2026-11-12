# Synthesising Coding Tasks by Breaking Tests, and What the Student Learns From Them

A method note based on SWE-smith [1].

- **Evidence:** B. Controlled ablations with public code, tasks, trajectories and models; preprint (venue not checked); Python only, one scaffold.
- **Numbers checked against the source:** yes, 2026-11-11, against the arXiv HTML (main text and appendices B, D, F).

## 1. Problem

Training a coding agent needs many tasks with executable checks. Mining real issues gives at most a few thousand tasks from about ten repositories and takes hundreds of hours of manual work. [1, Abstract]

## 2. Method

Build one execution environment per repository, then synthesise many tasks inside it. [1, §2.1]

1. An agent installs the repository and runs its tests; a human checks the result (about 7 minutes per repository). One Docker image serves all tasks from that repository.
2. Four bug generators produce candidate patches: an LLM modifies a function; an LLM rewrites a function from its signature and docstring; procedural AST transformations; and "PR mirroring", where an LLM reverts a past pull request in current code. Patches can be combined into multi-site bugs.
3. A candidate is kept only if it breaks at least one previously passing test.
4. An LLM writes an issue-style problem statement from the patch, one failing test and its output.

Training is rejection-sampling fine-tuning: run a teacher, keep resolved trajectories, fine-tune the student on them. [1, §3]

### Key decisions

1. **Environment first, tasks second.** This removes per-version installation, the most expensive step of SWE-bench collection. [1, §2.1]
2. **Cap trajectories per task at 3.** Tasks solved over and over are easy ones, which the authors, citing SWE-Gym, say degrade training. [1, §4]
3. **Convert the teacher's format to the student's.** The teacher used function calling; the student emits XML-tagged thought and action. The authors state that training directly on the teacher's format "does not work". [1, App. F.1]

### Implementation details that generalise

- History given to the student is truncated to the 5 most recent tool outputs, at training and inference alike. [1, App. F.1]
- Keep the failing test out of the issue text: students trained on such issues reproduced the bug in 127 of 500 runs, against 379. [1, §4.1]
- Fixed issue templates gave 31% fewer distinct teacher actions (379 vs 550). [1, §4.1]

## 3. Evidence

Data: 50k tasks from 128 repositories for about $1,360 of LLM cost. [1, §2.2] Claude 3.7 Sonnet in SWE-agent (75 steps, $2 cap) resolved 6,457 of 17,906 attempts (36%); after capping, 5,016 trajectories remained. [1, §4]

| Student (Qwen2.5-Coder-Instruct) | Training trajectories | SWE-bench Verified pass@1 |
|---|---|---|
| 7B | 2k | 15.2% |
| 32B | 5k | 40.2% (mean of 6 runs) |
| 32B | 500 | 28.2% |

[1, §4, Table 3; App. F.4]

Ablations on the 7B student (Verified, ± as given): [1, §4.1, Tables 4-5]

- Bug type, 507 training trajectories each: PR mirror 9.2 (±1.7), LM rewrite 8.8 (±1.7), procedural 8.6 (±1.8), LM modify 5.7 (±1.5).
- Issue text, 259 each: original 7.8, LM-generated 7.7, failing test 7.3, fixed template 6.4. All lie within about 1.5 points of one another.
- Difficulty of training tasks (scores 2/4/6/8): 12.4, 10.8, 13.6, 12.2%. No clear relation.
- More repositories at a fixed 700 trajectories, and resolved-only over random trajectories, both helped (figures only). [1, Fig. 5; App. F.4, Fig. 23]

**Repetition and loops.** [1, §4.2, App. F.5]

- Over 25% of the 32B student's trajectories contain a run of at least 10 identical base commands, against under 4% for the teacher. A run of length 10 corresponds to an 89% failure probability.
- 73% of the longest runs are file-view calls, used in place of search.
- 53% of the student's failures hit the step or cost limit, often before any source file was edited.
- Scaffold fixes: a warning after 4 (view) or 6 repeats, resampling up to 10 times after 6 or 8, injected messages or higher temperature after 7 or 9. Repetition fell sharply but resolves dropped slightly, to 38.4%. The authors suggest repetition is a symptom of difficulty rather than an intrinsic failure mode.

**Transfer.** On 300 non-Python tasks, the 32B student scored 8.4% against 6.5% for its base and 43% for the teacher. Spot checks found Python-like syntax in edits to non-Python files. [1, App. F.4]

## 4. Evidence boundaries

- **Python only**; the AST generators depend on Python's `ast` library. [1, §6]
- **One scaffold, one teacher family; ablations use 259-700 trajectories on 7B,** so 1-2 point differences sit inside the error bars.
- **The repetition analysis is on the 32B student.** The 7B student's loop rate is not reported.
- **SymPy specialisation (21.2% vs 13.6%) is measured on 22 tasks.** [1, §4.1]

## 5. What we take from it

Our interpretation, not the paper's claims.

- The recipe ports to Jac: take Jac projects with tests, mutate functions by AST rule or LLM rewrite, keep mutations that break a passing test, and write the task brief without the test. This yields debug-phase data cheaply.
- Our loop results (6 of 12 tasks kept repeating after LOOP DETECTED) match what this paper found when cloning a stronger teacher: the student repeats far more. Nudges and resampling cut repetition here without raising success. Loop breaking needs added information (documentation, an admin step), not only a warning.
- Python agent data will not make a Jac agent. Jac trajectories are needed.
- The teacher's tool-call format must be converted to our Qwen XML format before training, and the fold policy in training must match the one at run time.

## Reference

[1] John Yang, Kilian Lieret, Carlos E. Jimenez, Alexander Wettig, Kabir Khandpur, Yanzhe Zhang, Binyuan Hui, Ofir Press, Ludwig Schmidt, Diyi Yang. *SWE-smith: Scaling Data for Software Engineering Agents.* arXiv:2504.21798 (v2). <https://arxiv.org/html/2504.21798>. Project: <https://swesmith.com>. Accessed 2026-11-11.
