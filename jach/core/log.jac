"""Run log: one append-only JSONL file per run, plus the complete prompts (decision 0012)."""
import json;
import gzip;
import os;
import time;

obj RunLog {
    has run_dir: str;
    has seq: int = 0;
    has where: dict = {};

    def postinit {
        os.makedirs(self.run_dir, exist_ok=True);
    }

    """Set the position (session, phase, feature, task, step) stamped on later events."""
    def at(pos: dict) {
        self.where.update(pos);
    }

    """Append one event and return its seq."""
    def event(etype: str, actor: str, fields: dict) -> int {
        self.seq += 1;
        row = {"v": 1, "seq": self.seq, "ts": round(time.time(), 3), "type": etype, "actor": actor};
        row.update(self.where);
        row.update(fields);
        with open(os.path.join(self.run_dir, "events.jsonl"), "a") as f {
            f.write(json.dumps(row, ensure_ascii=False) + "\n");
        }
        return self.seq;
    }

    """Save the complete rendered prompt of a request."""
    def prompt(seq: int, text: str) {
        with gzip.open(os.path.join(self.run_dir, "prompts.jsonl.gz"), "at") as f {
            f.write(json.dumps({"seq": seq, "prompt": text}, ensure_ascii=False) + "\n");
        }
    }

    def meta(data: dict) {
        with open(os.path.join(self.run_dir, "meta.json"), "w") as f {
            f.write(json.dumps(data, indent=2));
        }
    }
}
