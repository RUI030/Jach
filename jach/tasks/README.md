# Task specs

Each task has two specs with the same browser actions:

- `<id>.json`: the Jac version. The run starts from `jach/template`; the goal names the nodes and fields to use, and only `server.jac`, `frontend.jac` and `main.jac` may change.
- `any/<id>.json`: the any-stack baseline (`gate.jac ... any`). The run starts from an empty folder and the app is started with `sh start.sh`; the goal names no Jac types and says the data must survive a server restart.

Every action starts with `open /`. Actions run in order on one data store, and the server is restarted before the last action.

| Difficulty | Level | Tasks |
|---|---|---|
| easy | 1: one call from client to server | hello, like |
| easy | 2: one node type, plain CRUD | todo, guestbook, poll, shopping, checkin, expenses, shortener |
| hard | 3: one extra rule or UI behaviour | booking, notes-modal, stopwatch |
| hard | 4: a small app | g2048, order, kanban, pantry |
| hard | 5: a complete app, several node types linked by edges, two views or derived values | forum, splitter, recipes, survey |

Tasks added on 2026-11-19 (`inspired_by` in the spec names the open-source apps they reduce):

| Task | Reduces |
|---|---|
| level2-expenses | ExpenseOwl, ezBookkeeping |
| level2-shortener | Kutt, YOURLS, Shlink |
| level4-kanban | Plane, WeKan, Vikunja |
| level4-pantry | Grocy, KitchenOwl |
| level5-forum | Lobsters, Discourse, Apache Answer |
| level5-splitter | Spliit |
| level5-recipes | Mealie, Tandoor, KitchenOwl |
| level5-survey | Formbricks |

None of these eight has a reference solution under `reference/` yet (nor do level1-hello, level3-booking and level4-order), so they are not validated.
