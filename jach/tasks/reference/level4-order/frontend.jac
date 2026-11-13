"""Render the food ordering page and its cart."""

import from .server { Shop, Dish, Order, list_shops, get_menu, place_order, list_orders }

"""Show shops, the selected menu, the cart total, and saved orders."""
def:pub app -> JsxElement {
    has shops: list[Shop] = [];
    has dishes: list[Dish] = [];
    has orders: list[Order] = [];
    has selected_shop: str = "";
    has cart_items: list[str] = [];
    has total: int = 0;
    has placed: bool = False;

    async can with entry {
        shops = await list_shops();
        orders = await list_orders();
    }

    async def show_menu(name: str) {
        selected_shop = name;
        menu = root spawn get_menu(shop_name=name);
        dishes = menu.reports[0] if menu.reports else [];
    }

    def add_dish(dish: Dish) {
        cart_items = cart_items + [dish.name];
        total = total + dish.price;
    }

    async def submit_order {
        order = await place_order(cart_items, total);
        orders = orders + [order];
        cart_items = [];
        total = 0;
        placed = True;
    }

    <div>
        <h1>Food order</h1>
        <div>{for shop in shops {
            <button key={shop.name} onClick={lambda { show_menu(shop.name); }}>{shop.name}</button>
        }}</div>
        {if selected_shop {
            <h2>{selected_shop}</h2>
            <div>{for dish in dishes {
                <div key={dish.name}>
                    <span>{dish.name}{": $"}{dish.price}</span>
                    <button onClick={lambda { add_dish(dish); }}>{"Add "}{dish.name}</button>
                </div>
            }}</div>
        }}
        <p>{"Total: $"}{total}</p>
        <button onClick={submit_order}>Place order</button>
        {if placed { <p>Order placed</p> }}
        <div>{for (index, order) in enumerate(orders) {
            <p key={str(index)}>{"Order "}{index + 1}{": $"}{order.total}</p>
        }}</div>
    </div>
}
