# Conventions for this Jac 0.36 project

Read the Jac skills before writing: jac-core-cheatsheet, jac-node-edge-patterns, jac-walker-patterns, jac-sv-endpoints, jac-cl-components, jac-fullstack-patterns. `jac guide <name>` prints one.

Write Jac, not Python in Jac syntax:

- Stored data is `node`s connected to `root`, related by edges. No module-level variables, dicts or lists as a data store.
- Data with a parent and children (shop and its dishes, board and its cards) is a graph: parent node, child nodes, an edge between them. Not nested lists or `if`/`else` tables.
- A read or update that walks more than one hop from `root` is a `walker:pub`. A single-hop read or write is a `def:pub`. Both are correct Jac; pick by this rule.
- Fixed data the app starts with is created as nodes on first use, never duplicated.
- Every `def:pub` and `walker:pub` has one sentence above it saying what it does. No Args/Returns lists.
- The entry file imports every server name the page calls.
- Page state is `has` fields; load in `async can with entry`.
