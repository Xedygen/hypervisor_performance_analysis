#!/bin/bash
# S1 and S3 with another guest than the bare-metal rt-bench (runs ON the Pi):
#   GUEST=linux   PREEMPT_RT Linux with cyclictest (as on the Pi 4), ~/linux-guest/Image
#   GUEST=zephyr  Zephyr rt-bench, ~/zephyr/rt-bench.bin
#   GUEST=linux FIX_FREQ=1 nohup ~/experiments/pi_guest.sh ~/results-linux > ~/results-linux/guest.log 2>&1 &
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
log "$GUEST guest campaign done, temp $(temp)"
