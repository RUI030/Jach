"""Work tree: Project -> Feature -> Task -> Step -> Turn (decision 0005)."""

node Project { has name: str; has dir: str; has brief: str = ""; }
node Feature { has fid: str; has title: str; }
node Task {
    has tid: str;
    has title: str;
    has goal: str;
    has writes: list[str] = [];
    has status: str = "ready";
}
node Step { has kind: str; has status: str = "pending"; has failures: int = 0; }
node Turn {
    has mid: str;
    has tool: str;
    has target: str = "";
    has status: str = "";
    has code: str = "";
    has message: str = "";
}
edge Has {}
edge Then {}
