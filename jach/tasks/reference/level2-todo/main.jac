"""Entry point. Every server endpoint the client calls must be named in an import here."""

import from server { Task, list_tasks, add_task }

import from .frontend { app as ClientApp }

"""Mount the client page as the app."""
def:pub app -> JsxElement {
    <ClientApp/>
}
