"""Client UI."""

import from server { ping }

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
