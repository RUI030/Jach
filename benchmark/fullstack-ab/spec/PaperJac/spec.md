Build a web app called **{APP}**: a paper library that also shows how its papers cite each other.

**Stack.** {STACK} `papers.json` is in the project root.

**Data.** `papers.json` has two lists:
- `papers`: each has `id` (unique), `short` (display name), `title`, `authors` (list, in order),
  `year`, `venue`, `field`, and either `arxiv` or `doi`.
- `cites`: each is `{"from": <id>, "to": <id>}`, meaning paper `from` cites paper `to`.

On first start the app loads this file. Every change made through the app (add, edit, delete) must
still be there after the server restarts.

**Pages.** Every page has a navigation bar linking to Library, Graph and Analysis.

1. **Library** (home page): a table of every paper with short name, title, year, venue and field.
   Filter by field and by a year range; search by words in the title or by author name.
   Buttons to add a paper, and to open, edit or delete each paper.
2. **Paper page**: every field of one paper, the papers it cites and the papers that cite it, each
   list with its count. Every listed paper links to its page; every author links to their author
   page. Buttons to edit and delete this paper.
3. **Author page**: every paper that author is on, each linking to its paper page.
4. **Graph**: all papers as nodes, citations as arrows from the citing paper to the cited one,
   nodes coloured by field. Clicking a node opens that paper's page.
5. **Analysis**, three sections:
   - **Most cited**: papers ranked by how many papers in the app cite them, highest first.
   - **Unconnected papers**: papers that neither cite nor are cited by any paper in the app.
   - **Citation path**: pick paper A and paper B and show the shortest chain A cites … cites B,
     following citations in their direction only, each step linking to its paper page. If there is
     no such chain, say so.

**Operations.**
- **Add**: a form for every paper field plus the existing papers it cites.
- **Edit**: the same form, filled in; every field except `id` can change, including what it cites.
- **Delete**: asks for confirmation, then removes the paper and every citation from or to it.
- Reject an add or edit, with a message saying why, when the id is already taken, a required field is
  empty, or the change would leave any paper citing a paper from a later year.
- After any operation, every page shows the new state.

When you are done, tell me the exact command(s) to start the app and the URL to open.
