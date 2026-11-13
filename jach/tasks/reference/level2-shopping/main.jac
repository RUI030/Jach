"""Register the shopping list endpoints and mount the client page."""

import from server { Item, list_items, add_item, remove_item }

import from .frontend { app as ClientApp }

"""Mount the shopping list page as the app."""
def:pub app -> JsxElement {
    <ClientApp/>
}
