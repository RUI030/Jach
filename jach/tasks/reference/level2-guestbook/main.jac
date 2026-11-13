"""Register guestbook endpoints and mount the client page."""

import from server { list_entries, add_entry }

import from .frontend { app as ClientApp }

"""Mount the guestbook page at the app entry point."""
def:pub app -> JsxElement {
    <ClientApp/>
}
