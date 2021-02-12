#!/usr/bin/env sh



# Kill existing desknamer
active_desknamers=$(pgrep -f "desknamer.sh")
if ! test -z "$active_desknamers"
then
		kill -9 $active_desknamers &
fi



echo "===== RESTART =====" | tee -a /tmp/desknamer.log
$HOME/.config/desknamer/desknamer.sh >>/tmp/desknamer.log &
