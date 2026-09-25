#!/bin/bash
# Started by cron @reboot while an unattended run is in progress (and once by
# hand): continues where the campaigns stopped.
#   1. pi_night.sh  (~/results, default frequency)       -> results/DONE
#   2. pi_extra.sh  (~/results)                           -> results/EXTRA_DONE
#   3. pi_fixed.sh  (~/results-fixed, fixed 2.4 GHz, incl. its extras
#                    and the bare-Linux reference)         -> results-fixed/FIXED_DONE
# Remove the cron entry when everything is done:
#   crontab -l | grep -v experiments/resume.sh | crontab -
EXP=$HOME/experiments
R1=$HOME/results
R2=$HOME/results-fixed
sleep 60	# let the network and the thermal guard come up
[ -e "$R1/DONE" ] || "$EXP/pi_night.sh" "$R1" >> "$R1/night.log" 2>&1
[ -e "$R1/DONE" ] && [ ! -e "$R1/EXTRA_DONE" ] &&
	"$EXP/pi_extra.sh" "$R1" >> "$R1/extra.log" 2>&1
if [ -e "$R1/EXTRA_DONE" ] && [ ! -e "$R2/FIXED_DONE" ]; then
	mkdir -p "$R2"
	FIX_FREQ=1 "$EXP/pi_fixed.sh" "$R2" >> "$R2/fixed.log" 2>&1
fi
