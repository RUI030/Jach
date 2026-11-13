"""Store and retrieve to-do tasks on the server."""

"""Represent one stored to-do task."""
node Task {
    has title: str;
}

"""Return the tasks connected to root."""
def:pub list_tasks -> list[Task] {
    return [root -->][?:Task];
}

"""Create a task with the given title and connect it to root."""
def:pub add_task(title: str) -> Task {
    return root ++> Task(title=title);
}
