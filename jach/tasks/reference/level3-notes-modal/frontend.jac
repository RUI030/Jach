"""Render the notes page and its new note dialog."""

import from server { create_note, list_notes }

"""Show stored note titles and let the user create or cancel a note."""
def:pub app -> JsxElement {
    has notes: list[str] = [];
    has title: str = "";
    has dialog_open: bool = False;

    async can with entry {
        notes = await list_notes();
    }

    def onOpen {
        title = "";
        dialog_open = True;
    }

    def onTitleChange(e: ChangeEvent) {
        title = e.target.value;
    }

    def onCancel {
        dialog_open = False;
    }

    async def onSave {
        saved_title = await create_note(title);
        notes = notes + [saved_title];
        dialog_open = False;
    }

    <main>
        <h1>Notes</h1>
        <button onClick={onOpen}>New note</button>
        <ul>
            {for (i, note_title) in enumerate(notes) {
                <li key={str(i)}>{note_title}</li>
            }}
        </ul>
        {if dialog_open {
            <dialog open>
                <input placeholder="Title" value={title} onChange={onTitleChange} />
                <button onClick={onSave}>Save</button>
                <button onClick={onCancel}>Cancel</button>
            </dialog>
        }}
    </main>
}
