# Should be sourced.

#  bahelite_rcfile.sh
#  Functions to source an RC file and verify, that its version is compatible.

# Require bahelite.sh to be sourced first.
[ -v BAHELITE_VERSION ] || {
	echo 'Must be sourced from bahelite.sh.' >&2
	return 5
}
. "$BAHELITE_DIR/bahelite_messages.sh" || return 5
. "$BAHELITE_DIR/bahelite_versioning.sh" || return 5

# Avoid sourcing twice
[ -v BAHELITE_MODULE_RCFILE_VER ] && return 0
#  Declaring presence of this module for other modules.
BAHELITE_MODULE_COLOURS_VER='1.0'


 # Reads an RC file and verifies, that it has a compatible version.
#  If version is lower, than minimum compatible version, throws an error.
#  $1 – path to RC file.
#  $2 – minimum compatible version for the RC file.
#  $3 – example RC file, that should silently be copied and used,
#       if there would be no RC file (it’s the first time program starts).
#
read_rc_file() {
	xtrace_off && trap xtrace_on RETURN
	local rcfile="$1" rcfile_min_ver="$2" example_rcfile="$3" \
	      which_is_newer rc_file_ver
	if [ -r "$rcfile" ]; then
		#  Verifying RC file version
		rcfile_ver=$( \
			sed -rn "1 s/# ${rcfile##*/} v([0-9\.]+)\s*$/\1/p" "$rcfile" )
		which_is_newer=$(compare_versions "$rcfile_ver" "$rcfile_min_ver")
		[ "$which_is_newer" = "$rcfile_min_ver" ] \
			&& err 'Please COPY and EDIT the new RC file!'
		. "$rcfile"
	else
		if [ -r "$example_rcfile" ]; then
			cp "$example_rcfile" "$rcfile" || err "Couldn’t create RC file!"
			. "$rcfile"
		else
			err "No RC file or example RC file was found!"
		fi
	fi
	return 0
}


return 0