# Pi 5 results: thesis scenarios S1-S4

## S1: baseline, root cell idle

| Config | Runs | Lat min/avg/max (us) | Lat >100 us | Task avg/max (us) | Resp max (us) | Resp >100 us |
|---|---|---|---|---|---|---|
| Spatial isolation only (no colouring) | 3 | 0.28 / 0.30 / 2.13 | 0.000% | 13.91 / 156.89 | 157.80 | 0.009% |
| Guest coloured 8/32, root unrestricted | 1 | 0.30 / 0.30 / 1.07 | 0.000% | 20.69 / 144.74 | 145.09 | 0.343% |
| Guest coloured 8/32, root kept out of guest colours | 1 | 0.30 / 0.30 / 1.28 | 0.000% | 20.54 / 174.87 | 175.26 | 0.312% |

## S3: targeted memory interference (3 root cores), per load

Per period: task = pointer-chase control task; L3 refills and bus accesses are PMU counts on the guest CPU.

| Load | Config | Task avg/max (us) | Resp max (us) | Resp >100 us | Lat max (us) | L3 refills/period | Bus accesses/period |
|---|---|---|---|---|---|---|---|
| idle | Spatial isolation only (no colouring) | 13.93 / 143.39 | 143.81 | 0.01% | 1.20 | 7.5 | 6379 |
| idle | Guest coloured 8/32, root unrestricted | 20.74 / 140.13 | 140.50 | 0.38% | 1.67 | 53.6 | 8259 |
| idle | Guest coloured 8/32, root kept out of guest colours | 20.45 / 146.02 | 146.37 | 0.30% | 6.80 | 50.1 | 8249 |
| cache | Spatial isolation only (no colouring) | 379.01 / 588.05 | 594.48 | 99.29% | 16.72 | 874.5 | 7557 |
| cache | Guest coloured 8/32, root unrestricted | 439.03 / 586.72 | 591.87 | 99.88% | 22.26 | 1025.8 | 8295 |
| cache | Guest coloured 8/32, root kept out of guest colours | 232.44 / 554.92 | 558.96 | 89.36% | 10.96 | 469.0 | 8277 |
| stream | Spatial isolation only (no colouring) | 386.93 / 477.57 | 482.61 | 100.00% | 8.44 | 1025.8 | 8468 |
| stream | Guest coloured 8/32, root unrestricted | 387.72 / 503.39 | 509.37 | 99.96% | 12.39 | 1027.3 | 8456 |
| stream | Guest coloured 8/32, root kept out of guest colours | 306.99 / 415.35 | 420.43 | 100.00% | 9.46 | 790.3 | 8293 |
| memcpy | Spatial isolation only (no colouring) | 13.91 / 110.56 | 111.20 | 0.00% | 1.89 | 7.3 | 6365 |
| memcpy | Guest coloured 8/32, root unrestricted | 21.27 / 145.07 | 145.59 | 0.43% | 1.69 | 59.4 | 8251 |
| memcpy | Guest coloured 8/32, root kept out of guest colours | 20.91 / 151.91 | 152.37 | 0.29% | 0.89 | 55.2 | 8246 |
| vm | Spatial isolation only (no colouring) | 482.69 / 741.87 | 747.59 | 96.34% | 15.93 | 994.7 | 8216 |
| vm | Guest coloured 8/32, root unrestricted | 496.60 / 753.44 | 758.85 | 99.91% | 14.41 | 1026.8 | 8356 |
| vm | Guest coloured 8/32, root kept out of guest colours | 374.80 / 682.87 | 687.91 | 91.69% | 17.55 | 725.6 | 8230 |
| pwalk | Spatial isolation only (no colouring) | 15.24 / 113.13 | 113.74 | 0.02% | 2.89 | 21.8 | 6375 |
| pwalk | Guest coloured 8/32, root unrestricted | 24.32 / 157.26 | 157.78 | 0.76% | 1.61 | 94.7 | 8253 |
| pwalk | Guest coloured 8/32, root kept out of guest colours | 23.80 / 135.44 | 135.78 | 0.64% | 6.83 | 88.8 | 8247 |

## S2: 100 stress-ng stressors x 30 s on the root cell

### Spatial isolation only (no colouring)

100 stressor windows in 1 cycle(s) (97 exited 0). Over all periods: latency >100 us 0.000%, response >100 us 27.073%, worst latency 21.33 us, worst task time 949.54 us, worst response 957.41 us.

Top 20 stressors by response-time deadline misses:

| Stressor | Resp >100 us | Task avg/max (us) | Lat max (us) | L3 refills/period |
|---|---|---|---|---|
| matrix-3d | 100.00% | 483.18 / 782.15 | 21.33 | 918.0 |
| vm-rw | 100.00% | 518.29 / 568.46 | 9.59 | 1026.9 |
| stream | 100.00% | 380.52 / 453.15 | 8.13 | 1028.8 |
| stack | 100.00% | 196.46 / 270.37 | 4.28 | 1031.3 |
| far-branch | 100.00% | 111.77 / 150.59 | 1.78 | 1041.4 |
| tree | 100.00% | 129.95 / 555.57 | 6.98 | 1032.9 |
| randlist | 99.98% | 212.70 / 374.30 | 7.85 | 1033.8 |
| prefetch | 99.98% | 126.56 / 340.17 | 17.46 | 1041.3 |
| tsearch | 99.98% | 114.86 / 204.00 | 4.70 | 1025.9 |
| ptr-chase | 99.97% | 130.82 / 372.37 | 2.81 | 1011.9 |
| radixsort | 99.94% | 133.01 / 598.89 | 15.04 | 1032.9 |
| llc-affinity | 99.93% | 333.17 / 610.72 | 18.61 | 1040.0 |
| judy | 99.93% | 123.03 / 474.07 | 6.92 | 1026.9 |
| bad-altstack | 99.88% | 116.65 / 170.65 | 15.13 | 958.3 |
| cachehammer | 99.87% | 140.64 / 212.87 | 8.24 | 1029.8 |
| mergesort | 99.83% | 263.97 / 590.59 | 9.98 | 1028.2 |
| lockbus | 99.74% | 105.32 / 194.61 | 2.65 | 895.5 |
| malloc | 99.61% | 143.00 / 388.41 | 5.63 | 1025.0 |
| memfd | 99.44% | 371.42 / 531.63 | 7.44 | 1027.1 |
| jpeg | 99.43% | 108.95 / 163.96 | 6.52 | 1003.2 |

### Guest coloured 8/32, root kept out of guest colours

100 stressor windows in 1 cycle(s) (99 exited 0). Over all periods: latency >100 us 0.000%, response >100 us 24.963%, worst latency 43.85 us, worst task time 885.81 us, worst response 892.91 us.

Top 20 stressors by response-time deadline misses:

| Stressor | Resp >100 us | Task avg/max (us) | Lat max (us) | L3 refills/period |
|---|---|---|---|---|
| matrix-3d | 100.00% | 430.79 / 825.42 | 43.85 | 716.2 |
| vm-rw | 100.00% | 513.31 / 576.07 | 9.44 | 1012.1 |
| memfd | 100.00% | 365.32 / 555.24 | 9.15 | 1002.4 |
| stream | 100.00% | 343.90 / 416.83 | 7.61 | 900.9 |
| stack | 100.00% | 192.32 / 252.91 | 5.85 | 1023.1 |
| opcode | 99.99% | 137.65 / 190.74 | 4.94 | 1024.9 |
| llc-affinity | 99.92% | 230.03 / 508.09 | 19.85 | 675.9 |
| bad-altstack | 99.92% | 128.38 / 205.69 | 3.87 | 1027.2 |
| ptr-chase | 99.84% | 114.75 / 241.48 | 3.54 | 911.5 |
| remap | 99.73% | 115.36 / 313.65 | 4.26 | 997.1 |
| randlist | 99.55% | 225.92 / 379.52 | 7.91 | 1016.7 |
| tree | 99.37% | 123.11 / 627.17 | 8.24 | 967.7 |
| cache | 98.48% | 238.32 / 537.00 | 19.28 | 511.7 |
| mergesort | 97.84% | 217.96 / 542.22 | 11.78 | 731.0 |
| memrate | 96.99% | 247.60 / 737.59 | 10.19 | 1003.4 |
| vm-addr | 94.97% | 470.73 / 885.81 | 13.07 | 802.3 |
| tlb-shootdown | 94.67% | 271.82 / 624.35 | 9.59 | 808.9 |
| vm | 93.74% | 470.12 / 706.41 | 13.52 | 964.1 |
| numa | 93.73% | 279.38 / 712.89 | 12.41 | 970.9 |
| radixsort | 89.74% | 115.34 / 539.63 | 6.96 | 947.3 |

## S4: UnixBench on the root cell

| Copies | Plain Linux (3 CPUs, no hypervisor) | Jailhouse root cell | Overhead |
|---|---|---|---|
| 1 | 1523.0 | 1473.5 | 3.3% |
| 3 | 3389.8 | 3263.1 | 3.7% |

Per test (index, 3 copies):

| Test | Plain | Jailhouse | Overhead |
|---|---|---|---|
| Dhrystone 2 using register variables | 9057.2 | 9055.7 | 0.0% |
| Double-Precision Whetstone | 3818.4 | 3815.3 | 0.1% |
| Execl Throughput | 2588.5 | 2539.1 | 1.9% |
| File Copy 1024 bufsize 2000 maxblocks | 4206.7 | 3971.0 | 5.6% |
| File Copy 256 bufsize 500 maxblocks | 5156.2 | 5133.2 | 0.4% |
| File Copy 4096 bufsize 8000 maxblocks | 2962.9 | 3188.7 | -7.6% |
| Pipe Throughput | 3515.6 | 3517.7 | -0.1% |
| Pipe-based Context Switching | 1462.5 | 1101.0 | 24.7% |
| Process Creation | 1752.7 | 1639.8 | 6.4% |
| Shell Scripts (1 concurrent) | 4820.8 | 4510.1 | 6.4% |
| Shell Scripts (8 concurrent) | 4396.3 | 4254.9 | 3.2% |
| System Call Overhead | 2094.7 | 2096.8 | -0.1% |

## Follow-up experiments

e1 = colour-share sweep, e2 = working-set sweep, e3 = 2+2 core split, e4 = MemGuard on the root cores (budget = L2 refills per core per 1 ms).

| Config | Load | Runs | Task avg/max (us) | Resp >100 us | Lat max (us) | L3 refills/period | Bus accesses/period |
|---|---|---|---|---|---|---|---|
| e1-col12 | idle | 2 | 16.61 / 245.20 | 0.16% | 3.06 | 13.6 | 7877 |
| e1-col12 | cache | 2 | 224.07 / 543.50 | 69.83% | 17.48 | 461.2 | 7609 |
| e1-col12 | stream | 2 | 283.58 / 424.91 | 100.00% | 8.17 | 728.7 | 7651 |
| e1-col12 | vm | 2 | 382.51 / 633.22 | 91.98% | 19.70 | 729.6 | 7596 |
| e1-col16 | idle | 2 | 14.08 / 101.30 | 0.00% | 1.28 | 5.8 | 6357 |
| e1-col16 | cache | 2 | 290.08 / 562.92 | 86.78% | 11.63 | 638.4 | 6701 |
| e1-col16 | stream | 2 | 234.06 / 411.67 | 100.00% | 16.91 | 591.6 | 6397 |
| e1-col16 | vm | 2 | 306.95 / 597.61 | 79.22% | 13.91 | 604.6 | 6854 |
| e1-col8 | idle | 2 | 20.59 / 138.37 | 0.31% | 1.61 | 51.8 | 8257 |
| e1-col8 | cache | 2 | 237.37 / 565.30 | 96.52% | 13.41 | 496.7 | 8271 |
| e1-col8 | stream | 2 | 264.42 / 416.69 | 100.00% | 20.33 | 660.4 | 8213 |
| e1-col8 | vm | 2 | 383.41 / 645.39 | 94.50% | 15.59 | 751.0 | 8206 |
| e2-ws1024-colhog | idle | 1 | 56.55 / 136.26 | 0.53% | 0.93 | 478.4 | 8335 |
| e2-ws1024-colhog | cache | 1 | 337.77 / 552.61 | 98.94% | 16.57 | 743.9 | 8373 |
| e2-ws1024-colhog | stream | 1 | 288.86 / 417.57 | 100.00% | 7.98 | 743.3 | 8394 |
| e2-ws1024-plain | idle | 1 | 16.19 / 130.09 | 0.13% | 1.07 | 12.5 | 7894 |
| e2-ws1024-plain | cache | 1 | 428.03 / 603.80 | 99.72% | 10.31 | 985.1 | 8157 |
| e2-ws1024-plain | stream | 1 | 380.46 / 456.61 | 100.00% | 13.15 | 1041.9 | 8538 |
| e2-ws256-colhog | idle | 1 | 6.09 / 74.63 | 0.00% | 0.80 | 1.8 | 317 |
| e2-ws256-colhog | cache | 1 | 100.74 / 481.11 | 57.02% | 11.02 | 218.4 | 1980 |
| e2-ws256-colhog | stream | 1 | 104.31 / 352.19 | 48.22% | 8.13 | 269.1 | 2726 |
| e2-ws256-plain | idle | 1 | 5.68 / 37.52 | 0.00% | 0.87 | 0.7 | 13 |
| e2-ws256-plain | cache | 1 | 201.92 / 581.39 | 63.07% | 19.59 | 422.5 | 3422 |
| e2-ws256-plain | stream | 1 | 347.61 / 454.81 | 100.00% | 8.43 | 936.3 | 8393 |
| e2-ws512-colhog | idle | 1 | 17.31 / 117.70 | 0.07% | 1.15 | 10.8 | 8193 |
| e2-ws512-colhog | cache | 1 | 176.23 / 557.61 | 73.93% | 11.65 | 285.8 | 7906 |
| e2-ws512-colhog | stream | 1 | 216.25 / 387.44 | 100.00% | 18.46 | 518.0 | 7574 |
| e2-ws512-plain | idle | 1 | 6.35 / 76.07 | 0.00% | 0.91 | 3.0 | 454 |
| e2-ws512-plain | cache | 1 | 338.86 / 606.17 | 75.99% | 13.85 | 748.1 | 6075 |
| e2-ws512-plain | stream | 1 | 371.36 / 457.87 | 100.00% | 21.24 | 999.1 | 8522 |
| e3-2c-colhog | idle | 2 | 20.29 / 126.91 | 0.33% | 1.24 | 47.5 | 8251 |
| e3-2c-colhog | cache | 2 | 227.22 / 536.59 | 94.29% | 10.13 | 467.6 | 8271 |
| e3-2c-colhog | stream | 2 | 192.76 / 443.15 | 99.93% | 7.87 | 487.9 | 8271 |
| e3-2c-colhog | vm | 2 | 234.82 / 597.02 | 71.87% | 12.22 | 535.2 | 8265 |
| e3-2c-colhog | pwalk | 2 | 23.17 / 121.69 | 0.50% | 0.81 | 82.4 | 8249 |
| e3-2c-plain | idle | 2 | 13.79 / 156.61 | 0.01% | 1.35 | 6.0 | 6379 |
| e3-2c-plain | cache | 2 | 339.23 / 609.80 | 98.68% | 10.46 | 822.6 | 7306 |
| e3-2c-plain | stream | 2 | 337.20 / 414.06 | 100.00% | 15.67 | 992.5 | 8090 |
| e3-2c-plain | vm | 2 | 275.38 / 653.61 | 62.38% | 11.54 | 708.6 | 7265 |
| e3-2c-plain | pwalk | 2 | 14.92 / 76.92 | 0.00% | 11.52 | 18.6 | 6369 |
| e4-mg1000-colhog | idle | 1 | 26.42 / 89.37 | 0.00% | 0.78 | 124.3 | 8260 |
| e4-mg1000-colhog | cache | 1 | 62.91 / 514.76 | 0.58% | 5.59 | 555.6 | 8261 |
| e4-mg1000-colhog | stream | 1 | 38.75 / 98.04 | 0.00% | 1.20 | 273.1 | 8270 |
| e4-mg1000-colhog | vm | 1 | 43.31 / 458.11 | 2.77% | 8.43 | 263.9 | 8280 |
| e4-mg1000-plain | idle | 1 | 13.90 / 37.11 | 0.00% | 0.78 | 7.3 | 6363 |
| e4-mg1000-plain | cache | 1 | 45.83 / 488.63 | 5.40% | 7.42 | 280.1 | 6421 |
| e4-mg1000-plain | stream | 1 | 130.86 / 264.35 | 84.06% | 8.22 | 862.1 | 8014 |
| e4-mg1000-plain | vm | 1 | 114.65 / 666.46 | 36.03% | 11.52 | 650.5 | 7349 |
| e4-mg20000-colhog | idle | 1 | 21.10 / 142.28 | 0.39% | 0.98 | 56.9 | 8249 |
| e4-mg20000-colhog | cache | 1 | 195.82 / 542.72 | 68.01% | 10.31 | 454.0 | 8283 |
| e4-mg20000-colhog | stream | 1 | 267.96 / 423.74 | 100.00% | 7.80 | 643.2 | 8233 |
| e4-mg20000-colhog | vm | 1 | 389.85 / 675.30 | 90.46% | 16.31 | 736.3 | 8222 |
| e4-mg20000-plain | idle | 1 | 13.88 / 108.91 | 0.01% | 1.11 | 6.9 | 6376 |
| e4-mg20000-plain | cache | 1 | 281.02 / 577.96 | 83.10% | 10.09 | 800.0 | 7176 |
| e4-mg20000-plain | stream | 1 | 395.78 / 491.89 | 100.00% | 11.83 | 1030.6 | 8458 |
| e4-mg20000-plain | vm | 1 | 504.88 / 745.39 | 97.08% | 21.65 | 1007.7 | 8221 |
| e4-mg5000-colhog | idle | 1 | 21.94 / 103.39 | 0.01% | 0.93 | 68.2 | 8262 |
| e4-mg5000-colhog | cache | 1 | 104.74 / 482.94 | 15.95% | 7.15 | 611.5 | 8281 |
| e4-mg5000-colhog | stream | 1 | 238.76 / 364.57 | 97.80% | 7.26 | 603.7 | 8236 |
| e4-mg5000-colhog | vm | 1 | 186.03 / 651.89 | 62.23% | 15.35 | 586.2 | 8249 |
| e4-mg5000-plain | idle | 1 | 14.13 / 76.11 | 0.00% | 0.78 | 10.2 | 6372 |
| e4-mg5000-plain | cache | 1 | 87.51 / 569.44 | 13.93% | 8.93 | 563.2 | 6681 |
| e4-mg5000-plain | stream | 1 | 186.39 / 450.56 | 99.10% | 7.96 | 1028.5 | 8432 |
| e4-mg5000-plain | vm | 1 | 281.07 / 730.83 | 89.17% | 13.89 | 993.7 | 8240 |

## Board temperature during the runs

Max 57.9 C, mean 44.3 C over 33516 samples; firmware throttle flags seen: 0x0.
