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

## S4: UnixBench on the root cell

| Copies | Plain Linux (3 CPUs, no hypervisor) | Jailhouse root cell | Overhead |
|---|---|---|---|
