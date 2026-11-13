"""Client UI."""

import from server { ping }

"""Show the page: a Ping button and the reply from the server."""
def:pub app -> JsxElement {
    has reply: str = "";

    async def onPing {
        reply = await ping();
    }

    <div>
        <h1>App</h1>
        <button onClick={onPing}>Ping</button>
        <p>{reply}</p>
    </div>
}
