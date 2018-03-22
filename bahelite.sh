# Should be sourced.

#  bahelite.sh
#  BAsh HElper LIbrary – To Everyone!
#  ――――――――――――――――――――――――――――――――――
#  deterenkelt © 2018
#  https://github.com/deterenkelt/Bahelite
#
#  This work is based on the Bash Helper Library for Large Scripts,
#  that I’ve been initially developing for Lifestream LLC in 2016. The old
#  code of BHLLS can be found at https://github.com/deterenkelt/bhlls.

#  This program is free software; you can redistribute it and/or modify it
#  under the terms of the GNU General Public License as published
#  by the Free Software Foundation; either version 3 of the License,
#  or (at your option) any later version.
#
#  This program is distributed in the hope that it will be useful,
#  but without any warranty; without even the implied warranty
#  of merchantability or fitness for a particular purpose.
#  See the GNU General Public License for more details.


#  Bahelite doesn’t enable or disable any shell options, leaving it
#  to the programmer to set the appropriate ones. Bahelite will only tempo-
#  rarely enable or disable them as needed for its internal functions.

 # bash >= 4.3 for nameref.
#  It’s better to use nameref than eval, where possible.
#
[ ${BASH_VERSINFO[0]:-0} -eq 4 ] &&
[ ${BASH_VERSINFO[1]:-0} -le 2 ] ||
[ ${BASH_VERSINFO[0]:-0} -le 3 ] && {
	# We use
	echo -e "Bahelite error: bash v4.3 or higher required." >&2
	# so it would work for both sourced and executed scripts
	return 3 2>/dev/null ||	exit 3
}

 # Scripts usually shouldn’t be sourced. And so that your main script wouldn’t
#  be sourced by an accident, Bahelite checks, that the main script is called
#  as an executable. Set BAHELITE_LET_MAIN_SCRIPT_BE_SOURCED to skip this.
#
[ -v BAHELITE_LET_MAIN_SCRIPT_BE_SOURCED ] || {
	[ "${BASH_SOURCE[-1]}" != "$0" ] && {
		echo -e "${BASH_SOURCE[-1]} shouldn’t be sourced." >&2
		return 4
	}
}

BAHELITE_VERSION="2.0"
#  $0 == -bash if the script is sourced.
[ -f "$0" ] && {
	MYNAME=${0##*/}
	MYPATH=$(realpath "$0")
	MYDIR=${MYPATH%/*}
	BAHELITE_DIR=${BASH_SOURCE[0]%/*}  # The directory of this file.
}

CMDLINE="$0 $@"
ARGS=("$@")
TERM_COLS=$(tput cols)
TERM_LINES=$(tput lines)
TMPDIR=$(mktemp -d)
#
#  This is a dummy. Call start_log from bahelite_logging.sh
#  to turn on proper logging.
LOG=/dev/null


 # By default Bahelite turns off xtrace for its internal functions.
#  Call “unset BAHELITE_HIDE_FROM_XTRACE” after sourcing bahelite.sh
#  to view full xtrace output.
#
BAHELITE_HIDE_FROM_XTRACE=t

 # To turn off xtrace (set -x) output during the execution
#  of Bahelite own functions.
#
xtrace_off() {
	[ -v BAHELITE_HIDE_FROM_XTRACE  -a  -o xtrace ] && {
		set +x
		declare -g BAHELITE_BRING_BACK_XTRACE=t
	}
	return 0
}
xtrace_on() {
	[ -v BAHELITE_BRING_BACK_XTRACE ] && {
		unset BAHELITE_BRING_BACK_XTRACE
		set -x
	}
	return 0
}

 # To turn off errexit (set -e) and disable trap on ERR temporarily.
#
errexit_off() {
	[ -o errexit ] && {
		set +e
		# traponerr is set by bahelite_error_handling.sh,
		# which is an optional module.
		[ "$(type -t traponerr)" = 'function' ] && traponerr unset
		declare -g BAHELITE_BRING_BACK_ERREXIT=t
	}
	return 0
}
errexit_on() {
	[ -v BAHELITE_BRING_BACK_ERREXIT ] && {
		unset BAHELITE_BRING_BACK_ERREXIT
		set -e
		[ "$(type -t traponerr)" = 'function' ] && traponerr set
	}
	return 0
}

 # To turn off noglob (set -f) temporarily.
#  This comes handy when shell needs to use globbing like for “ls *.sh”.
#
noglob_off() {
	[ -o noglob ] && {
		set +f
		declare -g BAHELITE_BRING_BACK_NOGLOB=t
	}
	return 0
}
noglob_on() {
	[ -v BAHELITE_BRING_BACK_NOGLOB ] && {
		unset BAHELITE_BRING_BACK_NOGLOB
		set -f
	}
	return 0
}

noglob_off
for bahelite_module in "$BAHELITE_DIR"/bahelite_*.sh; do
	. "$bahelite_module" || return 5
done
noglob_on

[ -v BAHELITE_MODULE_MESSAGES_VER ] || {
	echo "Bahelite needs module messages, but it wasn’t sourced." >&2
	return 5
}

#  List of utilities the lack of which must trigger an error.
required_utils=(
	getopt
	grep
	sed
)

 # Call this function in your script after extending the array above.
#
check_required_utils() {
	local missing_utils util
	for util in ${required_utils[@]}; do
		which $util &>/dev/null || { missing_utils=t; iwarn  no util; }
	done
	[ -v missing_utils ] && return 5
	return 0
}

 # It’s a good idea to extend required_utils list in your script
#  and then call check_required_utils:
#      required_utils+=( bc )
#      check_required_utils
#
check_required_utils


 # Bahelite requires util-linux >= 2.20
#
read -d '' major minor  < <(  \
	getopt -V \
	| sed -rn 's/^[^0-9]+([0-9]+)\.?([0-9]+)?.*/\1\n\2/p'; echo -e '\0'
)
[[ "$major" =~ ^[0-9]+$  &&  "$minor" =~ ^[0-9]+$ ]] && [ $major -ge 2 ] \
	&& ( [ $major -gt 2 ] || [ $major -eq 2  -a  $minor -ge 20 ] ) \
	|| err old_utillinux
unset major minor

return 0