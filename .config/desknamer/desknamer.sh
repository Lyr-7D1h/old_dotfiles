#!/usr/bin/env bash

RESET='\e[0m'
BOLD='\e[;1m'
RED='\e[31m'
GREEN='\e[32m'
ORANGE='\e[33m'
BLUE='\e[34m'

getAllApplications() { find -L /usr/share/applications /usr/local/share/applications ~/.local/share/applications -iname *.desktop 2>/dev/null; }

getAllCategories() {
	IFS=$'\n'
	for menuItem in $(getAllApplications); do
		sed -n 's/;/ /g; s/ /\n/g; s/^Categories=//p' < "$menuItem"
	done | sort -u
}

findMenuItem() {
	local menuItem=""

	# start specific, then get desperate for any matches
	for expression in "$1" "*$1"; do
		menuItem="$(find -L /usr/share/applications /usr/local/share/applications ~/.local/share/applications -iname "$expression".desktop 2>/dev/null)"
		[ -n "$menuItem" ] && break
	done
	echo "$menuItem" | head -n 1
}

getCategory() {
	local comm="$1"

	# if input is a file, it's likely a path to a menu item. Otherwise, find menu item
	[ -f "$comm" ] && menuItem="$comm" || menuItem="$(findMenuItem "$comm")"

	if [ -n "$menuItem" ]; then
		((verbose)) && echo -e " ├── [$comm] ${GREEN}Found menu item:${RESET} $menuItem"

		# grab categories from Categories= line and add to list
		local categories=$(sed -n 's/;/ /g; s/^Categories=//p' "$menuItem")
		if [ -n "$categories" ]; then
			desktopCategories+=($categories)
			((verbose)) && echo -e " ├── [$comm] ${GREEN}Added categories:${RESET} $categories"
			return 0
		else
			((verbose)) && echo -e " ├── [$comm] ${RED}No categories found.${RESET}"
			return 1
		fi
	else
		((verbose)) && echo -e " ├── [$comm] ${RED}No menu item found${RESET}"
		return 1
	fi
}

addClasses() {
	local node="$1"

	# get WM_CLASS window property
	local returnValue=1
	IFS=$'\n'
	for class in $(xprop -id "$node" WM_CLASS 2>/dev/null | cut -d '=' -f 2 | sed 's/, /\n/g; s/.*"\(.*\)".*/\1/gm'); do
		if [ -n "$class" ]; then
			[ "$class" == "WM_CLASS" ] && continue
			processList+=("$class")
			((verbose)) && echo -e " ├── ${GREEN}Found${RESET} [$class] via WM_CLASS property"
			returnValue=0
		fi
	done

	return "$returnValue"
}

addComms() {
	local pid="$1"

	# get names recursively for this pid
	IFS=$'\n'
	((recursive)) && for childPid in $(ps -o pid:1= --ppid "$pid" 2>/dev/null | tr -d '[:space:]'); do
		addComms "$childPid"
	done

	# accessing process file is faster than ps
	local comm="$({ tr '\0' '\n' < "/proc/$pid/comm"; } 2>/dev/null)"

	if [ -n "$comm" ]; then
		((verbose)) && echo -e " ├── ${GREEN}Found${RESET} [$comm] via PID: $pid"
		processList+=("$comm")
		return 0
	else
		return 1
	fi
}

inspectNode() {
	local node="$1"

	# grab PID from window properties
	local pid=$(xprop -id "$node" _NET_WM_PID 2>/dev/null | awk '{print $3}')
	[ "$pid" == "found." ] && pid=""
	((verbose)) && echo -e " ├─ ${BOLD}${BLUE}Node ID${RESET}: $node [PID: ${pid:-NONE}]"

	# get WM_CLASS names and process names of this node
	addClasses "$node"
	[ -n "$pid" ] && addComms "$pid"
}

renameDesktops() {
	local desktopIDs="$@"
	IFS=' '
	for desktopID in $desktopIDs; do
		monitorID="$(bspc query --desktop "$desktopID" --monitors)"

		if [ "${monitorBlacklist#*$monitorID}" != "$monitorBlacklist" ] || [ "${desktopBlacklist#*$monitorID}" != "$desktopBlacklist" ]; then
			echo -e " └ Not renaming Desktop ID: $desktopID\n"
			return 0
		fi
		echo -e " ├ ${BOLD}${BLUE}Renaming Desktop ID${RESET}: $desktopID"

		desktopName="$(bspc query --names --desktop "$desktopID" --desktops)"
		echo -e " ├─ Current Desktop Name: ${GREEN}$desktopName ${RESET}"

		((verbose)) && echo " ├─ Monitor ID: $monitorID"

		desktopIndex="$(bspc query -m "$monitorID" --desktops | grep -n "$desktopID" | cut -d ':' -f 1)"
		echo " ├─ Desktop Index: $desktopIndex"

		# inspect each node (containing a window) in this desktop
		desktopCategories=()
		processList=()
		IFS=$'\n'
		for node in $(bspc query -m "$monitorID" -d "$desktopID" -n .window -N); do
			inspectNode "$node"
		done

		# filter out duplicate process names
		[ "${#processList[@]}" -gt 0 ] && processList=($(tr ' ' '\n' <<< "${processList[@]}" | sort -u | tr '\n' ' '))
		echo " ├─ Unique Process Names: ${processList[@]}"

		# check programs against custom list of categories
		IFS=' '
		for comm in ${processList[@]}; do
			getCategory "$comm"

			# get custom category if present in config file
			if grep -q "$comm" <<< "$config"; then
				customCategory="$(2>/dev/null python3 -c "import sys, json; print(json.load(sys.stdin)['applications']['$comm'])" <<< "$config")"
				if [ -n "$customCategory" ]; then
					desktopCategories+=($customCategory)
					echo -e " ├── [$comm] ${GREEN}Added custom category${RESET}: $customCategory"
				fi
			fi
		done

		desktopCategories=($(tr ' ' '\n' <<< "${desktopCategories[@]}" | sort -u | tr '\n' ' '))
		echo -e " ├─ Unique Categories: ${desktopCategories[@]}"

		# using python, check config for name with lowest priority
		# convert bash array to python array
		pythonDesktopCategories="$(for category in "${desktopCategories[@]}"; do echo -n "\"$category\""; [ "$category" != "${desktopCategories[-1]}" ] && echo -n ", "; done)"
		name="$(python3 -c "\
import sys, json

minPriority = 100
name = \"\"

data = json.load(open('$configFile'))

for category in [$pythonDesktopCategories]:
	try:
		priority = data['categories'][category][1]
	except KeyError:
		continue
	if priority < minPriority:
		minPriority = priority
		name = data['categories'][category][0]

print(name)" <<< "$config")"

		## fallback names

		# existing programs, but none recognized
		[ -z "$name" ] && [ "${#processList[@]}" -gt 0 ] && { name="$(2>/dev/null python3 -c "import sys, json; print(json.load(sys.stdin)['categories']['default'][0])" <<< "$config")" || name="*"; }

		# or, find custom index name
		[ -z "$name" ] && name="$(2>/dev/null python3 -c "import sys, json; print(json.load(sys.stdin)['indexes']['$desktopIndex'])" <<< "$config")"

		# or, just plain index
		[ -z "$name" ] && name="$desktopIndex"	# no applications

		echo -e " └─ New Name: ${BLUE}$name ${RESET}\n"
		bspc desktop "$desktopID" --rename "$name"
	done
}

renameMonitor() {
	monitorID="$1"
	# ensure monitorID exists in monitorWhitelist and not in monitorBlacklist
	if [ "${monitorBlacklist#*$monitorID}" != "$monitorBlacklist" ]; then
		echo -e " ├ Not renaming monitor: $monitorID\n"
		return 0
	fi
	echo "Renaming monitor: $monitorID"
	IFS=$'\n'
	for desktop in $(bspc query -m "$monitorID" -D); do renameDesktops "$desktop"; done
}

renameAll() {
	echo " ├ Renaming All Monitors"
	IFS=$'\n'
	for monitorID in $(bspc query -M); do renameMonitor "$monitorID"; done
}

monitor() {
	bspc subscribe monitor_add monitor_remove monitor_swap desktop_add desktop_remove desktop_swap desktop_transfer node_add node_remove node_swap node_transfer | while read -r line; do	# trigger on any bspwm event

		echo -e "${BOLD}${RED}trigger:${RESET} $line"
		case "$line" in
			monitor*) renameAll ;;
			desktop_add*|desktop_remove*) renameAll ;;
			desktop_swap*) renameDesktops "$(echo "$line" | awk '{print $3,$5}')" ;;
			desktop_transfer*) renameDesktops "$(echo "$line" | awk '{print $3}')" ;;
			node_add*|node_remove*) renameDesktops "$(echo "$line" | awk '{print $3}')" ;;
			node_swap*|node_transfer*) renameDesktops "$(echo "$line" | awk '{print $3,$6}')" ;;
		esac
	done
}

flag_h=0
recursive=1
mode="monitor"

configFile=~/.config/desknamer/desknamer.json

verbose=0
python=0

processList=()
desktopCategories=()

OPTS="hc:nvM:D:lLs:g:"	# colon (:) means it requires a subsequent value
LONGOPTS="help,config:,norecursive,verbose,monitor-blacklist:,desktop-blacklist:,list-applications,list-categories,search:,get:"

parsed=$(getopt --options=$OPTS --longoptions=$LONGOPTS -- "$@")
eval set -- "${parsed[@]}"

while true; do
	case "$1" in
		-h|--help) flag_h=1; shift ;;
		-c|--config) configFile="$2"; shift 2 ;;
		-n|--norecursive) recursive=0; shift ;;
		-v|--verbose) verbose=1; shift ;;

		-M|--monitor-blacklist) monitorBlacklistIn="$2"; shift 2 ;;
		-D|--desktop-blacklist) desktopBlacklistIn="$2"; shift 2 ;;

		-l|--list-applications) mode="list-applications"; shift ;;
		-L|--list-categories) mode="list-categories"; shift ;;
		-s|--search) mode="search"; application="$2"; shift 2 ;;
		-g|--get) mode="get"; application="$2"; shift 2 ;;

		--) shift; break ;;
		*)
			printf '%s\n' "Error while parsing CLI options" 1>&2
			flag_h=1
			;;
	esac
done

HELP="\
Usage: desknamer [OPTIONS]

desknamer.sh monitors your open desktops and renames them according to what's inside.

optional args:
  -c, --config FILE       path to alternate configuration file
  -n, --norecursive       don't inspect windows recursively
  -M \"MONITOR [MONITOR2]...\"
                          specify monitor names or IDs to ignore
  -D \"DESKTOP [DESKTOP2]...\"
                          specify desktop names or IDs to ignore
  -l, --list-applications  print all applications found on your machine
  -L, --list-categories   print all categories found on your machine
  -s, --search PROGRAM    find .desktop files matching *program*.desktop
  -g, --get PROGRAM       get categories for given program
  -v, --verbose           make output more verbose
  -h, --help              show help"

# convert {monitor,desktop} names to ids
IFS=' '
for monitor in $monitorBlacklistIn; do
	found="$(bspc query -m "$monitor" -M) "
	[ $? -eq 0 ] && monitorBlacklist+="$found"
done
for desktop in $desktopBlacklistIn; do
	found="$(bspc query -d "$desktop" -D) "
	[ $? -eq 0 ] && desktopBlacklist+="$found"
done

if ((flag_h)); then
	printf '%s\n' "$HELP"
	exit 0
fi

if [ ! -e "$configFile" ]; then
	echo "error: config file specified does not exist: $configFile"
	exit 1
fi
config="$(cat "$configFile")"

case "$mode" in
	list-applications) getAllApplications ;;
	list-categories) getAllCategories ;;
	monitor) monitor ;;
	search) find -L /usr/share/applications /usr/local/share/applications ~/.local/share/applications -iname *"$application"*.desktop 2>/dev/null ;;
	get)
		getCategory "$application"
		echo "${desktopCategories[@]}"
		;;
esac
