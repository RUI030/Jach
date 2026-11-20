"""Entry point. Every server endpoint the client calls must be named in an import here."""

import from server { ping }

import from .frontend { app as ClientApp }
import ".styles.global.css";

"""Mount the client page as the app."""
def:pub app -> JsxElement {
    <ClientApp/>
}
