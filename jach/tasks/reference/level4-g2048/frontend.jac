"""Render and play a 2048 game in the browser."""

import from server { get_best, save_score }

"""Add a random tile to an empty board cell."""
def add_tile(cells: list[int]) -> list[int] {
    empty: list[int] = [];
    for i in range(16) {
        if cells[i] == 0 {
            empty.append(i);
        }
    }
    if empty {
        spot = empty[int(Math.floor(Math.random() * len(empty)))];
        cells[spot] = 4 if Math.random() < 0.1 else 2;
    }
    return cells;
}

"""Create a fresh board with two tiles."""
def fresh_board() -> list[int] {
    cells: list[int] = [0 for _ in range(16)];
    add_tile(cells);
    add_tile(cells);
    return cells;
}

"""Show the board, handle moves, and display the stored best score."""
def:pub app() -> JsxElement {
    has board: list[int] = fresh_board();
    has score: int = 0;
    has moves: int = 0;
    has best: int = 0;
    has key_handlers: list[Callable[[KeyboardEvent], None]] = [];

    async can with entry {
        best = await get_best();
    }

    def move(key: str) {
        next_board: list[int] = board[:];
        gained: int = 0;
        for line in range(4) {
            positions: list[int] = [];
            for offset in range(4) {
                if key == "ArrowLeft" {
                    positions.append(line * 4 + offset);
                } elif key == "ArrowRight" {
                    positions.append(line * 4 + 3 - offset);
                } elif key == "ArrowUp" {
                    positions.append(offset * 4 + line);
                } else {
                    positions.append((3 - offset) * 4 + line);
                }
            }
            values: list[int] = [];
            for position in positions {
                if board[position] != 0 {
                    values.append(board[position]);
                }
            }
            merged: list[int] = [];
            index: int = 0;
            while index < len(values) {
                if index + 1 < len(values) and values[index] == values[index + 1] {
                    value = values[index] * 2;
                    merged.append(value);
                    gained += value;
                    index += 2;
                } else {
                    merged.append(values[index]);
                    index += 1;
                }
            }
            for offset in range(4) {
                next_board[positions[offset]] = merged[offset] if offset < len(merged) else 0;
            }
        }
        moves = moves + 1;
        if next_board != board {
            board = add_tile(next_board);
            score = score + gained;
        }
    }

    can with (board, score, moves) entry {
        if key_handlers {
            window.removeEventListener("keydown", key_handlers[0]);
        }
        handler = lambda (event: KeyboardEvent) {
            if event.key in ["ArrowLeft", "ArrowRight", "ArrowUp", "ArrowDown"] {
                event.preventDefault();
                move(event.key);
            }
        };
        key_handlers = [handler];
        window.addEventListener("keydown", handler);
    }

    def new_game(_event: MouseEvent) {
        board = fresh_board();
        score = 0;
        moves = 0;
    }

    async def save(_event: MouseEvent) {
        best = await save_score(score);
    }

    <main style={{"maxWidth": "360px", "margin": "40px auto", "fontFamily": "sans-serif"}}>
        <h1>2048</h1>
        <p>{f"Score: {score}"}</p>
        <p>{f"Moves: {moves}"}</p>
        <p>{f"Best: {best}"}</p>
        <button onClick={new_game}>New game</button>
        <button onClick={save}>Save score</button>
        <div style={{"display": "grid", "gridTemplateColumns": "repeat(4, 1fr)", "gap": "6px", "marginTop": "20px", "background": "#bbada0", "padding": "6px"}}>
            {for (i, value) in enumerate(board) {
                <div key={str(i)} style={{"height": "75px", "display": "flex", "alignItems": "center", "justifyContent": "center", "background": "#eee4da", "fontSize": "28px", "fontWeight": "bold"}}>{str(value) if value != 0 else ""}</div>
            }}
        </div>
    </main>
}
