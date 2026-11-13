"""Store shopping items as nodes connected to the root."""

"""Represent one stored shopping item."""
node Item {
    has name: str;
}

"""Return the shopping items connected to the root."""
def:pub list_items -> list[Item] {
    return [root -->][?:Item];
}

"""Add a shopping item to the root and return it."""
def:pub add_item(name: str) -> Item {
    return root ++> Item(name=name);
}

"""Delete the root's shopping item with the given identifier."""
def:pub remove_item(item_id: str) -> None {
    for item in [root -->][?:Item] {
        if jid(item) == item_id {
            del item;
            return;
        }
    }
}
