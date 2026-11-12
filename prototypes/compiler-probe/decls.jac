"""Declaration-only view of one .jac module (bodies dropped)."""
import sys;
import from jaclang.jac0core.program { JacProgram }
import from jaclang.jac0core.compile_options { CompileOptions }
import from jaclang.jac0core { unitree as uni }

def acc(n: object) -> str {
    a = getattr(n, "access", None);
    return (":" + a.tag.value) if a else "";
}

def doc(n: object) -> str {
    d = getattr(n, "doc", None);
    return (f"  # {d.lit_value.strip()}") if d else "";
}

def ab_line(ab: uni.Ability, ind: str) -> str {
    kw = "async " if ab.is_async else "";
    nm = ab.name_ref.sym_name if ab.name_ref else "?";
    sig = ab.signature.unparse() if ab.signature else "";
    head = "can" if isinstance(ab.signature, uni.EventSignature) else "def";
    if isinstance(ab.signature, uni.EventSignature) { sig = " " + sig; }
    imp_s = "" if ab.body else "   [decl only]";
    return f"{ind}{kw}{head}{acc(ab)} {nm}{sig};{doc(ab)}{imp_s}";
}

with entry {
    prog = JacProgram();
    mod = prog.compile(sys.argv[-1], options=CompileOptions(type_check=True, no_cgen=True));
    for el in mod.body {
        if isinstance(el, uni.Archetype) {
            print(f"{el.arch_type.value}{acc(el)} {el.name.value} {{{doc(el)}");
            for st in (el.body if isinstance(el.body, list) else []) {
                if isinstance(st, uni.ArchHas) {
                    for v in st.vars {
                        dv = (" = " + v.value.unparse()) if v.value else "";
                        print(f"    has {v.name.value}{v.type_tag.unparse()}{dv};");
                    }
                } elif isinstance(st, uni.Ability) {
                    print(ab_line(st, "    "));
                }
            }
            print("}");
        } elif isinstance(el, uni.Ability) {
            print(ab_line(el, ""));
            if el.body {
                for st in el.body {
                    if isinstance(st, uni.ArchHas) {
                        for v in st.vars {
                            dv = (" = " + v.value.unparse()) if v.value else "";
                            print(f"    has {v.name.value}{v.type_tag.unparse()}{dv};   [component state]");
                        }
                    } elif isinstance(st, uni.Ability) {
                        print(ab_line(st, "    ") + "   [component handler]");
                    }
                }
            }
        } elif isinstance(el, uni.Import) {
            print(el.unparse().strip());
        }
    }
}
