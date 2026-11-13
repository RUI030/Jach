"""Show and control the stopwatch and its saved laps."""

import from server { Lap, list_laps, save_lap }

"""Render the elapsed time, controls, and saved laps."""
def:pub app -> JsxElement {
    has elapsed: float = 0.0;
    has running: bool = False;
    has timer_id: float | None = None;
    has laps: list[Lap] = [];

    async can with entry {
        laps = await list_laps();
    }

    def on_start {
        if running { return; }
        running = True;
        started_at = Date.now() - elapsed * 1000;
        timer_id = setInterval(lambda {
            elapsed = (Date.now() - started_at) / 1000;
        }, 100);
    }

    def on_stop {
        if timer_id is not None { clearInterval(timer_id); }
        timer_id = None;
        running = False;
    }

    def on_reset {
        on_stop();
        elapsed = 0.0;
    }

    async def on_save_lap {
        saved = await save_lap(elapsed);
        laps = laps + [saved];
    }

    <div>
        <h1>Stopwatch</h1>
        <p>{"Elapsed: " + format(elapsed, ".1f") + " s"}</p>
        <button onClick={on_start}>Start</button>
        <button onClick={on_stop}>Stop</button>
        <button onClick={on_reset}>Reset</button>
        <button onClick={on_save_lap}>Save lap</button>
        <ul>
            {for (i, lap) in enumerate(laps) {
                <li key={str(i)}>{"Lap " + str(i + 1) + ": " + format(lap.seconds, ".1f") + " s"}</li>
            }}
        </ul>
    </div>
}
