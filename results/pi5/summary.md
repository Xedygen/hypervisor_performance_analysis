# Pi 5 results: thesis scenarios S1-S4

## S1: baseline, root cell idle

| Config | Runs | Lat min/avg/max (us) | Lat >100 us | Task avg/max (us) | Resp max (us) | Resp >100 us |
|---|---|---|---|---|---|---|
| Spatial isolation only (no colouring) | 3 | 0.30 / 0.45 / 1.87 | 0.000% | 19.84 / 171.56 | 172.09 | 0.093% |
| Guest coloured 8/32, root unrestricted | 1 | 0.37 / 0.46 / 1.76 | 0.000% | 28.55 / 148.94 | 149.43 | 0.935% |
| Guest coloured 8/32, root kept out of guest colours | 1 | 0.30 / 0.46 / 1.61 | 0.000% | 28.23 / 150.09 | 150.63 | 0.865% |

## S3: targeted memory interference (3 root cores), per load

Per period: task = pointer-chase control task; L3 refills and bus accesses are PMU counts on the guest CPU.

| Load | Config | Task avg/max (us) | Resp max (us) | Resp >100 us | Lat max (us) | L3 refills/period | Bus accesses/period |
|---|---|---|---|---|---|---|---|
| idle | Spatial isolation only (no colouring) | 20.02 / 144.22 | 145.33 | 0.10% | 1.61 | 10.0 | 6375 |
| idle | Guest coloured 8/32, root unrestricted | 28.28 / 149.13 | 150.19 | 0.90% | 1.69 | 55.4 | 8263 |
| idle | Guest coloured 8/32, root kept out of guest colours | 28.20 / 147.46 | 147.96 | 0.88% | 1.59 | 56.0 | 8261 |
| cache | Spatial isolation only (no colouring) | 392.26 / 583.17 | 588.81 | 99.38% | 13.28 | 891.4 | 7625 |
| cache | Guest coloured 8/32, root unrestricted | 437.73 / 584.39 | 588.72 | 99.80% | 19.26 | 1027.3 | 8312 |
| cache | Guest coloured 8/32, root kept out of guest colours | 206.29 / 547.57 | 554.20 | 88.37% | 16.26 | 395.2 | 8285 |
| stream | Spatial isolation only (no colouring) | 387.98 / 473.65 | 479.98 | 100.00% | 20.41 | 1030.2 | 8469 |
| stream | Guest coloured 8/32, root unrestricted | 387.27 / 491.57 | 497.94 | 99.91% | 18.33 | 1029.5 | 8459 |
| stream | Guest coloured 8/32, root kept out of guest colours | 276.76 / 427.37 | 430.61 | 99.92% | 9.35 | 689.4 | 8281 |
| memcpy | Spatial isolation only (no colouring) | 14.08 / 111.98 | 112.69 | 0.00% | 4.11 | 9.2 | 6360 |
| memcpy | Guest coloured 8/32, root unrestricted | 21.18 / 136.56 | 136.87 | 0.39% | 1.39 | 58.9 | 8253 |
| memcpy | Guest coloured 8/32, root kept out of guest colours | 20.97 / 142.33 | 142.65 | 0.29% | 1.00 | 57.3 | 8249 |
| vm | Spatial isolation only (no colouring) | 508.27 / 814.00 | 818.26 | 96.40% | 17.65 | 1005.5 | 8226 |
| vm | Guest coloured 8/32, root unrestricted | 507.02 / 783.20 | 789.81 | 99.81% | 14.15 | 1030.2 | 8356 |
| vm | Guest coloured 8/32, root kept out of guest colours | 368.25 / 662.67 | 668.07 | 92.70% | 13.87 | 706.8 | 8231 |
| pwalk | Spatial isolation only (no colouring) | 15.33 / 150.83 | 151.31 | 0.03% | 8.17 | 22.8 | 6371 |
| pwalk | Guest coloured 8/32, root unrestricted | 24.13 / 130.20 | 130.70 | 0.69% | 1.78 | 93.1 | 8257 |
| pwalk | Guest coloured 8/32, root kept out of guest colours | 24.35 / 131.06 | 131.48 | 0.73% | 0.98 | 96.4 | 8256 |

## S2: 100 stress-ng stressors x 30 s on the root cell

### Spatial isolation only (no colouring)

100 stressor windows (100 exited 0). Over all periods: latency >100 us 0.000%, response >100 us 29.782%, worst latency 32.80 us, worst task time 932.85 us, worst response 940.20 us.

Top 20 stressors by response-time deadline misses:

| Stressor | Resp >100 us | Task avg/max (us) | Lat max (us) | L3 refills/period |
|---|---|---|---|---|
| matrix-3d | 100.00% | 496.61 / 814.57 | 32.80 | 919.8 |
| mergesort | 100.00% | 258.89 / 602.98 | 13.24 | 1032.8 |
| vm-rw | 100.00% | 499.55 / 558.74 | 10.07 | 1023.9 |
| randlist | 100.00% | 229.20 / 373.37 | 7.76 | 1036.2 |
| prefetch | 100.00% | 127.09 / 346.28 | 14.96 | 1042.1 |
| stack | 100.00% | 196.63 / 267.48 | 8.61 | 1030.9 |
| far-branch | 100.00% | 111.77 / 137.43 | 1.59 | 1044.2 |
| radixsort | 99.99% | 141.42 / 632.74 | 10.46 | 1032.7 |
| memfd | 99.99% | 372.56 / 548.54 | 9.19 | 1028.2 |
| ptr-chase | 99.98% | 126.66 / 307.39 | 4.70 | 1011.6 |
| llc-affinity | 99.97% | 326.90 / 603.05 | 17.72 | 1040.0 |
| cachehammer | 99.96% | 141.35 / 223.85 | 6.13 | 1031.1 |
| bad-altstack | 99.96% | 119.37 / 246.57 | 14.48 | 963.1 |
| tsearch | 99.84% | 113.90 / 193.00 | 3.28 | 1029.9 |
| tree | 99.74% | 131.02 / 663.89 | 8.44 | 1031.8 |
| stream | 99.66% | 372.83 / 447.02 | 7.41 | 1022.0 |
| lockbus | 99.58% | 106.10 / 246.91 | 3.67 | 902.4 |
| judy | 99.42% | 119.16 / 448.87 | 5.52 | 1011.6 |
| malloc | 99.31% | 142.41 / 388.06 | 4.59 | 1022.5 |
| regex | 99.20% | 109.82 / 225.85 | 5.04 | 991.5 |

### Guest coloured 8/32, root kept out of guest colours

100 stressor windows (97 exited 0). Over all periods: latency >100 us 0.000%, response >100 us 26.733%, worst latency 30.43 us, worst task time 868.98 us, worst response 875.74 us.

Top 20 stressors by response-time deadline misses:

| Stressor | Resp >100 us | Task avg/max (us) | Lat max (us) | L3 refills/period |
|---|---|---|---|---|
| matrix-3d | 100.00% | 480.62 / 841.65 | 30.43 | 880.6 |
| tree | 100.00% | 130.72 / 660.61 | 8.37 | 1025.4 |
| radixsort | 100.00% | 124.48 / 595.35 | 7.67 | 1029.1 |
| mergesort | 100.00% | 254.60 / 584.46 | 11.48 | 1018.4 |
| vm-rw | 100.00% | 469.53 / 544.41 | 9.93 | 923.8 |
| memfd | 100.00% | 375.70 / 524.37 | 7.89 | 1025.2 |
| prefetch | 100.00% | 127.82 / 332.52 | 14.35 | 1042.4 |
| stack | 100.00% | 200.84 / 323.61 | 4.57 | 1029.0 |
| ptr-chase | 100.00% | 125.93 / 242.81 | 4.96 | 1012.0 |
| tsearch | 100.00% | 117.38 / 235.04 | 3.04 | 1024.5 |
| bad-altstack | 100.00% | 129.80 / 213.39 | 4.00 | 1024.8 |
| opcode | 99.99% | 135.03 / 386.63 | 4.80 | 1025.5 |
| remap | 99.94% | 115.36 / 442.07 | 7.70 | 995.1 |
| stream | 99.92% | 372.68 / 435.56 | 7.42 | 1000.1 |
| malloc | 99.87% | 120.43 / 383.17 | 4.61 | 983.8 |
| llc-affinity | 99.61% | 251.78 / 521.04 | 17.89 | 767.4 |
| cachehammer | 99.10% | 124.40 / 183.80 | 6.37 | 883.7 |
| cache | 98.58% | 269.24 / 541.07 | 13.54 | 594.4 |
| randlist | 97.51% | 210.72 / 377.13 | 7.89 | 972.5 |
| memrate | 95.33% | 238.92 / 794.91 | 11.26 | 995.8 |

## S4: UnixBench on the root cell

| Copies | Plain Linux (3 CPUs, no hypervisor) | Jailhouse root cell | Overhead |
|---|---|---|---|
| 1 | 1522.0 | 1480.4 | 2.7% |
| 3 | 3357.8 | 3309.6 | 1.4% |

Per test (index, 3 copies):

| Test | Plain | Jailhouse | Overhead |
|---|---|---|---|
| Dhrystone 2 using register variables | 9036.8 | 9044.3 | -0.1% |
| Double-Precision Whetstone | 3813.5 | 3817.0 | -0.1% |
| Execl Throughput | 2696.1 | 2525.9 | 6.3% |
| File Copy 1024 bufsize 2000 maxblocks | 4048.0 | 3992.3 | 1.4% |
| File Copy 256 bufsize 500 maxblocks | 5145.6 | 5115.2 | 0.6% |
| File Copy 4096 bufsize 8000 maxblocks | 3125.2 | 3210.3 | -2.7% |
| Pipe Throughput | 3508.6 | 3507.4 | 0.0% |
| Pipe-based Context Switching | 1434.6 | 1262.3 | 12.0% |
| Process Creation | 1396.3 | 1559.9 | -11.7% |
| Shell Scripts (1 concurrent) | 4984.9 | 4729.7 | 5.1% |
| Shell Scripts (8 concurrent) | 4636.0 | 4422.5 | 4.6% |
| System Call Overhead | 2091.3 | 2091.6 | -0.0% |

## Board temperature during the runs

Max 57.9 C, mean 42.4 C over 20417 samples; firmware throttle flags seen: 0x0.
