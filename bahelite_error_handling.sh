# Should be sourced.

#  bahelite_error_handling.sh
#  Places traps on SIGERR and EXIT (also when the program is interrupted
#    in various ways). On error prints call stack trace, the failed command
#    and its return code, all highlighted distinctively.
#  Both traps on error and exit call user’s subroutines, if they are defined.
#  deterenkelt © 2018

# Require bahelite.sh to be sourced first.
[ -v BAHELITE_VERSION ] || {
	echo 'Must be sourced from bahelite.sh.' >&2
	return 5
}
. "$BAHELITE_DIR/bahelite_messages.sh" || return 5

# Avoid sourcing twice
[ -v BAHELITE_MODULE_ERROR_HANDLING_VER ] && return 0
#  Declaring presence of this module for other modules.
BAHELITE_MODULE_ERROR_HANDLING_VER='1.0'


bahelite_on_exit() {
	# Run user’s on_exit().
	[ "$(type -t on_exit)" = 'function' ] && on_exit
	[ -d "$TMPDIR" ] && rm -rf "$TMPDIR"
	# Not actually necessary as it’s a trap on exit,
	# the return code is frozen.
	return 0
}
trap 'bahelite_on_exit' EXIT TERM INT QUIT KILL

bahelite_show_error() {
	local line=$1 failed_command_code=$2 i
	# Since an error happened, all the following output is supposed
	# to go to stderr.
	exec 2>&1
	# Run user’s on_error().
	[ "$(type -t on_error)" = 'function' ] && on_error
	xtrace_off
	echo -en "${__b}--- Call stack "
	for ((i=0; i<TERM_COLS-15; i++)); do echo -n '-'; done
	echo -e "${__s}"
	for ((f=${#FUNCNAME[@]}-1; f>0; f--)); do
		echo -en "${__b}${FUNCNAME[f]}${__s}, "
		echo -e  "line ${BASH_LINENO[f-1]} in ${BASH_SOURCE[f]}"
	done
	echo -en "Command: "
	echo -en  "${__b}$line${__s} ${__b}${__r}(exit code: $failed_command_code)${__s}." \
	    | fold -w $((TERM_COLS-9)) -s \
	    | sed -r '1 !s/^/         /g'
	echo -e ""
	bahelite_notify_send "Bash error. See console." error
	xtrace_on
	[ "$LOG" = /dev/null ] && return 0
	info "Log is written to
	      $LOG"
	echo -n "$LOG" | xclip ||:
	return 0
}

 # During the debug, it sometimes needed to disable errexit (set -e)
#  temporarily. However disabling errexit (with set +e) doesn’t remove
#  the associated trap.
#
traponerr() {
	xtrace_off
	case "$1" in
		set)
			#  Note the single quotes – to prevent early expansion
			trap 'bahelite_show_error "$BASH_COMMAND" "$?"' ERR
			;;
		unset)
			#  trap '' ERR will ignore the signal.
			#  trap - ERR will reset command to 'bahelite_show_error "$BASH_SOURCE…'
			trap '' ERR
			;;
	esac
	xtrace_on
	return 0
}
traponerr set

return 0