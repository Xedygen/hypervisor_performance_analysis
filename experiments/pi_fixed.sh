#!/bin/bash
# Second campaign: all thesis scenarios at a fixed CPU frequency (performance
# governor, 2.4 GHz), with the thesis's repetition counts (S1 3x, S3 3x,
# S2 3 full passes over 100 stressors) for every configuration, followed by
# the follow-up experiments and the bare-Linux UnixBench reference.
# Runs ON the Pi, started by resume.sh after the first campaign:
#   FIX_FREQ=1 ~/experiments/pi_fixed.sh ~/results-fixed
RES=${1:-$HOME/results-fixed}
export FIX_FREQ=1
. "$(dirname "$0")/lib.sh"

mkdir -p "$RES"
log "fixed-frequency campaign start, temp $(temp)"

use_config plain
start_cell rpi5-rtbench
step s1 s1_idle 300 3
step s3 s3_hw 3 60
step s2 s2_stressors 3
step s4 s4_unixbench jailhouse

use_config col		# guest coloured 8/32, root Linux unrestricted (thesis config)
start_cell rpi5-rtbench-col
step s1 s1_idle 300 3
step s3 s3_hw 3 60
step s2 s2_stressors 3

use_config colhog	# guest coloured, root kept out of the guest colours
start_cell rpi5-rtbench-col
hog_on 24 31
step s1 s1_idle 300 3
step s3 s3_hw 3 60
step s2 s2_stressors 3
hog_off

# follow-ups E1-E4 at the same frequency
[ -e "$RES/EXTRA_DONE" ] || "$EXP/pi_extra.sh" "$RES"

# S4 reference without the hypervisor, CPU 3 offline so both runs have 3
# CPUs. Last, because CPU 3 does not come back online on this board.
use_config bare
if [ ! -e "$OUT/done.s4" ]; then
	jh cell list | grep -q rt-bench && jh cell destroy rt-bench
	sudo pkill -f "jailhouse console -f"
	[ "$(cat /sys/devices/jailhouse/enabled 2>/dev/null)" = 1 ] && jh disable
	echo 0 | sudo tee /sys/devices/system/cpu/cpu3/online >/dev/null
	step s4 s4_unixbench bare
fi

log "fixed-frequency campaign done, temp $(temp)"
touch "$RES/FIXED_DONE"
