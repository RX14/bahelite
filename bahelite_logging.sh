# Should be sourced.

#  bahelite_logging.sh
#  Organises logging and maintains logs in a separate folder.
#  deterenkelt © 2018

# Require bahelite.sh to be sourced first.
[ -v BAHELITE_VERSION ] || {
	echo 'Must be sourced from bahelite.sh.' >&2
	return 5
}

# Avoid sourcing twice
[ -v BAHELITE_MODULE_LOGGING_VER ] && return 0
#  Declaring presence of this module for other modules.
BAHELITE_MODULE_LOGGING_VER='1.1.1'
required_utils+=(date mktemp)


 # Call this function to start logging.
#
start_log() {
	xtrace_off && trap xtrace_on RETURN
	local arg
	LOGDIR="$MYDIR/logs"
	[ -d "$LOGDIR" -a -w "$LOGDIR" ] || {
		mkdir "$LOGDIR" &>/dev/null || {
			LOGDIR="$(mktemp -d)/logs"
			mkdir "$LOGDIR"
		}
	}
	LOG="$LOGDIR/${MYNAME%.sh}_$(date +%Y-%m-%d_%H:%M:%S).log"
	# Removing old logs, keeping maximum of $LOG_KEEP_COUNT of recent logs.
	cd "$LOGDIR"
	noglob_off
	ls -r "${MYNAME%.sh}_"* \
	        | tail -n+$((${BAHELITE_LOG_MAX_COUNT:=5})) \
	        | xargs rm -v &>/dev/null || :
	noglob_on
	cd - >/dev/null
	echo "Log started at $(date)." >"$LOG"
	echo "Command line: $CMDLINE" >>"$LOG"
	for ((i=0; i<${#ARGS[@]}; i++)) do
		echo "ARGS[$i] = ${ARGS[i]}" >>"$LOG"
	done
	exec &> >(tee -a $LOG)
	return 0
}

show_path_to_log() {
	xtrace_off && trap xtrace_on RETURN
	if [ -v BAHELITE_MODULE_MESSAGES_VER ]; then
		info "Log is written to
		      $LOG"
	else
		cat <<-EOF
		Log is written to
		$LOG
		EOF
	fi
	return 0
}

 # Returns an absolute path to the last modified log in $LOGDIR.
#  [$1] – log name prefix, if not set, equal to $MYNAME
#         without .sh at the end (caller script’s own log).
#
get_last_log() {
	xtrace_off && trap xtrace_on RETURN
	local logname="${1:-}" last_log
	[ "$logname" ] || logname=${MYNAME%.sh}
	pushd "$LOGDIR" >/dev/null
	noglob_off
	last_log=$(ls -tr ${logname}_* | tail -n1)
	noglob_on
	[ -f "$last_log" ] || return 1
	popd >/dev/null
	echo "$LOGDIR/$last_log"
	return 0
}


return 0