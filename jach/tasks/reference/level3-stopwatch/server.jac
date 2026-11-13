"""Store and retrieve stopwatch laps on the root graph."""

"""Represent one saved elapsed time."""
node Lap {
    has seconds: float;
}

"""Return saved laps in the order they were created."""
def:pub list_laps -> list[Lap] {
    return [root -->[?:Lap]];
}

"""Save an elapsed time as a lap connected to root."""
def:pub save_lap(seconds: float) -> Lap {
    return root ++> Lap(seconds=seconds);
}
