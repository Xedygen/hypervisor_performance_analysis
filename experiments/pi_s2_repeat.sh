#!/bin/bash
# Bring S2 up to the thesis's 3 cycles per configuration in an existing
# campaign (runs ON the Pi; already finished repetitions are skipped):
#   FIX_FREQ=1 nohup ~/experiments/pi_s2_repeat.sh ~/results-fixed > ~/results-fixed/s2rep.log 2>&1 &
RES=${1:-$HOME/results-fixed}
. "$(dirname "$0")/lib.sh"
log "S2 repeat start, temp $(temp)"
use_config colhog
start_cell rpi5-rtbench-col
hog_on 24 31
s2_stressors 3
hog_off
use_config plain
start_cell rpi5-rtbench
s2_stressors 3
log "S2 repeat done, temp $(temp)"
