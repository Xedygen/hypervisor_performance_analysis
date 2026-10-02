# Pi 5 results: thesis scenarios S1-S4

## S1: baseline, root cell idle

| Config | Runs | Lat min/avg/max (us) | Lat >100 us | Task avg/max (us) | Resp max (us) | Resp >100 us |
|---|---|---|---|---|---|---|
| Spatial isolation only (no colouring) | 1 | 1.00 / 1.00 / 18.00 | 0.000% | 0.00 / 0.00 | 18.00 | 0.000% |
| Guest coloured 8/32, root unrestricted | 1 | 1.00 / 1.00 / 19.00 | 0.000% | 0.00 / 0.00 | 19.00 | 0.000% |
| Guest coloured 8/32, root kept out of guest colours | 1 | 1.00 / 1.00 / 17.00 | 0.000% | 0.00 / 0.00 | 17.00 | 0.000% |

## S3: targeted memory interference (3 root cores), per load

Per period: task = pointer-chase control task; L3 refills and bus accesses are PMU counts on the guest CPU.

| Load | Config | Task avg/max (us) | Resp max (us) | Resp >100 us | Lat max (us) | L3 refills/period | Bus accesses/period |
|---|---|---|---|---|---|---|---|
| idle | Spatial isolation only (no colouring) | 0.00 / 0.00 | 11.00 | 0.00% | 11.00 | 0.0 | 0 |
| idle | Guest coloured 8/32, root unrestricted | 0.00 / 0.00 | 17.00 | 0.00% | 17.00 | 0.0 | 0 |
| idle | Guest coloured 8/32, root kept out of guest colours | 0.00 / 0.00 | 16.00 | 0.00% | 16.00 | 0.0 | 0 |
| cache | Spatial isolation only (no colouring) | 0.00 / 0.00 | 63.00 | 0.00% | 63.00 | 0.0 | 0 |
| cache | Guest coloured 8/32, root unrestricted | 0.00 / 0.00 | 52.00 | 0.00% | 52.00 | 0.0 | 0 |
| cache | Guest coloured 8/32, root kept out of guest colours | 0.00 / 0.00 | 41.00 | 0.00% | 41.00 | 0.0 | 0 |
| stream | Spatial isolation only (no colouring) | 0.00 / 0.00 | 54.00 | 0.00% | 54.00 | 0.0 | 0 |
| stream | Guest coloured 8/32, root unrestricted | 0.00 / 0.00 | 54.00 | 0.00% | 54.00 | 0.0 | 0 |
| stream | Guest coloured 8/32, root kept out of guest colours | 0.00 / 0.00 | 51.00 | 0.00% | 51.00 | 0.0 | 0 |
| memcpy | Spatial isolation only (no colouring) | 0.00 / 0.00 | 23.00 | 0.00% | 23.00 | 0.0 | 0 |
| memcpy | Guest coloured 8/32, root unrestricted | 0.00 / 0.00 | 16.00 | 0.00% | 16.00 | 0.0 | 0 |
| memcpy | Guest coloured 8/32, root kept out of guest colours | 0.00 / 0.00 | 17.00 | 0.00% | 17.00 | 0.0 | 0 |
| vm | Spatial isolation only (no colouring) | 0.00 / 0.00 | 79.00 | 0.00% | 79.00 | 0.0 | 0 |
| vm | Guest coloured 8/32, root unrestricted | 0.00 / 0.00 | 75.00 | 0.00% | 75.00 | 0.0 | 0 |
| vm | Guest coloured 8/32, root kept out of guest colours | 0.00 / 0.00 | 64.00 | 0.00% | 64.00 | 0.0 | 0 |
| pwalk | Spatial isolation only (no colouring) | 0.00 / 0.00 | 12.00 | 0.00% | 12.00 | 0.0 | 0 |
| pwalk | Guest coloured 8/32, root unrestricted | 0.00 / 0.00 | 15.00 | 0.00% | 15.00 | 0.0 | 0 |
| pwalk | Guest coloured 8/32, root kept out of guest colours | 0.00 / 0.00 | 16.00 | 0.00% | 16.00 | 0.0 | 0 |

## S2: 100 stress-ng stressors x 30 s on the root cell

### Spatial isolation only (no colouring)

100 stressor windows in 1 cycle(s) (99 exited 0). Over all periods: latency >100 us 0.000%, response >100 us 0.000%, worst latency 87.00 us, worst task time 0.00 us, worst response 87.00 us.

Top 20 stressors by response-time deadline misses:

| Stressor | Resp >100 us | Task avg/max (us) | Lat max (us) | L3 refills/period |
|---|---|---|---|---|
| vm | 0.00% | 0.00 / 0.00 | 87.00 | 0.0 |
| numa | 0.00% | 0.00 / 0.00 | 81.00 | 0.0 |
| matrix-3d | 0.00% | 0.00 / 0.00 | 81.00 | 0.0 |
| mergesort | 0.00% | 0.00 / 0.00 | 70.00 | 0.0 |
| vm-rw | 0.00% | 0.00 / 0.00 | 68.00 | 0.0 |
| memthrash | 0.00% | 0.00 / 0.00 | 62.00 | 0.0 |
| bitonicsort | 0.00% | 0.00 / 0.00 | 61.00 | 0.0 |
| llc-affinity | 0.00% | 0.00 / 0.00 | 60.00 | 0.0 |
| vm-addr | 0.00% | 0.00 / 0.00 | 59.00 | 0.0 |
| prefetch | 0.00% | 0.00 / 0.00 | 56.00 | 0.0 |
| qsort | 0.00% | 0.00 / 0.00 | 56.00 | 0.0 |
| memfd | 0.00% | 0.00 / 0.00 | 55.00 | 0.0 |
| stream | 0.00% | 0.00 / 0.00 | 52.00 | 0.0 |
| tlb-shootdown | 0.00% | 0.00 / 0.00 | 51.00 | 0.0 |
| cache | 0.00% | 0.00 / 0.00 | 50.00 | 0.0 |
| stack | 0.00% | 0.00 / 0.00 | 47.00 | 0.0 |
| memrate | 0.00% | 0.00 / 0.00 | 47.00 | 0.0 |
| radixsort | 0.00% | 0.00 / 0.00 | 44.00 | 0.0 |
| randlist | 0.00% | 0.00 / 0.00 | 42.00 | 0.0 |
| judy | 0.00% | 0.00 / 0.00 | 37.00 | 0.0 |

### Guest coloured 8/32, root kept out of guest colours

100 stressor windows in 1 cycle(s) (98 exited 0). Over all periods: latency >100 us 0.000%, response >100 us 0.000%, worst latency 78.00 us, worst task time 0.00 us, worst response 78.00 us.

Top 20 stressors by response-time deadline misses:

| Stressor | Resp >100 us | Task avg/max (us) | Lat max (us) | L3 refills/period |
|---|---|---|---|---|
| vm | 0.00% | 0.00 / 0.00 | 78.00 | 0.0 |
| matrix-3d | 0.00% | 0.00 / 0.00 | 68.00 | 0.0 |
| tlb-shootdown | 0.00% | 0.00 / 0.00 | 65.00 | 0.0 |
| vm-addr | 0.00% | 0.00 / 0.00 | 62.00 | 0.0 |
| mergesort | 0.00% | 0.00 / 0.00 | 59.00 | 0.0 |
| vm-rw | 0.00% | 0.00 / 0.00 | 59.00 | 0.0 |
| memfd | 0.00% | 0.00 / 0.00 | 56.00 | 0.0 |
| memrate | 0.00% | 0.00 / 0.00 | 55.00 | 0.0 |
| cache | 0.00% | 0.00 / 0.00 | 54.00 | 0.0 |
| numa | 0.00% | 0.00 / 0.00 | 53.00 | 0.0 |
| stream | 0.00% | 0.00 / 0.00 | 51.00 | 0.0 |
| llc-affinity | 0.00% | 0.00 / 0.00 | 49.00 | 0.0 |
| randlist | 0.00% | 0.00 / 0.00 | 45.00 | 0.0 |
| memthrash | 0.00% | 0.00 / 0.00 | 45.00 | 0.0 |
| prefetch | 0.00% | 0.00 / 0.00 | 45.00 | 0.0 |
| radixsort | 0.00% | 0.00 / 0.00 | 40.00 | 0.0 |
| full | 0.00% | 0.00 / 0.00 | 39.00 | 0.0 |
| qsort | 0.00% | 0.00 / 0.00 | 39.00 | 0.0 |
| bitonicsort | 0.00% | 0.00 / 0.00 | 38.00 | 0.0 |
| tree | 0.00% | 0.00 / 0.00 | 35.00 | 0.0 |

## S4: UnixBench on the root cell

| Copies | Plain Linux (3 CPUs, no hypervisor) | Jailhouse root cell | Overhead |
|---|---|---|---|

## Follow-up experiments

e1 = colour-share sweep, e2 = working-set sweep, e3 = 2+2 core split, e4 = MemGuard on the root cores (budget = L2 refills per core per 1 ms).

| Config | Load | Runs | Task avg/max (us) | Resp >100 us | Lat max (us) | L3 refills/period | Bus accesses/period |
|---|---|---|---|---|---|---|---|
| e4-mg1000-colhog | idle | 1 | 0.00 / 0.00 | 0.00% | 16.00 | 0.0 | 0 |
| e4-mg1000-colhog | cache | 1 | 0.00 / 0.00 | 0.00% | 23.00 | 0.0 | 0 |
| e4-mg1000-colhog | stream | 1 | 0.00 / 0.00 | 0.00% | 31.00 | 0.0 | 0 |
| e4-mg1000-colhog | vm | 1 | 0.00 / 0.00 | 0.00% | 48.00 | 0.0 | 0 |
| e4-mg1000-plain | idle | 1 | 0.00 / 0.00 | 0.00% | 27.00 | 0.0 | 0 |
| e4-mg1000-plain | cache | 1 | 0.00 / 0.00 | 0.00% | 43.00 | 0.0 | 0 |
| e4-mg1000-plain | stream | 1 | 0.00 / 0.00 | 0.00% | 37.00 | 0.0 | 0 |
| e4-mg1000-plain | vm | 1 | 0.00 / 0.00 | 0.00% | 59.00 | 0.0 | 0 |
| e4-mg20000-colhog | idle | 1 | 0.00 / 0.00 | 0.00% | 15.00 | 0.0 | 0 |
| e4-mg20000-colhog | cache | 1 | 0.00 / 0.00 | 0.00% | 54.00 | 0.0 | 0 |
| e4-mg20000-colhog | stream | 1 | 0.00 / 0.00 | 0.00% | 44.00 | 0.0 | 0 |
| e4-mg20000-colhog | vm | 1 | 0.00 / 0.00 | 0.00% | 70.00 | 0.0 | 0 |
| e4-mg20000-plain | idle | 1 | 0.00 / 0.00 | 0.00% | 13.00 | 0.0 | 0 |
| e4-mg20000-plain | cache | 1 | 0.00 / 0.00 | 0.00% | 56.00 | 0.0 | 0 |
| e4-mg20000-plain | stream | 1 | 0.00 / 0.00 | 0.00% | 57.00 | 0.0 | 0 |
| e4-mg20000-plain | vm | 1 | 0.00 / 0.00 | 0.00% | 81.00 | 0.0 | 0 |
| e4-mg5000-colhog | idle | 1 | 0.00 / 0.00 | 0.00% | 17.00 | 0.0 | 0 |
| e4-mg5000-colhog | cache | 1 | 0.00 / 0.00 | 0.00% | 48.00 | 0.0 | 0 |
| e4-mg5000-colhog | stream | 1 | 0.00 / 0.00 | 0.00% | 44.00 | 0.0 | 0 |
| e4-mg5000-colhog | vm | 1 | 0.00 / 0.00 | 0.00% | 76.00 | 0.0 | 0 |
| e4-mg5000-plain | idle | 1 | 0.00 / 0.00 | 0.00% | 13.00 | 0.0 | 0 |
| e4-mg5000-plain | cache | 1 | 0.00 / 0.00 | 0.00% | 57.00 | 0.0 | 0 |
| e4-mg5000-plain | stream | 1 | 0.00 / 0.00 | 0.00% | 55.00 | 0.0 | 0 |
| e4-mg5000-plain | vm | 1 | 0.00 / 0.00 | 0.00% | 82.00 | 0.0 | 0 |
