#!/bin/bash
# Unattended run of the thesis scenarios on the Pi 5 (runs ON the Pi, as pi).
# Start from a fresh boot (Jailhouse not enabled):
#   nohup ~/experiments/pi_night.sh ~/results > ~/results/night.log 2>&1 &
# Each configuration writes to <results>/<config>/:
#   console.log  hypervisor console (rt-bench "W" lines), prefixed with epoch time
#   markers.log  "<epoch> START|END <scenario> <load> <rep> [rc]" around every run
#   unixbench-*.txt, colorhog.txt, stress.err, done.<step>
# Needs: jailhouse-rt built in ~/jailhouse-rt, thermal-guard service running.
RES=${1:-$HOME/results}
. "$(dirname "$0")/lib.sh"

mkdir -p "$RES"
log "start, temp $(temp)"

# S4 on plain Linux, no hypervisor, CPU 3 offline so both runs have 3 CPUs.
# Skipped when a complete result exists: CPU 3 does not come back online
# after a long offline period on this board (firmware PSCI CPU_ON fails),
# so this step needs a reboot afterwards. Better: boot with maxcpus=3.
use_config bare
if [ "$(grep -c 'Index Score' "$OUT/unixbench-bare.txt" 2>/dev/null)" != 2 ]; then
	echo 0 | sudo tee /sys/devices/system/cpu/cpu3/online >/dev/null
	s4_unixbench bare
	log "bare done; reboot before the Jailhouse part (CPU 3 stays offline)"
	exit 0
fi

# Order: the colouring comparison (S1/S3 for all three configs) first, then
# the long S2 and S4 runs.
use_config plain
start_cell rpi5-rtbench
step s1 s1_idle 300 3
step s3 s3_hw 3 60

use_config col		# guest coloured 8/32, root Linux unrestricted (thesis config)
start_cell rpi5-rtbench-col
step s1 s1_idle 300 1
step s3 s3_hw 3 60

use_config colhog	# guest coloured, root kept out of the guest colours
start_cell rpi5-rtbench-col
hog_on 24 31
step s1 s1_idle 300 1
step s3 s3_hw 3 60
step s2 s2_stressors
hog_off

use_config plain
start_cell rpi5-rtbench
step s2 s2_stressors
step s4 s4_unixbench jailhouse

log "all done, temp $(temp)"
touch "$RES/DONE"
