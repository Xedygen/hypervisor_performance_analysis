#!/bin/bash
# S1 and S3 with another guest than the bare-metal rt-bench (runs ON the Pi):
#   GUEST=linux   PREEMPT_RT Linux with cyclictest (as on the Pi 4), ~/linux-guest/Image
#   GUEST=zephyr  Zephyr rt-bench, ~/zephyr/rt-bench.bin
#   GUEST=linux FIX_FREQ=1 nohup ~/experiments/pi_guest.sh ~/results-linux > ~/results-linux/guest.log 2>&1 &
# FULL=1 adds S2 (100 stressors, both configs) and E4 (MemGuard budgets); finished
# steps are skipped, so FULL=1 on an existing result directory only adds those.
# Same configurations and layout as pi_night.sh; analyze.py reads the result.
GUEST=${GUEST:-linux}
case $GUEST in
linux)	PLAIN_CELL=rpi5-linux-demo COL_CELL=rpi5-linux-col ;;
zephyr)	PLAIN_CELL=rpi5-zephyr COL_CELL=rpi5-zephyr-col ;;
*)	echo "GUEST must be linux or zephyr"; exit 1 ;;
esac
RES=${1:-$HOME/results-$GUEST}
. "$(dirname "$0")/lib.sh"
S1_SECS=${S1_SECS:-300}
S3_REPS=${S3_REPS:-1}
mkdir -p "$RES"
log "$GUEST guest campaign start, temp $(temp)"
use_config plain
start_cell $PLAIN_CELL
step s1 s1_idle "$S1_SECS" 1
step s3 s3_hw "$S3_REPS" 60
use_config col		# guest coloured 8/32, root Linux unrestricted
start_cell $COL_CELL
step s1 s1_idle "$S1_SECS" 1
step s3 s3_hw "$S3_REPS" 60
use_config colhog	# guest coloured, root kept out of the guest colours
start_cell $COL_CELL
hog_on 24 31
step s1 s1_idle "$S1_SECS" 1
step s3 s3_hw "$S3_REPS" 60
hog_off
if [ "${FULL:-0}" = 1 ]; then
	use_config colhog
	start_cell $COL_CELL
	hog_on 24 31
	step s2 s2_stressors
	hog_off
	use_config plain
	start_cell $PLAIN_CELL
	step s2 s2_stressors
	# E4 as in pi_extra.sh, MemGuard on the root CPUs
	for cfg in "plain $PLAIN_CELL" "colhog $COL_CELL"; do
		set -- $cfg
		for budget in 20000 5000 1000; do
			use_config "extra-e4-mg$budget-$1"
			start_cell "$2"
			[ "$1" = colhog ] && hog_on 24 31
			jh cell memguard 0 1000 "$budget" && mark MEMGUARD 1000 "$budget"
			step e4 loads_run e4 1 60 idle cache stream vm
			jh cell memguard 0 0 0
			[ "$1" = colhog ] && hog_off
		done
	done
fi
log "$GUEST guest campaign done, temp $(temp)"
