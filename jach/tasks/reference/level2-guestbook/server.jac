"""Store guestbook entries on the server."""

"""Represent one guestbook signature connected to root."""
node Entry {
    has name: str;
    has message: str;
}

"""Return the guestbook entries stored under root."""
def:pub list_entries -> list[Entry] {
    return [root -->][?:Entry];
}

"""Save a new guestbook entry under root and return it."""
def:pub add_entry(name: str, message: str) -> Entry {
    return root ++> Entry(name=name, message=message);
}
