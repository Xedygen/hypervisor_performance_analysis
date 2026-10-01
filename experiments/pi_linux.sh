#!/bin/bash
# Thesis scenarios with the PREEMPT_RT Linux guest running cyclictest (as on
# the Pi 4) instead of rt-bench (runs ON the Pi; guest Image in ~/linux-guest):
#   FIX_FREQ=1 nohup ~/experiments/pi_linux.sh ~/results-linux > ~/results-linux/linux.log 2>&1 &
# Same configurations and layout as pi_night.sh; analyze.py reads the result.
RES=${1:-$HOME/results-linux}
. "$(dirname "$0")/lib.sh"
S1_SECS=${S1_SECS:-300}
S3_REPS=${S3_REPS:-1}
mkdir -p "$RES"
log "linux guest campaign start, temp $(temp)"
use_config plain
start_cell rpi5-linux-demo
step s1 s1_idle "$S1_SECS" 1
step s3 s3_hw "$S3_REPS" 60
use_config col		# guest coloured 8/32, root Linux unrestricted
start_cell rpi5-linux-col
step s1 s1_idle "$S1_SECS" 1
step s3 s3_hw "$S3_REPS" 60
use_config colhog	# guest coloured, root kept out of the guest colours
start_cell rpi5-linux-col
hog_on 24 31
step s1 s1_idle "$S1_SECS" 1
step s3 s3_hw "$S3_REPS" 60
hog_off
log "linux guest campaign done, temp $(temp)"
