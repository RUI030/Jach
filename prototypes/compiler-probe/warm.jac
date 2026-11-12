"""Compile the same project repeatedly in one process to measure warm type-check cost."""
import sys;
import time;
import from jaclang.jac0core.program { JacProgram }
import from jaclang.jac0core.compile_options { CompileOptions }

with entry {
    target = sys.argv[-1];
    for i in range(6) {
        t0 = time.perf_counter();
        prog = JacProgram();
        prog.compile(target, options=CompileOptions(type_check=True, no_cgen=True));
        dt = time.perf_counter() - t0;
        print(f"run {i}: {dt*1000:.0f} ms  errors={len(prog.errors_had)} warnings={len(prog.warnings_had)}");
    }
    # one edit-and-recheck: introduce a type error via use_str
    src = open(target).read();
    t0 = time.perf_counter();
    prog = JacProgram();
    prog.compile(target, use_str=src + "\nwith entry { x: int = \"s\"; }\n", options=CompileOptions(type_check=True, no_cgen=True));
    print(f"edited (in-memory source): {(time.perf_counter()-t0)*1000:.0f} ms errors={[str(e.msg)[:60] for e in prog.errors_had]}");
}
