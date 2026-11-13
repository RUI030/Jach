"""Register the note endpoints and mount the client page."""

import from server { create_note, list_notes }

import from .frontend { app as ClientApp }

"""Mount the notes page as the app."""
def:pub app -> JsxElement {
    <ClientApp/>
}
