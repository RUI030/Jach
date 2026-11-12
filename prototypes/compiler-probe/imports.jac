"""Print the import graph of a Jac project: file -> names -> module -> resolved file."""
import sys;
import os;
import glob as pyglob;
import from jaclang.jac0core.program { JacProgram }
import from jaclang.jac0core.compile_options { CompileOptions }
import from jaclang.jac0core { unitree as uni }

with entry {
    root_dir = os.path.abspath(sys.argv[-1]);
    files = sorted(pyglob.glob(os.path.join(root_dir, "**", "*.jac"), recursive=True));
    for f in files {
        if ".impl." in f or "/.jac/" in f or "node_modules" in f { continue; }
        prog = JacProgram();
        mod = prog.compile(f, options=CompileOptions(type_check=True, no_cgen=True));
        rel = os.path.relpath(f, root_dir);
        for imp in mod.get_all_sub_nodes(uni.Import) {
            if imp.from_loc {
                mp = imp.from_loc;
                target = mp.resolve_relative_path();
                exists = os.path.exists(target);
                names = [];
                for it in imp.items {
                    nm = it.name.value;
                    found = "?";
                    if imp.ecosystem == "jac" and target in prog.mod.hub {
                        found = "ok" if nm in prog.mod.hub[target].names_in_scope else "NOT-EXPORTED";
                    } elif imp.ecosystem == "string" {
                        pj = os.path.join(root_dir, ".jac", "client", "node_modules", mp.dot_path_str, "package.json");
                        found = "npm-installed" if os.path.exists(pj) else "npm-NOT-INSTALLED";
                    }
                    names.append(f"{nm}[{found}]");
                }
                tgt = os.path.relpath(target, root_dir) if exists else f"{target} (MISSING)";
                print(f"{rel}:{imp.loc.first_line}  {', '.join(names)}  from {mp.dot_path_str} ({imp.ecosystem}) -> {tgt}");
            } else {
                for mp in imp.items {
                    print(f"{rel}:{imp.loc.first_line}  import {mp.dot_path_str} -> {mp.resolve_relative_path()}");
                }
            }
        }
        for e in prog.errors_had { print(f"  ERR {e}"); }
    }
}
