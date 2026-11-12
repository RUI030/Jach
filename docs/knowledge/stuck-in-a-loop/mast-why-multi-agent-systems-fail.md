# Why Do Multi-Agent LLM Systems Fail? (MAST)

- **Source:** https://arxiv.org/html/2503.13657
- **Authors / org:** Mert Cemri, Melissa Z. Pan, Shuyi Yang, and 10 others (UC Berkeley)
- **Date:** March 2025 (v3 revised 26 Oct 2025)
- **Type:** paper
- **Read:** main text sections 1-6 and appendices A-G (appendices H-N, including the detailed intervention case studies, were not read)

## Summary

The paper builds an empirical taxonomy of failures in LLM agent systems. The authors annotated 1,642 execution traces from seven frameworks (ChatDev, MetaGPT, HyperAgent, AppWorld, AG2, Magentic-One, OpenManus) running on models from GPT-4o and Claude 3.7 Sonnet down to Qwen2.5-Coder-32B and CodeLlama-7b. The taxonomy was developed with grounded theory on 150+ traces by six expert annotators; three annotators reached Cohen's kappa 0.88 on a shared sample. An o1-based LLM judge was then used to label the rest (94% accuracy, kappa 0.77 against humans).

The result is 14 failure modes in three groups: system design issues, inter-agent misalignment, and task verification. The single most common mode is step repetition (15.7% of labelled failures), followed by reasoning-action mismatch (13.2%), unawareness of termination conditions (12.4%), and disobeying the task specification (11.8%). Verification failures (none, incomplete, or incorrect) add up to about 17%, and premature termination is 6.2%. Failure rates of the studied systems range from 41% to 86.7%.

The authors argue that many failures come from system design rather than model capability. Two interventions on ChatDev support this modestly: clarifying roles and workflow gave +9.4% task success, and adding a verification step tied to the high-level task objective gave +15.6%. Neither removed most failures. The authors also note that verifiers often perform only shallow checks, such as confirming that code compiles.

## Key points

- Step repetition is the most frequent single failure mode (15.7%); not knowing when to stop is close behind (12.4%).
- Reasoning-action mismatch (13.2%): what the agent says it will do and what it does diverge.
- Verification that only checks compilation is a named weakness; objective-level verification helped (+15.6% on ChatDev).
- Failure profiles differ by system: OpenManus and HyperAgent are repetition-heavy, AppWorld terminates early.
- Kappa 0.88 between humans, 0.77 for the LLM judge: the taxonomy is usable for automated labelling of traces.

## Relevance to JacKnife

(Our interpretation, not the source's claims.)

- Our observed loop rate (16 of 22 failed runs) is consistent with repetition being the top failure mode even for much stronger models; it is a harness-level problem to design against, not only a small-model defect.
- "Unaware of termination conditions" argues for the harness, not the model, owning task completion via acceptance criteria.
- Acceptance criteria should test the task objective, not only "checker passes"; shallow verification is a documented failure class.
- The 14 modes are a ready-made label set for tagging JacKnife failed trajectories, which would let us track whether a harness change shifts the failure distribution.
