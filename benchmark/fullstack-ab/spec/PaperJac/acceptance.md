# PaperJac: acceptance checklist

For the tester only; `init.sh` never copies this file (or `spec2.md`) into a workspace. Expected
answers are computed from `papers.json` (20 papers, 37 citations). Run the checks in order: each
section starts from the state the previous one left.

## Arms

| Arm | Model | Stack | Starting project |
|---|---|---|---|
| Base | `ornith-ai/Ornith-1.5-9B-GGUF:Q8_0` (untrained) | React (Vite, TypeScript) + FastAPI | `shadcn init -t vite` (Tailwind, shadcn/ui), plus `backend/` with a hello-world FastAPI app and a virtualenv |
| JacLLM | `JacLLM-SFT-Ornith-9B-v1.3A_GGUF:Q8_0` (SFTv1.3, run A) | Jac | `jac create --use jac-shadcn`, including its `AGENTS.md` (points to `jac guide` and `jac check`) |

Both arms start with the same 54 shadcn components installed (every component both registries have),
so neither builds UI primitives from scratch, and choosing which ones to use is part of the test.

The two arms differ in both model and stack: the comparison is the finished app, not the model alone.
Both get only the agent's built-in tools (read, edit, write, bash); no MCP servers or skills. Each arm
uses its stack's own CLI through bash (npm/pip/uvicorn, or `jac check`/`jac guide`/`jac start`).

## Session rules

- Run `./init.sh PaperJac` in `benchmark/fullstack-ab/`. It creates `Impl/Base/PaperJac/` and `Impl/JacLLM/PaperJac/`,
  each with the scaffold, `papers.json`, a filled-in `SPEC.md`, and a git repo with one commit.
- Serve both models from Unsloth Studio as GGUF Q8_0 with the same context length (131072; pi's
  `~/.pi/agent/models.json` assumes it). Check the loaded context in Studio before each session.
- Start pi in the arm's project directory with MCP, skills, extensions and prompt templates off
  (`AGENTS.md` stays on):

  ```bash
  pi --no-mcp --no-skills --no-extensions --no-prompt-templates --model unsloth/<model id>
  ```

- **Level 1**: send the arm's `SPEC.md` unchanged as the first message. Budget: 30 tester messages or 3 hours. Then run checks 1–54.
- **Level 2**: only if checks 1–3 pass. Commit the level-1 result (`git add -A && git commit -m "level 1"`), start a
  new agent session in the same directory and send `spec2.md` unchanged as the first message.
  Budget: 15 tester messages or 1.5 hours. Then run checks 55–73.
- After the first message the tester may only send chat messages: report what is broken, paste error
  output, ask for a fix. The tester never edits code, runs installs the model didn't ask for, or hints
  at a solution.
- Record per arm and level: model, stack, start/end time, number of tester messages, the transcript,
  and the first message after which each check passed (or "never").

## Level 1

### Runs

| # | Check | Pass when |
|---|---|---|
| 1 | Starts | The command the model gave starts the app without manual fixes |
| 2 | Loads | The page at the given URL opens and shows papers |
| 3 | Count | The Library shows 20 papers |
| 4 | Navigation | Every page has links to Library, Graph and Analysis |

### Library

| # | Action | Expected |
|---|---|---|
| 5 | Filter field = generative | GAN, DDPM, DDIM, Latent Diffusion |
| 6 | Filter field = vision | LeNet, AlexNet, ResNet, ViT |
| 7 | Filter years 2020–2021 | DDPM, ViT, DDIM, Don't Stop Pretraining, CLIP, LoRA, Latent Diffusion, RoPE (8) |
| 8 | Filter years up to 2014 | Information Theory, Physical Symbol Systems, LeNet, AlexNet, GAN (5) |
| 9 | Search title "diffusion" | DDPM, DDIM, Latent Diffusion |
| 10 | Search title "transformer" | BERT, ViT, RoPE (Attention Is All You Need has no "transformer" in its title) |
| 11 | Search author "Bengio" | LeNet, GAN |

### Paper page

| # | Paper | Cites | Cited by |
|---|---|---|---|
| 12 | Attention Is All You Need | ResNet (1) | BERT, CLIP, DDPM, Don't Stop Pretraining, Latent Diffusion, LoRA, RoPE, ViT (8) |
| 13 | BERT | Attention Is All You Need (1) | CLIP, Continual Pre-training, Don't Stop Pretraining, Latent Diffusion, LoRA, RoPE, ViT (7) |
| 14 | GAN | AlexNet, LeNet (2) | DDPM, DDIM, Latent Diffusion (3) |
| 15 | Latent Diffusion | Attention Is All You Need, BERT, CLIP, DDIM, DDPM, GAN (6) | none (0) |
| 16 | LeNet | none (0) | GAN (1) |
| 17 | Information Theory | none (0) | none (0) |
| 18 | Links | Clicking a cited paper opens its page; clicking an author opens the author page | |

### Author page

| # | Author | Expected |
|---|---|---|
| 19 | Ilya Sutskever | AlexNet, CLIP |
| 20 | Jakob Uszkoreit | Attention Is All You Need, ViT |
| 21 | Herbert A. Simon | Physical Symbol Systems |
| 22 | Geoffrey E. Hinton | AlexNet, Knowledge Distillation |

Author names are as printed on each paper, except Hinton: Knowledge Distillation prints "Geoffrey
Hinton", stored as "Geoffrey E. Hinton" so both of his papers share one author page.

### Graph

| # | Check | Pass when |
|---|---|---|
| 23 | Shape | 20 nodes and 37 arrows; Information Theory and Physical Symbol Systems have no arrows |
| 24 | Direction | The arrow between QLoRA and LoRA points at LoRA |
| 25 | Colour | Nodes are coloured by field (6 fields) |
| 26 | Click | Clicking a node opens that paper's page |

### Analysis

| # | Check | Expected |
|---|---|---|
| 27 | Top 5 most cited | Attention Is All You Need 8, BERT 7, AlexNet 5, ResNet 4, GAN 3 |
| 28 | Unconnected papers | Information Theory, Physical Symbol Systems |

A path goes from the citing paper to the cited one. Where two shortest paths exist, either is a pass.

| # | Path from → to | Expected |
|---|---|---|
| 29 | Latent Diffusion → LeNet | Latent Diffusion → GAN → LeNet |
| 30 | RoPE → AlexNet | RoPE → Attention Is All You Need → ResNet → AlexNet |
| 31 | DDIM → Attention Is All You Need | DDIM → DDPM → Attention Is All You Need |
| 32 | Continual Pre-training → ResNet | 3 steps, through BERT or Don't Stop Pretraining, then Attention Is All You Need |
| 33 | LeNet → CLIP | No path (LeNet cites no paper in the app; paths only follow citation direction) |
| 34 | CLIP → LeNet | No path (nothing CLIP reaches cites LeNet; only GAN does) |
| 35 | Latent Diffusion → Information Theory | No path |

### Add

Use this made-up paper; it is test data, not a real publication.

| Field | Value |
|---|---|
| id | `testpaper` |
| short | Test Paper |
| title | A Test Paper for PaperJac |
| authors | Ada Tester, Yoshua Bengio |
| year | 2024 |
| venue | TestConf |
| field | training |
| arxiv | 2401.00000 |
| cites | QLoRA, Latent Diffusion |

| # | Action | Expected |
|---|---|---|
| 36 | Add with id `bert` | Rejected: id taken |
| 37 | Add with title empty | Rejected: required field |
| 38 | Add with year 2016 | Rejected: cites papers from 2021 and 2023 |
| 39 | Add as in the table | Accepted; Library shows 21 papers |
| 40 | QLoRA page | Cited by: Test Paper (1) |
| 41 | Path Test Paper → LeNet | Test Paper → Latent Diffusion → GAN → LeNet |
| 42 | Author Yoshua Bengio | LeNet, GAN, Test Paper |

### Edit

| # | Action | Expected |
|---|---|---|
| 43 | Edit Test Paper: venue → TestConf 2 | Paper page shows TestConf 2 |
| 44 | Edit LoRA: year → 2024 | Rejected: QLoRA (2023) cites LoRA |
| 45 | Edit Test Paper: year → 2020 | Rejected: it cites Latent Diffusion (2021) |
| 46 | Edit Test Paper: remove QLoRA from what it cites | QLoRA page: cited by none (0); Test Paper cites Latent Diffusion only |

### Delete

| # | Action | Expected |
|---|---|---|
| 47 | Delete GAN, cancel at the confirmation | GAN is still there |
| 48 | Delete GAN, confirm | Library shows 20 papers; GAN's page and node are gone |
| 49 | Latent Diffusion page | Cites Attention Is All You Need, BERT, CLIP, DDIM, DDPM (5) |
| 50 | Unconnected papers | Information Theory, Physical Symbol Systems, LeNet |
| 51 | Top 4 most cited | Attention Is All You Need 8, BERT 7, then AlexNet and ResNet with 4 each |
| 52 | Path Test Paper → LeNet | No path |
| 53 | Graph | 20 nodes, 33 arrows |
| 54 | Restart the server | Same as 48–53; Test Paper is there with venue TestConf 2 and cites Latent Diffusion only |

## Level 2

Starts from the state after check 54 (GAN deleted, Test Paper present).

### Tags

| # | Action | Expected |
|---|---|---|
| 55 | Tag BERT, LoRA, QLoRA with `llm`; tag DDPM, DDIM with `diffusion` | Tags show on those paper pages and in the Library |
| 56 | Library filter tag `llm` | BERT, LoRA, QLoRA |
| 57 | Remove `llm` from BERT, filter again | LoRA, QLoRA |

### Collections

| # | Action | Expected |
|---|---|---|
| 58 | Create collection "Fine-tuning" | Collections page lists it with 0 papers |
| 59 | In the Library select Don't Stop Pretraining, LoRA, Continual Pre-training, QLoRA; add to "Fine-tuning" in one action | Collection page lists those 4 |
| 60 | Rename it "PEFT & CPT" | Collections page and LoRA's page show the new name |
| 61 | Create "Reading"; add LoRA from LoRA's page | LoRA's page lists both collections |
| 62 | Delete "Reading" | LoRA still exists and is only in "PEFT & CPT" |
| 63 | Add Test Paper to "PEFT & CPT", then delete Test Paper | "PEFT & CPT" lists the original 4 again |

### Notes

| # | Action | Expected |
|---|---|---|
| 64 | On CLIP's page save the note "check the zero-shot table" | The note shows after reloading the page |

### BibTeX

| # | Action | Expected |
|---|---|---|
| 65 | QLoRA's BibTeX | Exactly the example in `spec2.md` |
| 66 | Information Theory's BibTeX (a DOI paper) | Exactly the block below |
| 67 | Copy button on a paper page | Pasting gives the same text as shown |
| 68 | Export "PEFT & CPT" | Exactly the 4 entries below, in this order |

Check 65:

```bibtex
@article{shannon,
  title = {A Mathematical Theory of Communication},
  author = {C. E. Shannon},
  journal = {Bell System Technical Journal},
  year = {1948},
  doi = {10.1002/j.1538-7305.1948.tb01338.x}
}
```

Check 67 (sorted by year, then id: `cpt` before `qlora` in 2023):

```bibtex
@article{dapt,
  title = {Don't Stop Pretraining: Adapt Language Models to Domains and Tasks},
  author = {Suchin Gururangan and Ana Marasović and Swabha Swayamdipta and Kyle Lo and Iz Beltagy and Doug Downey and Noah A. Smith},
  journal = {ACL},
  year = {2020},
  eprint = {2004.10964}
}

@article{lora,
  title = {LoRA: Low-Rank Adaptation of Large Language Models},
  author = {Edward Hu and Yelong Shen and Phillip Wallis and Zeyuan Allen-Zhu and Yuanzhi Li and Shean Wang and Lu Wang and Weizhu Chen},
  journal = {ICLR},
  year = {2021},
  eprint = {2106.09685}
}

@article{cpt,
  title = {Continual Pre-training of Language Models},
  author = {Zixuan Ke and Yijia Shao and Haowei Lin and Tatsuya Konishi and Gyuhak Kim and Bing Liu},
  journal = {ICLR},
  year = {2023},
  eprint = {2302.03241}
}

@article{qlora,
  title = {QLoRA: Efficient Finetuning of Quantized LLMs},
  author = {Tim Dettmers and Artidoro Pagnoni and Ari Holtzman and Luke Zettlemoyer},
  journal = {NeurIPS},
  year = {2023},
  eprint = {2305.14314}
}
```

### Level 1 still works, and restart

| # | Action | Expected |
|---|---|---|
| 69 | Library count | 19 papers (Test Paper deleted in 63) |
| 70 | Path Latent Diffusion → Attention Is All You Need | One step (Latent Diffusion cites it directly) |
| 71 | Add a paper (any valid one), then delete it | Both work as in level 1 |
| 72 | Restart the server | Tags (55–57), "PEFT & CPT" with 4 papers, and the CLIP note are all still there |
| 73 | Collections page | Only "PEFT & CPT", with 4 papers |
