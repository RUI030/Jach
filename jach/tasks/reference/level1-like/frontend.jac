"""Show the stored like count and a button to increase it."""

import from server { get_likes, like }

"""Load the stored count and update it when Like is clicked."""
def:pub app -> JsxElement {
    has likes: int = 0;

    async can with entry {
        likes = await get_likes();
    }

    async def onLike {
        likes = await like();
    }

    <div>
        <p>{"Likes: " + str(likes)}</p>
        <button onClick={onLike}>Like</button>
    </div>
}
