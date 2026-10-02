# Pi 5 results: thesis scenarios S1-S4

## S1: baseline, root cell idle

| Config | Runs | Lat min/avg/max (us) | Lat >100 us | Task avg/max (us) | Resp max (us) | Resp >100 us |
|---|---|---|---|---|---|---|
| Spatial isolation only (no colouring) | 1 | 0.56 / 0.57 / 1.54 | 0.000% | 14.11 / 113.15 | 114.04 | 0.010% |
| Guest coloured 8/32, root unrestricted | 1 | 0.56 / 0.57 / 2.33 | 0.000% | 22.50 / 170.26 | 171.59 | 0.461% |
| Guest coloured 8/32, root kept out of guest colours | 1 | 0.56 / 0.57 / 6.30 | 0.000% | 22.95 / 358.70 | 362.67 | 0.664% |

## S3: targeted memory interference (3 root cores), per load

Per period: task = pointer-chase control task; L3 refills and bus accesses are PMU counts on the guest CPU.

| Load | Config | Task avg/max (us) | Resp max (us) | Resp >100 us | Lat max (us) | L3 refills/period | Bus accesses/period |
|---|---|---|---|---|---|---|---|
| idle | Spatial isolation only (no colouring) | 14.08 / 108.67 | 109.48 | 0.01% | 1.41 | 5.4 | 6351 |
| idle | Guest coloured 8/32, root unrestricted | 22.45 / 141.72 | 142.41 | 0.46% | 1.07 | 59.0 | 8286 |
| idle | Guest coloured 8/32, root kept out of guest colours | 22.76 / 171.87 | 173.46 | 0.61% | 1.63 | 62.3 | 8290 |
| cache | Spatial isolation only (no colouring) | 467.15 / 622.07 | 629.28 | 99.76% | 21.85 | 983.2 | 8041 |
| cache | Guest coloured 8/32, root unrestricted | 433.75 / 581.00 | 587.31 | 100.00% | 21.31 | 1034.8 | 8347 |
| cache | Guest coloured 8/32, root kept out of guest colours | 305.99 / 586.39 | 594.89 | 99.26% | 12.52 | 593.2 | 8267 |
| stream | Spatial isolation only (no colouring) | 397.69 / 494.35 | 502.57 | 100.00% | 12.26 | 1037.6 | 8623 |
| stream | Guest coloured 8/32, root unrestricted | 397.36 / 480.76 | 486.98 | 100.00% | 12.43 | 1044.2 | 8639 |
| stream | Guest coloured 8/32, root kept out of guest colours | 365.68 / 475.37 | 479.20 | 100.00% | 10.93 | 973.4 | 8523 |
| memcpy | Spatial isolation only (no colouring) | 14.16 / 101.63 | 102.54 | 0.00% | 1.46 | 6.2 | 6355 |
| memcpy | Guest coloured 8/32, root unrestricted | 23.05 / 135.11 | 135.70 | 0.78% | 1.33 | 65.7 | 8287 |
| memcpy | Guest coloured 8/32, root kept out of guest colours | 23.12 / 186.56 | 187.28 | 0.83% | 1.72 | 66.2 | 8286 |
| vm | Spatial isolation only (no colouring) | 505.73 / 754.81 | 765.78 | 97.09% | 23.72 | 1017.0 | 8327 |
| vm | Guest coloured 8/32, root unrestricted | 501.74 / 774.24 | 780.61 | 99.96% | 18.78 | 1036.5 | 8459 |
| vm | Guest coloured 8/32, root kept out of guest colours | 462.89 / 719.04 | 725.74 | 96.26% | 16.33 | 958.2 | 8343 |
| pwalk | Spatial isolation only (no colouring) | 15.75 / 107.20 | 108.13 | 0.03% | 1.83 | 23.5 | 6362 |
| pwalk | Guest coloured 8/32, root unrestricted | 26.35 / 132.83 | 133.43 | 1.00% | 1.76 | 103.5 | 8294 |
| pwalk | Guest coloured 8/32, root kept out of guest colours | 26.18 / 162.06 | 163.83 | 1.22% | 1.78 | 101.9 | 8290 |

## S2: 100 stress-ng stressors x 30 s on the root cell

## S4: UnixBench on the root cell

| Copies | Plain Linux (3 CPUs, no hypervisor) | Jailhouse root cell | Overhead |
|---|---|---|---|
