# Results directory

Mirrors the thesis's four scenarios (the project guide §3 Phase 4) for both boards,
so Pi 4 vs. Pi 5 numbers land in directly comparable folders:

- scenario1_baseline_idle/          — baseline/idle latency
- scenario2_spatial_only/           — spatial-isolation-only under stress-ng load
- scenario3_cache_coloring/         — spatial isolation + cache coloring active
- scenario4_throughput_unixbench/   — UnixBench system-throughput comparison

Keep raw cyclictest histograms and stress-ng logs in raw_logs/, not just summary
statistics — per the project guide §4.4, the thesis's per-tool WCL table came
from exactly this kind of raw log retention.

Pi 5 note (24 Sep 2026): the Pi 5 guest is Zephyr RTOS, not PREEMPT_RT Linux,
so cyclictest can't run inside the guest. Record which in-guest latency
measurement replaces it next to each pi5/ run, and keep the 100 µs deadline and
stress-ng set identical to the Pi 4 runs. Every pi5/ run uses the Active Cooler
at full speed (set in config.txt).
