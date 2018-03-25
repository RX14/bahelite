# Should be sourced.

#  bahelite_messages.sh
#  Provides messages for console and desktop.
#  deterenkelt © 2018

# Require bahelite.sh to be sourced first.
[ -v BAHELITE_VERSION ] || {
	echo 'Must be sourced from bahelite.sh.' >&2
	return 5
}
. "$BAHELITE_DIR/bahelite_colours.sh" || return 5

# Avoid sourcing twice
[ -v BAHELITE_MODULE_MESSAGES_VER ] && return 0
#  Declaring presence of this module for other modules.
BAHELITE_MODULE_MESSAGES_VER='1.1'

# Bahelite offers keyword-based messages, which allows
# for creation of localised programs.

 # List of informational messages
#
declare -A BAHELITE_INFO_MESSAGES=()

 # List of warning messages
#
declare -A BAHELITE_WARNING_MESSAGES=(
	[no such msg]='Internal: No such message: ‘$failed_message’.'
	[no util]='“$util” is required but wasn’t found.'
)

 # List of error messages
#  Keys are used as parameters to err() and values are printed via msg().
#  Keys may contain spaces – e.g. ‘my key’. Passing them to err()
#  doesn’t require quoting and the number of spaces is not important.
#  You can add your messages just by adding elements to this array,
#  and perform localisation just by redefining it after sourcing this file!
#
declare -A BAHELITE_ERROR_MESSAGES=(
	[just quit]='Quitting.'
	[old utillinux]='Need util-linux-2.20 or higher.'
	[missing deps]='Dependencies are not satisfied.'
)


 # Desktop notifications
#
#  To send a notification to both console and desktop, main script should
#  call info-ns(), warn-ns() or err() function. As err() always ends the
#  program, its messages can’t be of lower importance. Thus they are always
#  sent to desktop (if only NO_DESKTOP_NOTIFICATIONS is set).
#
 # If set, disables all desktop notifications.
#  All message functions will print only to console.
#  By default it is unset, and notifications are shown.
#
#NO_DESKTOP_NOTIFICATIONS=t

 # Shows a desktop notification
#  $1 – message.
#  $2 – icon type: empty, “information”, “warning” or “error”.
#
bahelite_notify_send() {
	xtrace_off
	[ -v NO_DESKTOP_NOTIFICATIONS ] && return 0
	local msg="$1" icon="$2" duration
	case "$icon" in
		warning|error) duration=5000;;  # warning, error: 5s
		*) duration=3000;;  # info: 3s
	esac
	# The hint is for the message to not pile in the stack – it is limited.
	# ||:  is for running safely under set -e.
	which notify-send &>/dev/null \
		|| warn 'Cannot show error message on desktop: notify-send not found.'
	notify-send --hint int:transient:1 -t $duration \
	            "${MY_MSG_TITLE:-$MYNAME}" "$msg" \
	            ${icon:+--icon=dialog-$icon}|| :
	xtrace_on
	return 0
}

 # Message Indentation Level.
#  Each time you go deeper one level, call milinc – and the messages
#  will be indented one level more. mildec decreases one level.
#  See also: milset, mildrop.
#
MI_LEVEL=0  # Debug indentation level. Default is 0.
MI_SPACENUM=4  # Number of spaces to use per indentation level
MI_CHARS=''  # Accumulates spaces for one portion of indentation
for ((i=0; i<MI_SPACENUM; i++)); do MI_CHARS+=' '; done

mi_assemble() {
	local z
	MI=
	for ((z=0; z<MI_LEVEL; z++)); do MI+=$MI_CHARS; done
	# Without this, multiline messages that occur on MI_LEVEL=0,
	# when $MI is empty, won’t be indented properly. ‘* ’, remember?
	[ "$MI" ] || MI='  '
	return 0
}
mi_assemble

 # Increments the indentation level.
#  [$1] — number of times to increment $MI_LEVEL.
#         The default is to increment by 1.
#
milinc() {
	xtrace_off
	local count=${1:-1} z mi_as_result
	for ((z=0; z<count; z++)); do ((MI_LEVEL++, 1)); done
	mi_assemble; mi_as_result=$?
	xtrace_on
	return $mi_as_result
}

 # Decrements the indentation level.
#  [$1] — number of times to decrement $MI_LEVEL.
#  The default is to decrement by 1.
#
mildec() {
	xtrace_off
	local count=${1:-1} z mi_as_result
	if [ $MI_LEVEL -eq 0 ]; then
		warn "No need to decrease indentation, it’s on the minimum."
	else
		for ((z=0; z<count; z++)); do ((MI_LEVEL--, 1)); done
		mi_assemble; mi_as_result=$?
	fi
	xtrace_on
	return $mi_as_result
}

 # Sets the indentation level to a specified number.
#  $1 – desired indentation level, 0..9999.
#
milset () {
	xtrace_off
	local _mi_level=$1 mi_as_result
	[[ "$_mi_level" =~ ^[0-9]{1,4}$ ]] || {
		warn "Indentation level should be an integer between 0 and 9999."
		return 0
	}
	MI_LEVEL=$_mi_level
	mi_assemble; mi_as_result=$?
	xtrace_on
	return $mi_as_result
}

 # Removes any indentation.
#
mildrop() {
	xtrace_off
	MI_LEVEL=0
	mi_assemble; local mi_as_result=$?
	xtrace_on
	return $mi_as_result
}

 # Shows an info message.
#  Features asterisk, automatic indentation with mil*, keeps lines
#  $1 — a message or a key of an item in the corresponding array containing
#       the messages. Depends on whether $MSG_USE_ARRAYS is set (see above).
#
info() {
	xtrace_off
	msg "$@"
	xtrace_on
}

 # Same as info(), but omits the ending newline, like “echo -n” does.
#  This allows to print whatever with just simple “echo” later.
#
infon() {
	xtrace_off
	nonl=t msg "$@"
	xtrace_on
}

 # Like info(), but has a higher rank than usual info(),
#  which allows its message to be also shown on desktop.
#  $1 – a message to be shown both in console and on desktop.
#
info-ns() {
	xtrace_off
	msg "$@"
	xtrace_on
}

 # Shows an info message and waits for the given command to finish,
#  to print its result, and if it’s not zero, print the output
#  of that command.
#
#  $1 – a message. Something like ‘Starting up servicename… ’
#  $2 – a command.
#  $3 – any string to force the output even if the result is [OK].
#       Handy for faulty programs that return 0 even on error.
#
infow() {
	xtrace_off
	local message=$1 command=$2 force_output="$3" outp result
	msg "$message"
	outp=$( bash -c "$command" 2>&1 )
	result=$?
	[ $result -eq 0 ] \
		&& printf "${__b}%s${__g}%s${__s}${__b}%s${__s}\n"  ' [ ' OK ' ]' \
		|| printf "${__b}%s${__r}%s${__s}${__b}%s${__s}\n"  ' [ ' Fail ' ]'
	[ $result -ne 0 -o "$force_output" ] && {
		milinc
		info "Here is the output of ‘$command’:"
		plainmsg "$outp"
		mildec
	}
	xtrace_on
}

 # Like info, but the output goes to stderr. Dimmed yellow asterisk.
#
warn() {
	xtrace_off
	msg "$@"
	xtrace_on
}

 # Like warn(), but has a higher rank than usual info(),
#  which allows its message to be also shown on desktop.
#  $1 – a message to be shown both in console and on desktop.
#
warn-ns() {
	xtrace_off
	msg "$@"
	xtrace_on
}

 # Shows message and then calls exit. Red asterisk.
#  If MSG_USE_ARRAYS is not set, the default exit code is 5.
#
err() {
	xtrace_off
	msg "$@"
	xtrace_on
}

 # Same as err(), but prints the whole line in red.
#
errw() {
	xtrace_off
	msg "$@"
	xtrace_on
}

 # For Bahelite internal warnings and errors.
#
iwarn() {
	xtrace_off
	msg "$@"
	xtrace_on
}
ierr() {
	xtrace_off
	msg "$@"
	xtrace_on
}

 # For internal use in alias functions, such as infow(), where we cannot use
#  msg() as is, because FUNCNAME[1] will be set to the name of that alias
#  function. Hence, to avoid additions and get a plain msg(), we must call it
#  from another function, for which no additions are specified in msg().
#
plainmsg() {
	xtrace_off
	msg "$@"
	xtrace_on
}


 # Shows an info, a warning or an error message
#  on console and optionally, on desktop too.
#  $1 — a text message or, if MSG_USE_ARRAYS is set, a key from
#       - INFO_MESSAGES, if called as info*();
#       - WARNING_MESSAGES,  if called as warn*();
#       - ERROR_MESSAGES, if called as err*().
#       That key may contain spaces, and the number of spaces between words
#       in the key is not important, i.e.
#         $ warn "no needed file found"
#         $ warn  no needed file found
#       and
#         $ warn  no   needed  file     found
#       will use the same item in the WARNING_MESSAGES array.
#  RETURNS:
#    If called as an err* function, then quits the script
#    with exit/return code 5 or 5–∞, if ERROR_CODES is set.
#    Returns zero otherwise.
#
msg() {
	local msgtype=msg  c=  cs=$__s  nonl  asterisk='  '  message \
	      redir  code=5  internal  key  msg_key_exists \
	      notifysend_rank  notifysend_icon
	case "${FUNCNAME[1]}" in
		*info*)  # all *info*
			msgtype=info
			local -n  msg_array=INFO_MESSAGES
			local -n  c=info_colour
			;;&
		info|infon|info-ns)
			asterisk="* ${MSG_ASTERISK_PLUS_WORD:+INFO: }"
			;;&
		info-ns)
			notifysend_rank=1
			notifysend_icon='information'
			;;
		infow)
			asterisk="* ${MSG_ASTERISK_PLUS_WORD:+RUNNING: }"
			nonl=t
			;;
		*warn*)
			msgtype=warn redir='>&2'
			local -n  msg_array=WARNING_MESSAGES
			local -n  c=warn_colour
			asterisk="* ${MSG_ASTERISK_PLUS_WORD:+WARNING: }"
		    ;;&
		warn-ns)
			notifysend_rank=1
			notifysend_icon='warning'
			;;
		*err*)
			msgtype=err redir='>&2'
			local -n  msg_array=ERROR_MESSAGES
			local -n  c=err_colour
			asterisk="* ${MSG_ASTERISK_PLUS_WORD:+ERROR: }"
			notifysend_rank=1
			notifysend_icon='error'
			;;&
		errw)
			asterisk='  '
			unset cs  # print whole line in red, no asterisk.
			;;
		iwarn|ierr|iinfo)
			internal=t
			;;&
		iwarn)
			# For internal messages.
			local -n  msg_array=BAHELITE_WARNING_MESSAGES
			notifysend_rank=1
			notifysend_icon='warning'
			;;
		ierr)
			# For internal messages.
			local -n  msg_array=BAHELITE_ERROR_MESSAGES
			;;
	esac
	[ -v nonl ] && nonl='-n'
	[ -v QUIET ] && redir='>/dev/null'
	[ -v MSG_USE_ARRAYS -o -v internal ] && {
		# What was passed to us is not a message, but a key
		# of a corresponding array.
		#
		# We cannot do
		#     eval [ -v \"$prefix$msg_array[$message]\" ]
		# here, becasue it will only work when $message item does exist,
		# and if it doesn’t, bash will throw an error about wrong syntax.
		# Actually, without nameref it would be hell to do this cycle.
		for key in "${!msg_array[@]}"; do
			[ "$key" = "$*" ] && msg_key_exists=t
		done
		if [ -v msg_key_exists ]; then
			message="${msg_array[$@]}"
		else
			failed_message=$message iwarn no such msg
			# Quit, if the user has called err*() – he most probably
			# intended to quit here.
			[ "$msgtype" = err ] && ierr just quit || return $code
		fi
	}|| message="$*"
	# Removing blank space before message lines.
	# This allows strings to be split across lines and at the same time
	# be well-indented with tabs and/or spaces – indentation will be cut
	# from the output.
	message=$(sed -r 's/^\s*//; s/\n\t/\n/g' <<<"$message")
	# Both fold and fmt use smaller width,
	# if they deal with non-Latin characters.
	if [ -v BAHELITE_FOLD_MESSAGES ]; then
		eval "echo -e ${nonl:-} \"$c$asterisk$cs$message$__s\" \
		      | fold  -w $((TERM_COLS - MI_LEVEL*MI_SPACENUM -2)) -s \
		      | sed -r \"1s/^/${MI#  }/; 1!s/^/$MI/g\" ${redir:-}"
	else
		eval "echo -e ${nonl:-} \"$c$asterisk$cs$message$__s\" \
	          | sed -r \"1s/^/${MI#  }/; 1!s/^/$MI/g\" ${redir:-}"
	fi
	[ ${notifysend_rank:--1} -ge 1 ] && {
		# Stripping colours, that might be placed in the $message by user.
		bahelite_notify_send "$(strip_colours "$message")" ${notifysend_icon:-}
	}
	[ "$msgtype" = err ] && {
		# If this is an error message, we must also quit
		# with a certain exit/return code.
		[ -v MSG_USE_ARRAYS ] && [ ${#ERROR_CODES[@]} -ne 0 ] \
			&& code=${ERROR_CODES[$*]}
		# Bahelite can be used in both sourced and standalone scripts
		# code=5 by default.
		[ -v BAHELITE_USE_RETURN ] && { return $code; :; } || exit $code
	}
	return 0
}

return 0