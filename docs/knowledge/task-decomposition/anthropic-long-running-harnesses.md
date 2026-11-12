# Feature Lists with Pass Flags and a Fixed Session Start-up Routine

A method note based on Anthropic's "Effective harnesses for long-running agents" [1].

- **Evidence:** D. Vendor engineering blog describing internal experiments; no controlled comparison and no numbers for any of the reported improvements.
- **Numbers checked against the source:** yes, 2026-11-11, against the raw HTML of the article. The only numbers in it are the feature count and dates.

## 1. Problem

A coding agent that builds a full web application must work across many context windows, and each new session starts with no memory of the last. Even with compaction, the author reports that Claude Opus 4.5 on the Claude Agent SDK, given only a high-level prompt such as building a clone of claude.ai, failed in two ways. [1, "The long-running agent problem"]

- It tried to build too much at once, ran out of context mid-feature, and left half-finished, undocumented work for the next session.
- Later in a project, a session saw that progress had been made and declared the whole job done.

## 2. Method

Two prompts over the same harness, tools and system prompt. [1, "The long-running agent problem", footnote 1]

- **Initializer session** (runs once): writes `init.sh` to start the dev server, a progress log (`claude-progress.txt`), an initial git commit, and a feature list expanded from the user's prompt.
- **Coding session** (every later session): implements one feature, then leaves the repository in a clean state, meaning code fit to merge to a main branch.

### Key decisions

1. **A machine-readable feature list.** For the claude.ai clone it held over 200 features, each with a category, a description, a list of verification steps, and a `passes` field initially false. [1, "Feature list"]
2. **Only the status may change.** Coding sessions are told to edit the list only by flipping `passes`, with strongly worded instructions against removing or editing entries. [1, "Feature list"]
3. **JSON, not Markdown.** The author reports the model was less likely to rewrite or overwrite a JSON file. [1, "Feature list"]
4. **One feature per session.** Described as critical to stopping the agent from doing too much at once. [1, "Incremental progress"]
5. **Commit and log at the end.** A descriptive git commit and a progress summary each session; git also lets the agent revert bad changes. [1, "Incremental progress"]
6. **End-to-end testing before marking done.** The model tended to mark features complete after unit tests or `curl` checks. Prompting it to test through browser automation as a user would is reported to have improved results substantially. [1, "Testing"]

### Implementation details that generalise

Every coding session starts with the same routine. [1, "Getting up to speed"]

1. Print the working directory.
2. Read the git log and the progress file.
3. Read the feature list and pick the highest-priority unfinished feature.
4. Run `init.sh` and a basic end-to-end check, to catch breakage left by the previous session before adding anything.

Remaining failure: features that depend on browser-native alert modals stayed buggier, because the browser automation tool could not see them. [1, "Testing"]

## 3. Evidence

There are no measurements. The article reports qualitative outcomes: one feature at a time was described as critical, browser testing "dramatically improved performance", and the start-up routine saved tokens because the agent no longer had to work out how to run and test the app. [1, "Incremental progress", "Testing", "Getting up to speed"]

The article summarises four failure modes with an initializer response and a coding-session response for each: declaring victory early, leaving bugs or undocumented progress, marking features done prematurely, and spending time working out how to run the app. [1, "Agent failure modes and solutions"]

## 4. Evidence boundaries

- **No controlled comparison.** No success rate, feature count or cost is given with and without any component.
- **One frontier model, one task type.** Opus 4.5 building a full-stack web app. The author names generalising to other fields as future work. [1, "Future work"]
- **The agent still sets its own status.** Coding sessions are told to mark features passing only after careful testing; nothing in the harness checks that. [1, "Agent failure modes and solutions"]
- **Prompt-level rules depend on a capable model.** Whether a 9B model would keep to "edit only the `passes` field" is not addressed.
- **Single versus multi-agent is open.** The author says it is unclear whether specialised testing or cleanup agents would do better. [1, "Future work"]

## 5. What we take from it

Our interpretation, not the article's claims.

- The task list should be a structured file owned by the harness, with acceptance criteria per task and a status set only by the harness after its own check passes. The article leaves this to the model; a 9B model should not be trusted with it.
- The start-up routine maps onto a deterministic resume step: load the task record, show the last progress note, re-run the task's checks, then hand control to the model. None of it needs model judgement.
- The premature-completion failure, and our own 0 of 13 apps working in a browser, both argue for an end-to-end gate the model cannot skip before a task counts as done.

## Reference

[1] Justin Young (Anthropic). *Effective harnesses for long-running agents.* Anthropic Engineering blog, published 26 Nov 2025. <https://www.anthropic.com/engineering/effective-harnesses-for-long-running-agents>. Accessed 2026-11-11.
