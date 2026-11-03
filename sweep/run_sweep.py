#!/usr/bin/env python3
"""Runs the Table III-style sweep: 5 hazard mixes x 3 repetitions x 3 techniques
= 45 programs, on the baseline core (stall, compiler reordering) and the
LW-driven core (bubble mitigation). Needs Icarus Verilog (iverilog, vvp).

Usage (from the repository root):  python3 sweep/run_sweep.py
"""
import json, os, shutil, subprocess, sys

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SWEEP = os.path.join(ROOT, 'sweep')
BUILD = os.path.join(SWEEP, 'build')
sys.path.insert(0, SWEEP)
import gen  # noqa: E402

shutil.rmtree(BUILD, ignore_errors=True)
os.makedirs(BUILD)
for core in ('baseline', 'lw_driven'):
    d = os.path.join(BUILD, core); os.makedirs(d)
    rtl = [os.path.join(ROOT, 'rtl', core, f) for f in sorted(os.listdir(os.path.join(ROOT, 'rtl', core)))]
    subprocess.run(['iverilog', '-o', os.path.join(d, 'sim'), *rtl, os.path.join(SWEEP, 'tb_sweep.v')], check=True)

rows, totals, mismatches = [], {'stall': 0, 'reorder': 0, 'bubblefree': 0}, 0
for ex, mix in gen.EXPERIMENTS.items():
    for it in (1, 2, 3):
        finals = set()
        row = {'ex': ex, 'iter': it}
        for tech, reorder in (('stall', False), ('reorder', True), ('bubblefree', False)):
            prog, sentinel = gen.build_program(mix, it, reorder=reorder)
            core = 'lw_driven' if tech == 'bubblefree' else 'baseline'
            d = os.path.join(BUILD, core)
            with open(os.path.join(d, 'instructions.mem'), 'w') as f:
                f.writelines('%08x\n' % (w & 0xFFFFFFFF) for w in prog)
            out = subprocess.run(['vvp', '-n', 'sim', f'+SENTINEL={sentinel}'], cwd=d,
                                 capture_output=True, text=True).stdout
            line = next(l for l in out.splitlines() if l.startswith('RESULT'))
            kv = dict(x.split('=') for x in line.split()[1:])
            row[tech] = int(kv['cycles']); totals[tech] += row[tech]
            finals.add((kv['x29'], kv['x30']))
        mismatches += len(finals) > 1
        row['improve_%'] = round(100 * (row['stall'] - row['bubblefree']) / row['stall'], 2)
        rows.append(row)

print(f"{'Ex':>3} {'Iter':>4} {'Stall':>6} {'Reorder':>8} {'Bubble':>7} {'Improve%':>9}")
for r in rows:
    print(f"{r['ex']:>3} {r['iter']:>4} {r['stall']:>6} {r['reorder']:>8} {r['bubblefree']:>7} {r['improve_%']:>9}")
print(f"TOTAL     {totals['stall']:>6} {totals['reorder']:>8} {totals['bubblefree']:>7} "
      f"{100 * (totals['stall'] - totals['bubblefree']) / totals['stall']:>9.2f}")
print(f"Configurations with mismatched final registers: {mismatches} of {len(rows)}")
