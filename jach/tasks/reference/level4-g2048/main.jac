"""Register the 2048 server endpoints and mount the client page."""

import from server { get_best, save_score }

import from .frontend { app as ClientApp }

"""Mount the 2048 game page."""
def:pub app() -> JsxElement {
    <ClientApp />
}
