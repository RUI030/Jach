"""Store and retrieve notes connected to the root node."""

"""Hold the title of a stored note."""
node Note {
    has title: str;
}

"""Create a note under root and return its title."""
def:pub create_note(title: str) -> str {
    note = root ++> Note(title=title);
    return note.title;
}

"""List the titles of notes stored under root."""
def:pub list_notes -> list[str] {
    return [note.title for note in [root -->][?:Note]];
}
