#!/usr/bin/env python3
"""Draw the result figures for one campaign (after analyze.py has written runs.csv).

Usage: plots.py <results-dir>
       plots.py --compare <default-campaign> <fixed-campaign> <output-dir>
Writes <results-dir>/figures/*.png (viewing) and *.pdf (print).
Palette: reference data-viz palette, light mode, first three categorical slots
(validated all-pairs for colour-vision deficiency) - one per configuration.
"""
import csv
import sys
from pathlib import Path

import matplotlib
matplotlib.use("Agg")
import matplotlib.pyplot as plt  # noqa: E402

sys.path.insert(0, str(Path(__file__).parent))
import analyze  # noqa: E402

SURFACE, INK, INK2, GRID = "#fcfcfb", "#0b0b0b", "#52514e", "#e4e3df"
CONFIGS = [  # (dir, legend label, colour)
    ("plain", "Spatial isolation only", "#2a78d6"),
    ("col", "Guest coloured only (8/32)", "#eb6834"),
    ("colhog", "Guest + root partitioned", "#1baf7a"),
]
LOADS = ["idle", "cache", "stream", "memcpy", "vm", "pwalk"]
# loads get their own hues (validated light-mode set, below 3:1 contrast, so
# lines/bars carry direct labels); idle is neutral ink
LOAD_COLOURS = {"idle": INK2, "cache": "#4a3aa7", "stream": "#eda100", "vm": "#e87ba4"}
DEADLINE_US = 100

plt.rcParams.update({
    "figure.facecolor": SURFACE, "axes.facecolor": SURFACE, "savefig.facecolor": SURFACE,
    "axes.edgecolor": GRID, "axes.labelcolor": INK2, "xtick.color": INK2, "ytick.color": INK2,
    "text.color": INK, "axes.grid": True, "grid.color": GRID, "grid.linewidth": 0.6,
    "axes.axisbelow": True, "axes.spines.top": False, "axes.spines.right": False,
    "font.size": 9, "axes.titlesize": 10, "axes.titleweight": "bold", "legend.frameon": False,
})


def read_runs(d):
    p = d / "runs.csv"
    if not p.exists():
        return []
    rows = []
    for r in csv.DictReader(p.open()):
        for k, v in r.items():
            try:
                r[k] = float(v)
            except (TypeError, ValueError):
                pass
        rows.append(r)
    return rows


def combined(rows, **match):
    sel = [r for r in rows if all(r.get(k) == v for k, v in match.items())]
    return analyze.combine(sel) if sel else None


def save(fig, out, name):
    out.mkdir(exist_ok=True)
    fig.savefig(out / f"{name}.png", dpi=180, bbox_inches="tight")
    fig.savefig(out / f"{name}.pdf", bbox_inches="tight")
    plt.close(fig)
    print("wrote", out / f"{name}.png")


def grouped_bars(ax, groups, series, value_of, width=0.26):
    """series: [(label, colour, rows)]; bars with a 2 px surface gap."""
    n = len(series)
    for i, (label, colour, rows) in enumerate(series):
        xs, ys = [], []
        for g, grp in enumerate(groups):
            c = value_of(rows, grp)
            if c is not None:
                xs.append(g + (i - (n - 1) / 2) * width)
                ys.append(c)
        ax.bar(xs, ys, width=width, color=colour, label=label,
               edgecolor=SURFACE, linewidth=1.0)
    ax.set_xticks(range(len(groups)), groups)


def fig_s3(res, runs, out):
    series = [(lab, col, runs[d]) for d, lab, col in CONFIGS if runs.get(d)]
    fig, axes = plt.subplots(1, 3, figsize=(13, 3.8))
    specs = [
        ("Control task time (avg, us)", lambda r, g: (c := combined(r, scenario="s3", load=g)) and c["exe_avg_ns"] / 1000),
        ("Periods missing the 100 us deadline (%)", lambda r, g: (c := combined(r, scenario="s3", load=g)) and c["resp_over_pct"]),
        ("L3 refills per period (guest CPU)", lambda r, g: (c := combined(r, scenario="s3", load=g)) and c["l3_refill_per_period"]),
    ]
    for ax, (title, fn) in zip(axes, specs):
        grouped_bars(ax, LOADS, series, fn)
        ax.set_title(title, loc="left")
        ax.set_xlabel("Root-cell load (3 cores)")
        ax.tick_params(axis="x", labelsize=8)
    deadline(axes[0])
    axes[1].set_ylim(0, 105)
    handles, labels = axes[0].get_legend_handles_labels()
    fig.legend(handles, labels, loc="lower center", ncol=3, fontsize=9,
               bbox_to_anchor=(0.5, -0.06))
    fig.suptitle("S3: targeted memory interference on the guest cell", x=0.01, y=1.03,
                 ha="left", fontweight="bold")
    save(fig, out, "s3_interference")


def fig_s2(res, runs, out):
    plain = {r["load"]: r for r in runs.get("plain", []) if r["scenario"] == "s2"}
    hog = {r["load"]: r for r in runs.get("colhog", []) if r["scenario"] == "s2"}
    if not plain or not hog:
        return
    # top 20 stressors by misses in the uncoloured config (like thesis Fig. 4.7)
    top = sorted(plain, key=lambda s: plain[s]["resp_over_pct"], reverse=True)[:20][::-1]
    fig, ax = plt.subplots(figsize=(6.4, 6))
    y = range(len(top))
    ax.barh([i + 0.2 for i in y], [plain[s]["resp_over_pct"] for s in top], height=0.38,
            color=CONFIGS[0][2], label=CONFIGS[0][1], edgecolor=SURFACE, linewidth=1)
    ax.barh([i - 0.2 for i in y], [hog[s]["resp_over_pct"] if s in hog else 0 for s in top],
            height=0.38, color=CONFIGS[2][2], label=CONFIGS[2][1], edgecolor=SURFACE, linewidth=1)
    ax.set_yticks(list(y), top)
    ax.set_xlim(0, 105)
    ax.grid(axis="y", visible=False)
    ax.set_xlabel("Periods missing the 100 us deadline (%)")
    ax.set_title("S2: 20 stressors with the most deadline misses", loc="left")
    ax.legend(loc="upper center", bbox_to_anchor=(0.4, -0.08), ncol=2, fontsize=8)
    save(fig, out, "s2_top_stressors")

    # thesis Fig. 4.9/4.10 analogue: miss rate against the mechanism, per stressor
    fig, ax = plt.subplots(figsize=(6.4, 4))
    for d, lab, col in (CONFIGS[0], CONFIGS[2]):
        rows = [r for r in runs.get(d, []) if r["scenario"] == "s2"]
        ax.scatter([r["l3_refill_per_period"] for r in rows], [r["resp_over_pct"] for r in rows],
                   s=22, color=col, label=lab, edgecolor=SURFACE, linewidth=0.8, alpha=0.9)
    ax.set_xlabel("Guest L3 refills per period (one dot per stressor)")
    ax.set_ylabel("Periods missing the deadline (%)")
    ax.set_title("S2: deadline misses follow L3 misses", loc="left")
    ax.legend(loc="upper center", bbox_to_anchor=(0.5, -0.16), ncol=2, fontsize=8)
    save(fig, out, "s2_misses_vs_l3")


def end_label(ax, x, y, text, colour):
    ax.annotate(text, (x, y), xytext=(6, 0), textcoords="offset points", va="center",
                color=INK2, fontsize=8)


def deadline(ax, left=False):
    ax.axhline(DEADLINE_US, color=INK2, linewidth=1, linestyle="--")
    ax.annotate("100 us deadline", (0 if left else 1, DEADLINE_US), xycoords=("axes fraction", "data"),
                xytext=(2 if left else -2, 4), textcoords="offset points",
                ha="left" if left else "right", color=INK2, fontsize=8)


def main_s3(res, cfg):
    return [r for r in read_runs(res / cfg) if r["scenario"] == "s3"]


def fig_extras(res, out):
    ex = {d.name[len("extra-"):]: read_runs(d) for d in sorted(res.glob("extra-*"))}
    ex = {k: v for k, v in ex.items() if v}
    if not ex:
        return
    loads = ["idle", "cache", "stream"]

    # E2 working set: one panel per configuration, colour = load
    fig, axes = plt.subplots(1, 2, figsize=(10, 3.6), sharey=True)
    for ax, (suffix, cfg, title) in zip(axes, (("plain", "plain", CONFIGS[0][1]),
                                               ("colhog", "colhog", CONFIGS[2][1] + " (8/32)"))):
        for load in loads:
            pts = []
            for ws in (256, 512, 768, 1024):
                rows = main_s3(res, cfg) if ws == 768 else ex.get(f"e2-ws{ws}-{suffix}", [])
                if (c := combined(rows, load=load)):
                    pts.append((ws, c["exe_avg_ns"] / 1000))
            if pts:
                ax.plot(*zip(*pts), "-o", color=LOAD_COLOURS[load], linewidth=2, markersize=5)
                end_label(ax, *pts[-1], f"root: {load}", LOAD_COLOURS[load])
        ax.axvspan(200, 512, color=GRID, alpha=0.35, linewidth=0)
        ax.annotate("fits the private L2", (220, 470), color=INK2, fontsize=8)
        deadline(ax)
        ax.set_xticks([256, 512, 768, 1024])
        ax.set_xlim(200, 1250)
        ax.set_xlabel("Guest working set (KB)")
        ax.set_title(title, loc="left")
    axes[0].set_ylabel("Control task time (avg, us)")
    fig.suptitle("E2: working-set size (768 KB = main campaign)", x=0.01, y=1.02, ha="left",
                 fontweight="bold")
    save(fig, out, "e2_working_set")

    # E1 colour share, colour = load
    fig, ax = plt.subplots(figsize=(6, 3.6))
    shares = [8, 12, 16]
    for load in loads:
        pts = [(n, c["exe_avg_ns"] / 1000) for n in shares
               if (c := combined(ex.get(f"e1-col{n}", []), load=load))]
        if pts:
            ax.plot(*zip(*pts), "-o", color=LOAD_COLOURS[load], linewidth=2, markersize=5)
            end_label(ax, *pts[-1], f"root: {load}", LOAD_COLOURS[load])
    deadline(ax)
    ax.set_xlim(7, 18.5)
    ax.set_xticks(shares, [f"{n}/32\n({n * 64} KB)" for n in shares])
    ax.set_xlabel("Guest share of the L3 (colours), root partitioned, 768 KB working set")
    ax.set_ylabel("Control task time (avg, us)")
    ax.set_title("E1: giving the guest more of the L3", loc="left")
    save(fig, out, "e1_colour_share")

    # E3 core split, colour = load
    fig, ax = plt.subplots(figsize=(7, 3.8))
    groups = [("3+1\nspatial only", main_s3(res, "plain")),
              ("2+2\nspatial only", ex.get("e3-2c-plain", [])),
              ("3+1\npartitioned", main_s3(res, "colhog")),
              ("2+2\npartitioned", ex.get("e3-2c-colhog", []))]
    for i, load in enumerate(["cache", "stream", "vm"]):
        xs, ys = [], []
        for g, (_, rows) in enumerate(groups):
            if (c := combined(rows, load=load)):
                xs.append(g + (i - 1) * 0.26)
                ys.append(c["exe_avg_ns"] / 1000)
        ax.bar(xs, ys, width=0.26, color=LOAD_COLOURS[load], label=f"root: {load}",
               edgecolor=SURFACE, linewidth=1)
    deadline(ax)
    ax.set_xticks(range(len(groups)), [g for g, _ in groups])
    ax.set_xlabel("Root cores + guest cores")
    ax.set_ylabel("Control task time (avg, us)")
    ax.set_title("E3: fewer noisy cores on the root side", loc="left")
    ax.legend(fontsize=8, loc="upper right", ncol=3)
    ax.set_ylim(0, 600)
    save(fig, out, "e3_core_split")


def fig_s4(res, out):
    bare = analyze.unixbench_scores(res / "bare" / "unixbench-bare.txt")
    jh = analyze.unixbench_scores(res / "plain" / "unixbench-jailhouse.txt")
    if 3 not in bare or 3 not in jh:
        return
    tests = [t for t in bare[3][1] if t in jh[3][1]]
    ov = [100 * (bare[3][1][t] - jh[3][1][t]) / bare[3][1][t] for t in tests]
    order = sorted(range(len(tests)), key=lambda i: ov[i])
    fig, ax = plt.subplots(figsize=(6.4, 4.2))
    ax.barh(range(len(order)), [ov[i] for i in order], color=CONFIGS[0][2], height=0.6,
            edgecolor=SURFACE, linewidth=1)
    ax.set_yticks(range(len(order)), [tests[i] for i in order])
    ax.axvline(0, color=INK2, linewidth=0.8)
    ax.grid(axis="y", visible=False)
    lim = max(abs(v) for v in ov) + 4
    ax.set_xlim(-lim, lim)
    for yi, i in enumerate(order):
        ax.annotate(f"{ov[i]:+.1f}%", (ov[i], yi), xytext=(3 if ov[i] >= 0 else -3, 0),
                    textcoords="offset points", va="center", ha="left" if ov[i] >= 0 else "right",
                    color=INK2, fontsize=7.5)
    b, j = bare[3][0], jh[3][0]
    ax.set_xlabel("Throughput loss under Jailhouse (%), 3 copies")
    ax.set_title(f"S4: UnixBench overhead (index {b:.0f} -> {j:.0f}, {100 * (b - j) / b:.1f}%)", loc="left")
    save(fig, out, "s4_unixbench")


def fig_compare(res_a, res_b, out):
    """Default (ondemand) vs fixed-frequency campaign, S3 per load."""
    loads = ["idle", "cache", "stream", "vm"]
    fig, axes = plt.subplots(1, 2, figsize=(10, 3.6), sharey=True)
    for ax, (cfg, title) in zip(axes, (("plain", CONFIGS[0][1]), ("colhog", CONFIGS[2][1]))):
        for i, (res, label, colour) in enumerate(((res_a, "default frequency (ondemand)", INK2),
                                                  (res_b, "fixed 2.4 GHz", CONFIGS[0][2]))):
            rows = main_s3(res, cfg)
            xs, ys = [], []
            for g, load in enumerate(loads):
                if (c := combined(rows, load=load)):
                    xs.append(g + (i - 0.5) * 0.36)
                    ys.append(c["exe_avg_ns"] / 1000)
            ax.bar(xs, ys, width=0.36, color=colour, label=label, edgecolor=SURFACE, linewidth=1)
            for x, y in zip(xs, ys):
                ax.annotate(f"{y:.0f}", (x, y), xytext=(0, 2), textcoords="offset points",
                            ha="center", color=INK2, fontsize=7)
        deadline(ax, left=True)
        ax.set_xticks(range(len(loads)), loads)
        ax.set_xlabel("Root-cell load (3 cores)")
        ax.set_title(title, loc="left")
    axes[0].set_ylabel("Control task time (avg, us)")
    handles, labels = axes[0].get_legend_handles_labels()
    fig.legend(handles, labels, loc="lower center", ncol=2, bbox_to_anchor=(0.5, -0.08))
    fig.suptitle("S3 at default vs fixed CPU frequency", x=0.01, y=1.02, ha="left",
                 fontweight="bold")
    save(fig, out, "compare_frequency")


def main(res):
    runs = {d: read_runs(res / d) for d, _, _ in CONFIGS}
    out = res / "figures"
    fig_s3(res, runs, out)
    fig_s2(res, runs, out)
    fig_extras(res, out)
    fig_s4(res, out)


if __name__ == "__main__":
    if len(sys.argv) == 5 and sys.argv[1] == "--compare":
        # plots.py --compare <default-campaign> <fixed-campaign> <output-dir>
        fig_compare(Path(sys.argv[2]), Path(sys.argv[3]), Path(sys.argv[4]))
    else:
        main(Path(sys.argv[1]))
