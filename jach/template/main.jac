"""Entry point. Every server endpoint the client calls must be named in an import here."""

import from server { ping }

import from .frontend { app as ClientApp }

def:pub app -> JsxElement {
    <ClientApp/>
}
