"""Display and update the to-do list."""

import from server { Task, list_tasks, add_task }

"""Show stored tasks and let the user add a new one."""
def:pub app -> JsxElement {
    has title: str = "";
    has tasks: list[Task] = [];

    async can with entry {
        tasks = await list_tasks();
    }

    def on_input(e: ChangeEvent) {
        title = e.target.value;
    }

    async def on_add {
        if title {
            tasks = tasks + [await add_task(title)];
            title = "";
        }
    }

    <div>
        <h1>To-do list</h1>
        <input placeholder="New task" value={title} onChange={on_input} />
        <button onClick={on_add}>Add</button>
        <ul>{for task in tasks { <li key={jid(task)}>{task.title}</li> }}</ul>
    </div>
}
