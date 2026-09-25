#!/bin/bash
# Started by cron @reboot while an unattended run is in progress: resumes
# pi_night.sh, then runs pi_extra.sh. Remove the cron entry when done:
#   crontab -l | grep -v experiments/resume.sh | crontab -
RES=$HOME/results
sleep 60	# let the network and the thermal guard come up
[ -e "$RES/DONE" ] || "$HOME/experiments/pi_night.sh" "$RES" >> "$RES/night.log" 2>&1
[ -e "$RES/DONE" ] && [ ! -e "$RES/EXTRA_DONE" ] &&
	"$HOME/experiments/pi_extra.sh" "$RES" >> "$RES/extra.log" 2>&1
