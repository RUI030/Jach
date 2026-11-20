"""Jac documentation of the installed version, read from `jac guide` at run time (decision 0008).
Nothing here is written for one Jac version: names, pages and sections all come from the binary."""
import os;
import re;
import json;
import difflib;
import subprocess;
import from check { reserved_words }

glob GUIDE_CHARS = int(os.environ.get("JACH_GUIDE_CHARS", "12000"));  # setting: a longer page or section is shown as its outline
glob SEARCH_GROUPS = 12;
glob LIST_SECTIONS = 40;
glob PAGES: dict = {};
glob INDEX: list = [];

"""Run `jac guide` with the given arguments and return what it prints."""
def jac_guide(args: list[str]) -> str {
    env = dict(os.environ);
    env["NO_COLOR"] = "1";
    p = subprocess.run(["jac", "guide"] + args, capture_output=True, text=True, timeout=60, env=env);
    return p.stdout + p.stderr;
}

"""Every guide and doc of the installed version: name, description, group, kind (skill or doc)."""
def guide_index -> list[dict] {
    if not INDEX { INDEX.extend(json.loads(jac_guide(["--json"]))); }
    return INDEX;
}

"""The skills, one line each: the name and the first part of its description."""
def skill_list -> str {
    # The first clause of each description: up to " - " or the end of the first sentence.
    return "\n".join([f"  {e['name']}: {re.split(r' - |\. ', e['description'])[0].rstrip('.')}" for e in guide_index() if e["kind"] == "skill"]);
}

"""Text of one guide or doc; empty when the installed version has no such name."""
def page(topic: str) -> str {
    if topic not in PAGES {
        names = [e["name"] for e in guide_index()];
        PAGES[topic] = jac_guide([topic]).rstrip("\n") if topic in names else "";
    }
    return PAGES[topic];
}

"""Markdown headings outside code blocks, in order: level, title and the index of the heading line."""
def headings(lines: list[str]) -> list[dict] {
    found: list[dict] = [];
    fence = False;
    for (i, ln) in enumerate(lines) {
        if ln.lstrip().startswith("```") { fence = not fence; continue; }
        if fence { continue; }
        m = re.match(r"(#{1,6})\s+(.*)", ln);
        if m { found.append({"level": len(m.group(1)), "title": m.group(2).strip(), "start": i}); }
    }
    return found;
}

"""Index of the line after heading k's section: the next heading of the same or a higher level."""
def section_end(lines: list[str], hs: list[dict], k: int) -> int {
    for h in hs[k + 1:] {
        if h["level"] <= hs[k]["level"] { return h["start"]; }
    }
    return len(lines);
}

"""Lines lo..hi as text when they fit GUIDE_CHARS; otherwise the text before the first subsection
and the list of subsections, so the model can ask for one."""
def fit(lines: list[str], hs: list[dict], lo: int, hi: int, level: int) -> str {
    text = "\n".join(lines[lo:hi]).strip("\n");
    if len(text) <= GUIDE_CHARS { return text; }
    inner = [h for h in hs if lo < h["start"] and h["start"] < hi and h["level"] > level];
    if not inner { return text[:GUIDE_CHARS] + f"\n[cut at {GUIDE_CHARS} of {len(text)} characters]"; }
    top = min([h["level"] for h in inner]);
    kids = [h for h in inner if h["level"] == top];
    intro = "\n".join(lines[lo:kids[0]["start"]]).strip("\n")[:GUIDE_CHARS // 2];
    rows: list[str] = [];
    for (j, h) in enumerate(kids[:LIST_SECTIONS]) {
        end = kids[j + 1]["start"] if j + 1 < len(kids) else hi;
        rows.append(f"  {h['title']}  ({len(chr(10).join(lines[h['start']:end]))} characters)");
    }
    more = f"\n  ... and {len(kids) - LIST_SECTIONS} more" if len(kids) > LIST_SECTIONS else "";
    return f"{intro}\n\n[{len(text)} characters, too long to show whole. Sections; read one with guide(topic, section):]\n" + "\n".join(rows) + more;
}

"""The `guide` tool: a whole page, or one section of it found by heading title."""
def guide_text(topic: str, section: str = "") -> dict {
    topic = topic.strip();
    text = page(topic);
    if not text {
        names = [e["name"] for e in guide_index()];
        close = difflib.get_close_matches(topic, names, n=5, cutoff=0.4);
        return {"ok": False, "text": f"failed: no guide `{topic}`. Closest names: {', '.join(close) if close else '(none)'}. guide_search finds a word in every guide."};
    }
    lines = text.split("\n");
    hs = headings(lines);
    if not section.strip() { return {"ok": True, "text": f"guide {topic}\n\n" + fit(lines, hs, 0, len(lines), 0)}; }
    want = section.strip().lstrip("#").strip().lower();
    hits = [k for (k, h) in enumerate(hs) if h["title"].lower() == want];
    if not hits { hits = [k for (k, h) in enumerate(hs) if want in h["title"].lower()]; }
    if not hits {
        tops = [h["title"] for h in hs if h["level"] == min([x["level"] for x in hs if x["level"] > 1] + [9])];
        return {"ok": False, "text": f"failed: no section `{section}` in {topic}. Sections:\n" + "\n".join(["  " + t for t in tops[:LIST_SECTIONS]])};
    }
    k = hits[0];
    body = fit(lines, hs, hs[k]["start"], section_end(lines, hs, k), hs[k]["level"]);
    also = "\n\nAlso matching: " + "; ".join([hs[j]["title"] for j in hits[1:6]]) if len(hits) > 1 else "";
    return {"ok": True, "text": f"guide {topic} > {hs[k]['title']}\n\n{body}{also}"};
}

"""The `guide_search` tool: every guide section that contains the text, with its first matching line."""
def guide_search(text: str) -> dict {
    if not text.strip() { return {"ok": False, "text": "failed: give a word or phrase to search for."}; }
    out = jac_guide(["--search", text]);
    groups: dict = {};
    skipped = 0;
    for ln in out.split("\n") {
        m = re.match(r"([\w./-]+):(\d+): ?(.*)", ln);
        if not m { continue; }
        topic = m.group(1);
        lno = int(m.group(2)) - 1;
        if len(groups) >= SEARCH_GROUPS and topic not in PAGES { skipped += 1; continue; }
        hs = headings(page(topic).split("\n"));
        sec = "";
        for h in hs { if h["start"] <= lno and h["level"] > 1 { sec = h["title"]; } }
        key = f"{topic} > {sec}" if sec else topic;
        if key not in groups {
            if len(groups) >= SEARCH_GROUPS { skipped += 1; continue; }
            groups[key] = {"n": 0, "first": m.group(3).strip()[:160]};
        }
        groups[key]["n"] += 1;
    }
    if not groups { return {"ok": False, "text": f"no guide contains `{text}`."}; }
    rows = [f"  {key}  ({g['n']} lines)\n      {g['first']}" for (key, g) in groups.items()];
    more = f"\n{skipped} more matching lines in other sections are not shown; search for something more specific." if skipped else "";
    return {"ok": True, "text": f"Sections containing `{text}` (topic > section); read one with guide(topic, section):\n" + "\n".join(rows) + more};
}

"""Names the installed compiler refuses, from probing it with every word in the syntax reference's code."""
def reserved_text -> str {
    code = "\n".join(re.findall(r"```[a-z]*\n(.*?)```", page("reference/language/syntax-cheatsheet"), re.S));
    words = reserved_words(re.findall(r"[A-Za-z_][A-Za-z0-9_]*", code));
    return "Reserved words; none of them can name a variable, parameter or field: " + " ".join(words);
}

"""A section of a guide, or empty when the installed version has no such guide or section."""
def section_text(topic: str, section: str) -> str {
    g = guide_text(topic, section);
    return g["text"] if g["ok"] else "";
}
