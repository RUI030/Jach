"""Store food shops, dishes, and placed orders in the shared graph."""

"""Represent a food shop with its name."""
node Shop {
    has name: str;
}

"""Represent a dish sold by a shop."""
node Dish {
    has name: str;
    has price: int;
}

"""Represent a placed order with its items and total."""
node Order {
    has items: list[str];
    has total: int;
}

"""Create the fixed shops and menus once and return the shops."""
def:pub list_shops -> list[Shop] {
    shops = [root -->[?:Shop]];
    if not shops {
        noodle = root ++> Shop(name="Noodle House");
        noodle ++> Dish(name="Beef noodles", price=8);
        noodle ++> Dish(name="Dumplings", price=5);
        tea = root ++> Shop(name="Tea Bar");
        tea ++> Dish(name="Milk tea", price=3);
        tea ++> Dish(name="Green tea", price=2);
        shops = [root -->[?:Shop]];
    }
    return shops;
}

"""Walk from root through the named shop to report its dishes."""
walker:pub get_menu {
    has shop_name: str;
    has dishes: list[Dish] = [];
    has reports: list[list[Dish]] = [];

    can find_shop with Root entry {
        visit [here -->[?:Shop]];
    }

    can find_dishes with Shop entry {
        if here.name == self.shop_name {
            visit [here -->[?:Dish]];
        }
    }

    can collect_dish with Dish entry {
        self.dishes.append(here);
    }

    can finish with Root exit {
        report self.dishes;
    }
}

"""Save a new order under root and return it."""
def:pub place_order(items: list[str], total: int) -> Order {
    return root ++> Order(items=items, total=total);
}

"""Return placed orders in the order they were created."""
def:pub list_orders -> list[Order] {
    return [root -->[?:Order]];
}
