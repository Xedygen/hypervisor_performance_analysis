#!/bin/bash
# Follow-up experiments after pi_night.sh (runs ON the Pi, Jailhouse may be on):
#   nohup ~/experiments/pi_extra.sh ~/results > ~/results/extra.log 2>&1 &
# E1  colour-share sweep: guest gets 8, 12, 16 of 32 L3 colours (root kept out
#     of them with colorhog), fixed 768 KB working set
# E2  working-set sweep: 256/512/768/1024 KB, uncoloured and coloured 8/32
# E3  2+2 core split: guest cell on CPUs 2-3, root load on CPUs 0-1 only
# E4  MemGuard on the root cores: 1 ms period, budget of L2 refills per core
# E4_ONLY=1 skips E1-E3 (for adding E4 to an existing campaign).
# Results go to <results>/extra-<name>/ with the same layout as pi_night.sh.
RES=${1:-$HOME/results}
. "$(dirname "$0")/lib.sh"
SECS=60
MAIN_LOADS="idle cache stream vm"

mkdir -p "$RES"
log "extras start, temp $(temp)"

if [ "${E4_ONLY:-0}" != 1 ]; then
# E1: colour share (root excluded from the guest colours each time)
for spec in "8 rpi5-rtbench-col 24" "12 rpi5-rtbench-col12 20" "16 rpi5-rtbench-col16 16"; do
	set -- $spec
	use_config "extra-e1-col$1"
	start_cell "$2"
	hog_on "$3" 31
	step e1 loads_run e1 2 $SECS $MAIN_LOADS
	hog_off
done

# E2: working-set size, without and with colouring (8/32 + colorhog)
for ws in 256 512 1024; do
	use_config "extra-e2-ws$ws-plain"
	start_cell rpi5-rtbench "ws-kb=$ws"
	step e2 loads_run e2 1 $SECS idle cache stream

	use_config "extra-e2-ws$ws-colhog"
	start_cell rpi5-rtbench-col "ws-kb=$ws"
	hog_on 24 31
	step e2 loads_run e2 1 $SECS idle cache stream
	hog_off
done

# E3: 2+2 split, the root cell loads only CPUs 0-1
ROOT_CPUS=0-1 NLOAD=2
use_config extra-e3-2c-plain
start_cell rpi5-rtbench-2c
step e3 loads_run e3 2 $SECS $MAIN_LOADS pwalk

use_config extra-e3-2c-colhog
start_cell rpi5-rtbench-2c-col
hog_on 24 31
step e3 loads_run e3 2 $SECS $MAIN_LOADS pwalk
hog_off
ROOT_CPUS=0-2 NLOAD=3
fi

# E4: MemGuard on the root cell's CPUs (period 1000 us, L2 refills per period).
for cfg in "plain rpi5-rtbench" "colhog rpi5-rtbench-col"; do
	set -- $cfg
	for budget in 20000 5000 1000; do
		use_config "extra-e4-mg$budget-$1"
		start_cell "$2"
		[ "$1" = colhog ] && hog_on 24 31
		jh cell memguard 0 1000 "$budget" && mark MEMGUARD 1000 "$budget"
		step e4 loads_run e4 1 $SECS $MAIN_LOADS
		jh cell memguard 0 0 0
		[ "$1" = colhog ] && hog_off
	done
done

log "extras done, temp $(temp)"
touch "$RES/EXTRA_DONE"
