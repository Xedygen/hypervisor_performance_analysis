#!/usr/bin/env python3
"""Summarise a pi_night.sh results directory into CSV files and a Markdown report.

Usage: analyze.py <results-dir>   (the directory copied back from the Pi)
Writes <results-dir>/summary.md and <results-dir>/<config>/runs.csv.
"""
import csv
import re
import sys
from pathlib import Path

CONFIGS = [
    ("plain", "Spatial isolation only (no colouring)"),
    ("col", "Guest coloured 8/32, root unrestricted"),
    ("colhog", "Guest coloured 8/32, root kept out of guest colours"),
]
W_RE = re.compile(
    r"^(?P<t>\d+\.\d+) W \d+ lat (?P<lmin>\d+) (?P<lavg>\d+) (?P<lmax>\d+) (?P<lover>\d+) "
    r"exe (?P<emin>\d+) (?P<eavg>\d+) (?P<emax>\d+) resp (?P<rmax>\d+) (?P<rover>\d+) "
    r"pmu (?P<l2>\d+) (?P<l3>\d+) (?P<bus>\d+) (?P<inst>\d+) (?P<cyc>\d+)")
PERIODS_PER_WINDOW = 1000


def load_windows(path):
    windows = []
    for line in path.read_text(errors="replace").replace("\x00", "").splitlines():
        m = W_RE.match(line)
        if m:
            windows.append({k: float(v) for k, v in m.groupdict().items()})
    return windows


def load_runs(path):
    runs, open_runs = [], {}
    for line in path.read_text(errors="replace").replace("\x00", "").splitlines():
        parts = line.split()
        if len(parts) < 5 or parts[1] not in ("START", "END"):
            continue
        key = tuple(parts[2:5])
        if parts[1] == "START":
            open_runs[key] = float(parts[0])
        elif key in open_runs:
            rc = parts[5] if len(parts) > 5 else ""
            runs.append({"scenario": parts[2], "load": parts[3], "rep": parts[4],
                         "start": open_runs.pop(key), "end": float(parts[0]), "rc": rc})
    return runs


def aggregate(windows):
    """Combine the 1-second windows of one run."""
    if not windows:
        return None
    n = len(windows) * PERIODS_PER_WINDOW
    agg = {
        "windows": len(windows),
        "lat_min_ns": min(w["lmin"] for w in windows),
        "lat_avg_ns": sum(w["lavg"] for w in windows) / len(windows),
        "lat_max_ns": max(w["lmax"] for w in windows),
        "lat_over": sum(w["lover"] for w in windows),
        "exe_avg_ns": sum(w["eavg"] for w in windows) / len(windows),
        "exe_max_ns": max(w["emax"] for w in windows),
        "resp_max_ns": max(w["rmax"] for w in windows),
        "resp_over": sum(w["rover"] for w in windows),
        "l2_refill_per_period": sum(w["l2"] for w in windows) / n,
        "l3_refill_per_period": sum(w["l3"] for w in windows) / n,
        "bus_access_per_period": sum(w["bus"] for w in windows) / n,
    }
    agg["lat_over_pct"] = 100.0 * agg["lat_over"] / n
    agg["resp_over_pct"] = 100.0 * agg["resp_over"] / n
    return agg


def runs_with_stats(cfg_dir):
    windows = load_windows(cfg_dir / "console.log")
    out = []
    for run in load_runs(cfg_dir / "markers.log"):
        # a window line is printed at the end of its 1 s window: skip the one
        # that started before the run and the one straddling its end
        sel = [w for w in windows if run["start"] + 1.2 < w["t"] <= run["end"] + 0.2]
        stats = aggregate(sel)
        if stats:
            out.append({**run, **stats})
    return out


def write_csv(rows, path):
    if not rows:
        return
    with path.open("w", newline="") as f:
        w = csv.DictWriter(f, fieldnames=list(rows[0].keys()))
        w.writeheader()
        w.writerows(rows)


def combine(rows):
    """Merge several runs (repetitions) into one line."""
    total = sum(r["windows"] for r in rows) * PERIODS_PER_WINDOW
    wsum = lambda k: sum(r[k] * r["windows"] for r in rows) / sum(r["windows"] for r in rows)
    return {
        "runs": len(rows),
        "lat_min_ns": min(r["lat_min_ns"] for r in rows),
        "lat_avg_ns": wsum("lat_avg_ns"),
        "lat_max_ns": max(r["lat_max_ns"] for r in rows),
        "lat_over_pct": 100.0 * sum(r["lat_over"] for r in rows) / total,
        "exe_avg_ns": wsum("exe_avg_ns"),
        "exe_max_ns": max(r["exe_max_ns"] for r in rows),
        "resp_max_ns": max(r["resp_max_ns"] for r in rows),
        "resp_over_pct": 100.0 * sum(r["resp_over"] for r in rows) / total,
        "l3_refill_per_period": wsum("l3_refill_per_period"),
        "bus_access_per_period": wsum("bus_access_per_period"),
    }


def us(ns):
    return f"{ns / 1000:.2f}"


def unixbench_scores(path):
    """Return {copies: (index, {test: index})} from a UnixBench output."""
    scores, copies, tests = {}, None, {}
    if not path.exists():
        return scores
    for line in path.read_text(errors="replace").splitlines():
        m = re.search(r"running (\d+) parallel cop", line)
        if m:
            copies, tests = int(m.group(1)), {}
        m = re.match(r"(.+?)\s{2,}[\d.]+\s+[\d.]+\s+([\d.]+)$", line.strip())
        if m and copies is not None and "BASELINE" not in line:
            tests[m.group(1).strip()] = float(m.group(2))
        m = re.search(r"System Benchmarks Index Score\s+([\d.]+)", line)
        if m and copies is not None:
            scores[copies] = (float(m.group(1)), tests)
    return scores


def main(res):
    md = ["# Pi 5 results: thesis scenarios S1-S4", ""]
    per_cfg = {}
    for cfg, _ in CONFIGS:
        d = res / cfg
        if (d / "markers.log").exists() and (d / "console.log").exists():
            rows = runs_with_stats(d)
            write_csv(rows, d / "runs.csv")
            per_cfg[cfg] = rows

    # S1
    md += ["## S1: baseline, root cell idle", "",
           "| Config | Runs | Lat min/avg/max (us) | Lat >100 us | Task avg/max (us) | Resp max (us) | Resp >100 us |",
           "|---|---|---|---|---|---|---|"]
    for cfg, label in CONFIGS:
        rows = [r for r in per_cfg.get(cfg, []) if r["scenario"] == "s1"]
        if rows:
            c = combine(rows)
            md.append(f"| {label} | {c['runs']} | {us(c['lat_min_ns'])} / {us(c['lat_avg_ns'])} / "
                      f"{us(c['lat_max_ns'])} | {c['lat_over_pct']:.3f}% | {us(c['exe_avg_ns'])} / "
                      f"{us(c['exe_max_ns'])} | {us(c['resp_max_ns'])} | {c['resp_over_pct']:.3f}% |")

    # S3
    md += ["", "## S3: targeted memory interference (3 root cores), per load", "",
           "Per period: task = pointer-chase control task; L3 refills and bus accesses are PMU counts on the guest CPU.", "",
           "| Load | Config | Task avg/max (us) | Resp max (us) | Resp >100 us | Lat max (us) | L3 refills/period | Bus accesses/period |",
           "|---|---|---|---|---|---|---|---|"]
    for load in ["idle", "cache", "stream", "memcpy", "vm", "pwalk"]:
        for cfg, label in CONFIGS:
            rows = [r for r in per_cfg.get(cfg, []) if r["scenario"] == "s3" and r["load"] == load]
            if rows:
                c = combine(rows)
                md.append(f"| {load} | {label} | {us(c['exe_avg_ns'])} / {us(c['exe_max_ns'])} | "
                          f"{us(c['resp_max_ns'])} | {c['resp_over_pct']:.2f}% | {us(c['lat_max_ns'])} | "
                          f"{c['l3_refill_per_period']:.1f} | {c['bus_access_per_period']:.0f} |")

    # S2
    md += ["", "## S2: 100 stress-ng stressors x 30 s on the root cell", ""]
    for cfg, label in CONFIGS:
        rows = [r for r in per_cfg.get(cfg, []) if r["scenario"] == "s2"]
        if not rows:
            continue
        c = combine(rows)
        ran = [r for r in rows if r["rc"] in ("0", "")]
        md += [f"### {label}", "",
               f"{len(rows)} stressor windows ({len(ran)} exited 0). Over all periods: "
               f"latency >100 us {c['lat_over_pct']:.3f}%, response >100 us {c['resp_over_pct']:.3f}%, "
               f"worst latency {us(c['lat_max_ns'])} us, worst task time {us(c['exe_max_ns'])} us, "
               f"worst response {us(c['resp_max_ns'])} us.", "",
               "Top 20 stressors by response-time deadline misses:", "",
               "| Stressor | Resp >100 us | Task avg/max (us) | Lat max (us) | L3 refills/period |",
               "|---|---|---|---|---|"]
        for r in sorted(rows, key=lambda r: (r["resp_over_pct"], r["exe_max_ns"]), reverse=True)[:20]:
            md.append(f"| {r['load']} | {r['resp_over_pct']:.2f}% | {us(r['exe_avg_ns'])} / "
                      f"{us(r['exe_max_ns'])} | {us(r['lat_max_ns'])} | {r['l3_refill_per_period']:.1f} |")
        md.append("")

    # S4
    bare = unixbench_scores(res / "bare" / "unixbench-bare.txt")
    jh = unixbench_scores(res / "plain" / "unixbench-jailhouse.txt")
    md += ["## S4: UnixBench on the root cell", "",
           "| Copies | Plain Linux (3 CPUs, no hypervisor) | Jailhouse root cell | Overhead |",
           "|---|---|---|---|"]
    for copies in sorted(set(bare) | set(jh)):
        b = bare.get(copies, (None, {}))[0]
        j = jh.get(copies, (None, {}))[0]
        ov = f"{100 * (b - j) / b:.1f}%" if b and j else "n/a"
        md.append(f"| {copies} | {b if b else 'n/a'} | {j if j else 'n/a'} | {ov} |")
    if bare and jh:
        md += ["", "Per test (index, 3 copies):", "", "| Test | Plain | Jailhouse | Overhead |", "|---|---|---|---|"]
        for test, b in bare.get(3, (None, {}))[1].items():
            j = jh.get(3, (None, {}))[1].get(test)
            if j:
                md.append(f"| {test} | {b} | {j} | {100 * (b - j) / b:.1f}% |")

    # follow-up experiments (pi_extra.sh): one row per config and load
    extras = sorted(d for d in res.glob("extra-*") if (d / "markers.log").exists())
    if extras:
        md += ["", "## Follow-up experiments", "",
               "e1 = colour-share sweep, e2 = working-set sweep, e3 = 2+2 core split, "
               "e4 = MemGuard on the root cores (budget = L2 refills per core per 1 ms).", "",
               "| Config | Load | Runs | Task avg/max (us) | Resp >100 us | Lat max (us) | "
               "L3 refills/period | Bus accesses/period |",
               "|---|---|---|---|---|---|---|---|"]
        for d in extras:
            rows = runs_with_stats(d)
            write_csv(rows, d / "runs.csv")
            for load in dict.fromkeys(r["load"] for r in rows):
                c = combine([r for r in rows if r["load"] == load])
                md.append(f"| {d.name[len('extra-'):]} | {load} | {c['runs']} | {us(c['exe_avg_ns'])} / "
                          f"{us(c['exe_max_ns'])} | {c['resp_over_pct']:.2f}% | {us(c['lat_max_ns'])} | "
                          f"{c['l3_refill_per_period']:.1f} | {c['bus_access_per_period']:.0f} |")

    # thermal
    th = res / "thermal.csv"
    if th.exists():
        temps, flags = [], set()
        for row in csv.DictReader(th.open()):
            try:
                temps.append(int(row["temp_mC"]))
                flags.add(row["throttled"])
            except (KeyError, ValueError):
                pass
        if temps:
            md += ["", "## Board temperature during the runs", "",
                   f"Max {max(temps) / 1000:.1f} C, mean {sum(temps) / len(temps) / 1000:.1f} C over "
                   f"{len(temps)} samples; firmware throttle flags seen: {', '.join(sorted(flags))}."]
    (res / "summary.md").write_text("\n".join(md) + "\n")
    print("\n".join(md))


if __name__ == "__main__":
    main(Path(sys.argv[1]))
