"""Show the poll and submit votes from the browser."""

import from server { Poll, poll_counts, vote_tea, vote_coffee }

"""Show the stored counts and buttons for the two choices."""
def:pub app -> JsxElement {
    has tea: int = 0;
    has coffee: int = 0;

    async can with entry {
        poll: Poll = await poll_counts();
        tea = poll.tea;
        coffee = poll.coffee;
    }

    async def onVoteTea {
        poll: Poll = await vote_tea();
        tea = poll.tea;
        coffee = poll.coffee;
    }

    async def onVoteCoffee {
        poll: Poll = await vote_coffee();
        tea = poll.tea;
        coffee = poll.coffee;
    }

    <div>
        <h1>Tea or coffee?</h1>
        <button onClick={onVoteTea}>Vote tea</button>
        <button onClick={onVoteCoffee}>Vote coffee</button>
        <p>{"Tea: " + str(tea)}</p>
        <p>{"Coffee: " + str(coffee)}</p>
    </div>
}
