# Should be sourced.

#  bahelite_misc.sh
#  Miscellaneous helper functions.
#  deterenkelt © 2018

# Require bahelite.sh to be sourced first.
[ -v BAHELITE_VERSION ] || {
	echo 'Must be sourced from bahelite.sh.' >&2
	return 5
}

# Avoid sourcing twice
[ -v BAHELITE_MODULE_MISC_VER ] && return 0
#  Declaring presence of this module for other modules.
BAHELITE_MODULE_MISC_VER='1.0'


# It is *highly* recommended to use “set -eE” in whatever script
# you’re going to source it from.


if_true() {
	xtrace_off
	declare -n var=$1
	if [[ "$var" =~ ^(y|Y|[Yy]es|1|t|T|[Tt]rue|[Oo]n|[Ee]nable[d])$ ]]; then
		xtrace_on
		return 0
	elif [[ "$var" =~ ^(n|N|[Nn]o|0|f|F|[Ff]alse|[Oo]ff|[Dd]isable[d])$ ]]; then
		xtrace_on
		return 1
	else
		if [ -v BAHELITE_MODULE_MESSAGES_VER ]; then
			err "Variable “$1” must have a boolean value (0/1, on/off, yes/no),
			     but it has “$var”."
		else
			cat <<-EOF >&2
			Variable “$1” must have a boolean value (0/1, on/off, yes/no),
			but it has “$var”.
			EOF
		fi
	fi
	xtrace_on
	return 0
}


 # Dumps values of variables to stdout and to the log
#    $1..n – variable names
#
dumpvar() {
	xtrace_off
	local var
	for var in "$@"; do
		msg "$(declare -p $var)"
	done
	xtrace_on
	return 0
}

return 0