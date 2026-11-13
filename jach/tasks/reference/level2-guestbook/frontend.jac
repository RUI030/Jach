"""Render the guestbook page."""

import from server { Entry, list_entries, add_entry }

"""Show stored entries and let a visitor sign the guestbook."""
def:pub app -> JsxElement {
    has name: str = "";
    has message: str = "";
    has entries: list[Entry] = [];

    async can with entry {
        entries = await list_entries();
    }

    def on_name_change(e: ChangeEvent) {
        name = e.target.value;
    }

    def on_message_change(e: ChangeEvent) {
        message = e.target.value;
    }

    async def on_sign(_e: MouseEvent) {
        entries = entries + [await add_entry(name, message)];
        name = "";
        message = "";
    }

    <div>
        <h1>Guestbook</h1>
        <input placeholder="Your name" value={name} onChange={on_name_change} />
        <input placeholder="Message" value={message} onChange={on_message_change} />
        <button onClick={on_sign}>Sign</button>
        <ul>{for item in entries { <li key={jid(item)}>{item.name + ": " + item.message}</li> }}</ul>
    </div>
}
