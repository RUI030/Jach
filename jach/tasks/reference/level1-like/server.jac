"""Store and update the like count on the server."""

"""Hold the persistent number of likes connected to root."""
node Counter {
    has likes: int = 0;
}

"""Find the root's counter or create it with zero likes."""
def _counter -> Counter {
    counters = [root -->][?:Counter];
    if counters {
        return counters[0];
    }
    return (root ++> Counter()) as Counter;
}

"""Return the stored number of likes."""
def:pub get_likes -> int {
    return _counter().likes;
}

"""Add one like and return the updated number."""
def:pub like -> int {
    counter = _counter();
    counter.likes += 1;
    return counter.likes;
}
