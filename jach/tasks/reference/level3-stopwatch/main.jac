"""Register the stopwatch endpoints and mount the client page."""

import from server { Lap, list_laps, save_lap }

import from .frontend { app as ClientApp }

"""Mount the stopwatch page as the application."""
def:pub app -> JsxElement {
    <ClientApp/>
}
