"""Show and edit the shopping list in the browser."""

import from server { Item, list_items, add_item, remove_item }

"""Display stored items and provide controls to add or remove them."""
def:pub app -> JsxElement {
    has name: str = "";
    has items: list[Item] = [];

    async can with entry {
        items = await list_items();
    }

    def onInput(e: ChangeEvent) {
        name = e.target.value;
    }

    async def onAdd {
        if name {
            created = await add_item(name);
            name = "";
            items = items + [created];
        }
    }

    async def onRemove(item_id: str) {
        await remove_item(item_id);
        items = [item for item in items if jid(item) != item_id];
    }

    <div>
        <input placeholder="Item" value={name} onChange={onInput} />
        <button onClick={onAdd}>Add</button>
        <ul>{for item in items {
            <li key={jid(item)}>{item.name} <button onClick={lambda { onRemove(jid(item)); }}>{"Remove " + item.name}</button></li>
        }}</ul>
    </div>
}
