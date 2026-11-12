import sys;
import time;
import from jaclang.jac0core.program { JacProgram }
import from jaclang.jac0core.compile_options { CompileOptions }

def chk(target: str, label: str) -> None {
    t0 = time.perf_counter();
    prog = JacProgram();
    prog.compile(target, options=CompileOptions(type_check=True, no_cgen=True));
    print(f"{label}: {(time.perf_counter()-t0)*1000:.0f} ms errors={[ (e.loc.mod_path.split('/')[-1], e.loc.first_line, str(e.msg)[:70]) for e in prog.errors_had]}");
}

with entry {
    d = sys.argv[-1];
    chk(d + "/main.jac", "cold");
    chk(d + "/main.jac", "warm");
    m = open(d + "/model.jac").read();
    open(d + "/model.jac", "w").write(m.replace("def:pub count_open(prefix: str = \"\", limit: int = 10)", "def:pub count_open(prefix: str, limit: int)"));
    chk(d + "/main.jac", "after editing model.jac on disk (main calls nothing)");
    open(d + "/main.jac", "a").write("\nwith entry { n: int = count_open(\"a\"); }\n");
    chk(d + "/main.jac", "after adding bad call in main.jac");
    chk(d + "/main.jac", "warm again");
}
