#!/usr/bin/env bash

log_file=/tmp/polybar.log


killall -q polybar

cd ~/.config/polybar 

# Wait untill the processes have been shut down
while pgrep -u $UID -x polybar >/dev/null; do sleep 1; done

echo "===== RESTART =====" | tee -a $log_file &
polybar main -rq >>$log_file 2>&1 &
polybar external -rq >>$log_file 2>&1 &


#if [[ $(xrandr --query | grep 'DP-1-1') = *connected* ]]; then
#		polybar external -rq >>$log_file 2>&1 &
#fi
#polybar bspwm -rq >>$log_file 2>&1 &
#polybar mpd -rq >>$log_file 2>&1 &
#polybar tray -rq >>$log_file 2>&1 &

