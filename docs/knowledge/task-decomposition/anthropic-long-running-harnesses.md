# Effective harnesses for long-running agents

- **Source:** https://www.anthropic.com/engineering/effective-harnesses-for-long-running-agents
- **Authors / org:** Justin Young (Anthropic)
- **Date:** 2025-11-26
- **Type:** engineering blog
- **Read:** full text

## Summary

The article describes a harness for building a full web application across many context windows, where each new session starts with no memory of the previous ones. Two failure patterns were observed even with a frontier model and compaction: the agent tried to build too much at once and ran out of context mid-feature, leaving undocumented half-finished work; and later sessions looked at existing progress and declared the whole project done.

The fix is two prompts over one harness. An initializer session runs once and creates the working environment: a feature list, an `init.sh` script that starts the dev server, a progress log, and an initial git commit. Every later session is a coding session that implements one feature and leaves the repository in a clean, documented state.

The feature list is a JSON file. For a claude.ai clone it held over 200 entries, each with a category, a description, a list of verification steps, and a `passes` field that starts as false. Coding sessions may only flip `passes`; they are told not to edit or delete entries. JSON was chosen because the model was less likely to casually rewrite it than Markdown.

Each coding session begins with the same routine: confirm the working directory, read the git log and progress file, read the feature list and choose the highest-priority unfinished feature, run `init.sh`, and run a basic end-to-end check to detect breakage left by the previous session. Only then does it start new work. At the end it commits with a descriptive message and updates the progress file.

On testing, the model tended to mark features done after unit tests or `curl` checks alone. Requiring browser-automation tests that exercise the feature as a user would improved results substantially.

## Key points

- Split "set up the task structure" from "do one unit of work"; both use the same tools.
- A machine-readable feature list with a pass flag stops premature "all done" claims.
- The agent may change only the status field of the list, never the requirements.
- Every session starts by reading state and verifying that the existing build still works.
- One feature per session; end in a committed, documented state.
- End-to-end verification is required before a feature is marked as passing.

## Relevance to JacKnife

(Our interpretation.)

- The task list should be a structured file owned by the harness, with acceptance criteria per task and a status that only the harness sets after its own check passes. A 9B model should not be able to edit criteria.
- The session start-up routine translates into a deterministic "resume" step in the state machine: load task record, show last progress note, re-run the task's tests, then hand control to the model. None of this needs model judgement.
- "One feature per session" corresponds to one task per unfolded context; fold everything from the previous task to its record.
- The premature-completion finding argues for a harness gate between the unit-test and e2e-test states that the model cannot skip.
