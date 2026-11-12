# SWE-agent: Agent-Computer Interfaces Enable Automated Software Engineering

- **Source:** https://arxiv.org/html/2405.15793
- **Authors / org:** John Yang, Carlos E. Jimenez, Alexander Wettig, Kilian Lieret, Shunyu Yao, Karthik Narasimhan, Ofir Press (Princeton University)
- **Date:** May 2024 (v3 revised 11 Nov 2024)
- **Type:** paper
- **Read:** first ~100k of ~204k characters of the HTML (main text and the start of the appendix; the rest of the appendix was not read)

## Summary

The paper argues that an LLM agent is a new kind of user and needs an interface designed for it, the agent-computer interface (ACI), in the way people need an IDE. Without changing the model, the authors build a small command set over a shell and show that the design choices move results substantially.

The stated principles are: simple actions with few options and short documentation; compact actions that accomplish a meaningful step in one call; feedback that is informative but concise; and guardrails that stop errors from propagating. The tools are a file viewer showing 100 lines with line numbers, search commands capped at 50 results (beyond that the agent is told to refine the query), and a line-range edit command that runs a linter and rejects edits introducing syntax errors. Observations older than the last five steps are collapsed to one line, and a command with no output returns an explicit "ran successfully, no output" message.

With GPT-4 Turbo, SWE-agent resolved 12.47% of full SWE-bench and 18.0% of SWE-bench Lite, against 11.0% on Lite for the same model with a plain shell. Ablations on Lite (from 18.0%): no edit command 10.3; edit without lint guardrail 15.0; search that returns one result at a time 12.0; no search tools 15.7; 30-line viewer 14.3; whole-file viewer 12.7; full history instead of collapsing 15.0; no demonstration 16.3.

On editing failures: about half of trajectories contained at least one failed edit. An edit attempt eventually succeeded 90.5% of the time overall, but only 57.2% of the time once one edit had failed. Among unresolved runs, about 23% were classed as cascading failed edits. The rejected-edit message shows the error, what the file would have looked like, and the original snippet, and tells the agent not to reissue the same command.

## Key points

- Interface design alone gave a 64% relative gain over a raw shell with the same model.
- Guardrail on edits (reject on lint error) was worth 3 points; a good edit tool at all was worth 7.7.
- Too little context (30 lines) and too much (whole file) both hurt; 100 lines was best.
- Summarised, capped search beat iterative search by 6 points.
- One failed edit lowers the eventual success rate of editing from 90.5% to 57.2%.
- Collapsing old observations helped (+3 points over full history).

## Relevance to JacKnife

(Our interpretation, not the source's claims.)

- The 90.5% to 57.2% drop was measured on GPT-4 Turbo; our model's failed-edit loop is a more severe form of the same effect. The first failed edit is the moment to change something, not the third.
- Reject invalid edits before they land: run the Jac checker (or at least the parser) inside the edit tool and return a rejection with the reason and the unchanged original snippet.
- Tool surface for the 9B model: few commands, few parameters each, bounded output with a "refine your query" message instead of long listings.
- Use a windowed file view with line numbers; the paper's sweet spot was about 100 lines.
- Collapse old observations; this also removes stale failed calls from context.
