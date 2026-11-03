import json

def itype(imm, rs1, funct3, rd, opcode):
    imm &= 0xFFF
    return (imm<<20)|(rs1<<15)|(funct3<<12)|(rd<<7)|opcode
def stype(imm, rs2, rs1, funct3, opcode):
    imm &= 0xFFF
    return (((imm>>5)&0x7F)<<25)|(rs2<<20)|(rs1<<15)|(funct3<<12)|((imm&0x1F)<<7)|opcode

def addi(rd, rs1, imm): return itype(imm, rs1, 0, rd, 0b0010011)
def sw(rs2, imm, rs1): return stype(imm, rs2, rs1, 0b010, 0b0100011)
def lw(rd, imm, rs1): return itype(imm, rs1, 0b010, rd, 0b0000011)

def block(kind, reorder=False):
    gap = [addi(31,31,1)] if reorder else []
    if kind == 'C1':
        return [lw(29,0,28)] + gap + [addi(30,29,1)]
    elif kind == 'C2':
        return [addi(28,0,4), addi(13,0,5), lw(29,0,28)] + gap + [addi(30,29,1)]
    elif kind == 'C3':
        return [addi(28,0,0), lw(29,0,28)] + gap + [addi(30,29,1)]

def build_program(mix, iters, reorder=False):
    # "iters" repeats of the full block-mix, unrolled -- identical executed
    # instruction stream to a real loop run `iters` times, no branches needed.
    prog = [addi(1,0,111), addi(2,0,0), sw(1,0,2), addi(28,0,0)]
    for _ in range(iters):
        for k in mix:
            prog += block(k, reorder)
    sentinel_pc = len(prog)*4
    prog += [addi(31,0,999)]
    return prog, sentinel_pc

EXPERIMENTS = {
    1:  ['C1']*5,
    2:  ['C1']*3 + ['C2']*2,
    3:  ['C1']*2 + ['C2']*2 + ['C3'],
    4:  ['C1']*4 + ['C3'],
    5:  ['C1']*2 + ['C2']*3,
}

if __name__ == "__main__":
    manifest = []
    for ex_id, mix in EXPERIMENTS.items():
        for it in (1,2,3):
            for tech, reorder in [('stall', False), ('reorder', True), ('bubblefree', False)]:
                prog, sentinel = build_program(mix, it, reorder=reorder)
                fname = f"ex{ex_id}_it{it}_{tech}.mem"
                with open(fname, "w") as f:
                    for instr in prog:
                        f.write("%08x\n" % (instr & 0xFFFFFFFF))
                manifest.append({"ex": ex_id, "mix": mix, "iter": it, "tech": tech,
                                  "file": fname, "sentinel": sentinel,
                                  "design": "bubblefree" if tech=="bubblefree" else "baseline"})
    with open("manifest.json","w") as f:
        json.dump(manifest, f, indent=2)
    print(f"Generated {len(manifest)} programs (unrolled, no branches)")
