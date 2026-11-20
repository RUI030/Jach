This project is a paper library app already built from `SPEC.md`. Keep everything it does working,
and add the features below. Everything they create must still be there after the server restarts.

1. **Tags**: a paper can have any number of free-text tags. Add and remove them on the paper page.
   Show them on the paper page and in the Library table, and let the Library filter by tag.
2. **Collections**: a new **Collections** page, linked from the navigation bar, lists every
   collection with its number of papers. Create, rename and delete a collection there; deleting a
   collection does not delete its papers. Each collection has its own page listing its papers.
   A paper can be in any number of collections; the paper page shows which ones, and has a way to add
   it to or remove it from a collection.
3. **Bulk add**: in the Library, select several papers and add them all to a collection at once.
4. **Notes**: each paper page has one free-text note that can be edited and saved.
5. **BibTeX export**: the paper page shows the paper's BibTeX entry with a button to copy it, and each
   collection page exports all its papers as one BibTeX text, sorted by year and then by id.
   Use exactly this format: entry type `article`, key = the paper's `id`, fields in this order,
   authors joined with ` and `, and `eprint` for an arXiv id or `doi` for a DOI:

   ```bibtex
   @article{qlora,
     title = {QLoRA: Efficient Finetuning of Quantized LLMs},
     author = {Tim Dettmers and Artidoro Pagnoni and Ari Holtzman and Luke Zettlemoyer},
     journal = {NeurIPS},
     year = {2023},
     eprint = {2305.14314}
   }
   ```

   Entries in one export are separated by one blank line.
6. A deleted paper disappears from every collection it was in.

When you are done, tell me the exact command(s) to start the app and the URL to open.
