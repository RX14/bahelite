# Should be sourced.

#  bahelite_colours.sh
#  Defines variables, that will contain colour setting combinations.
#  They can be used with echo -e, for example.

# Require bahelite.sh to be sourced first.
[ -v BAHELITE_VERSION ] || {
	echo 'Must be sourced from bahelite.sh.' >&2
	return 5
}

# Avoid sourcing twice
[ -v BAHELITE_MODULE_COLOURS_VER ] && return 0
#  Declaring presence of this module for other modules.
BAHELITE_MODULE_COLOURS_VER='1.0'


 # Colours for messages.
#  If you don’t use single-letter variables, better use them for colours.
#
__bk='\e[30m'     # black
__r='\e[31m'    # red
__g='\e[32m'    # green
__y='\e[33m'    # yellow
__bl='\e[34m'    # blue
__ma='\e[35m'    # magenta
__cy='\e[36m'    # cyan
__ma='\e[37m'    # white

__s='\e[0m'     # stop
__b='\e[1m'     # bright/bold.
__dim='\e[2m'     # dim.
__blink='\e[3m'     # blink (usually disabled).
__u='\e[4m'     # underlined
__inv='\e[7m'     # inverted fg and bg
__hid='\e[8m'     # hidden

__rb='\e[21m'   # reset bold/bright
__d='\e[39m'    # default fg

info_colour=$__g
warn_colour=$__y
err_colour=$__r

return 0