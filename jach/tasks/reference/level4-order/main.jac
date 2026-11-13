"""Register the food order endpoints and mount the client page."""

import from server { list_shops, get_menu, place_order, list_orders }

import from .frontend { app as ClientApp }

"""Mount the food ordering page at the app entry point."""
def:pub app -> JsxElement {
    <ClientApp/>
}
