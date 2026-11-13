"""Store and update the poll on the server."""

"""Hold the persistent vote counts."""
node Poll {
    has tea: int = 0;
    has coffee: int = 0;
}

"""Find the poll under root or create it with zero votes."""
def get_poll -> Poll {
    polls = [root -->][?:Poll];
    if polls {
        return polls[0];
    }
    return root ++> Poll();
}

"""Return the stored poll counts to the page."""
def:pub poll_counts -> Poll {
    return get_poll();
}

"""Add one tea vote and return the updated counts."""
def:pub vote_tea -> Poll {
    poll = get_poll();
    poll.tea += 1;
    return poll;
}

"""Add one coffee vote and return the updated counts."""
def:pub vote_coffee -> Poll {
    poll = get_poll();
    poll.coffee += 1;
    return poll;
}
