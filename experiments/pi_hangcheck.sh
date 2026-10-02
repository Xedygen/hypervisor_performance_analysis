#!/bin/bash
# Re-run the stressors that hung the board before (S2/S3/E-runs), to check
# the lost-IPI fixes in jailhouse-rt (runs ON the Pi):
#   FIX_FREQ=1 nohup ~/experiments/pi_hangcheck.sh ~/results-hangcheck > ~/results-hangcheck/hc.log 2>&1 &
# Each stressor REPS times for SECS s, guest coloured 8/32 + colorhog (most
# hangs were with colorhog), then without colorhog. A hang shows up in
# markers.log as "END hc <stressor> <rep> hang" after the watchdog reset;
# rerun the same command to continue.
RES=${1:-$HOME/results-hangcheck}
. "$(dirname "$0")/lib.sh"
REPS=${REPS:-3}
SECS=${SECS:-30}
STRESSORS="membarrier rmap stack opcode vm tlb-shootdown pipe pipeherd"
mkdir -p "$RES"
log "hang check start, temp $(temp)"
use_config colhog
start_cell rpi5-rtbench-col
hog_on 24 31
step hc loads_run hc "$REPS" "$SECS" $STRESSORS
hog_off
use_config plain
start_cell rpi5-rtbench
step hc loads_run hc "$REPS" "$SECS" $STRESSORS
log "hang check done, temp $(temp)"
