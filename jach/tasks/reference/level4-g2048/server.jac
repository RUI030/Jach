"""Store and retrieve the highest saved 2048 score."""

"""Hold the highest score saved on the server."""
node Best {
    has score: int = 0;
}

"""Return the highest saved score, creating its node on first use."""
def:pub get_best() -> int {
    bests = [root -->][?:Best];
    if not bests {
        return (root ++> Best()).score;
    }
    return bests[0].score;
}

"""Save a score when it exceeds the highest stored score."""
def:pub save_score(score: int) -> int {
    bests = [root -->][?:Best];
    if not bests {
        best = root ++> Best();
    } else {
        best = bests[0];
    }
    if score > best.score {
        best.score = score;
    }
    return best.score;
}
