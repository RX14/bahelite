# Should be sourced.

#  bahelite_menus.sh
#  Function(s) for drawing menus.
#  deterenkelt © 2018

# The benefits of using these functions over “read” and “select”:
# - with read and select you type a certain string as teh answer…
#   …and the user often mistypes it
#   …and you must place strict checking on what is typed
#   …which blows your code, so you need a helper function anyway.
#   But with Bahelite this function is ready for use and the moves
#   are reduced to keyboard arrows – one can’t answer wrong, when
#   arrows highlight one string or the other (“Yes” or “No” for example)
# - the menu changes appearance depending on the number of elements
#   to choose from:
#   1)  Pick server: "Server 1" < "Server 2"    (server 1 is highlighted)
#       <right arrow pressed>
#       Pick server: "Server 1" > "Server 2"    (now server 2 is highlighted)
#   2) Choose letter: <| S |>                   ()
#
#
#   …

# Require bahelite.sh to be sourced first.
[ -v BAHELITE_VERSION ] || {
	echo 'Must be sourced from bahelite.sh.' >&2
	return 5
}
. "$BAHELITE_DIR/bahelite_messages.sh" || return 5

# Avoid sourcing twice
[ -v BAHELITE_MODULE_MENUS_VER ] && return 0
#  Declaring presence of this module for other modules.
BAHELITE_MODULE_MENUS_VER='1.0'

# It is *highly* recommended to use “set -eE” in whatever script
# you’re going to source it from.



 # To clear screen each time menu() redraws its output.
#  Clearing helps to focus, while leaving old screens
#  allows to check the console output before menu() was called.
#
#BAHELITE_MENU_CLEAR_SCREEN=t


 # Shows a menu, where a selection is made with only arrows on keyboard.
#
#  TAKES
#      $1 – prompt
#      $2..n – options to choose from. The first one become the default.
#                If the default option is not the first one, it should be
#                given _with underscores_.
#              If the user must set values to options, vertical type of menu
#                allows to show values aside of the option names.
#                To pass a value for an option, add it after the option name
#                and separate from it with “---”.
#                If the option name has underscores marking it as default,
#                they surround only the option name, as usual.
#  SETS
#      CHOSEN – selected option.
#
carousel() { menu "$@"; }
menu() {
	xtrace_off
	local mode choice_is_confirmed bivariant prompt options=() optvals=() \
	      option rest arrow_up=$'\e[A' arrow_right=$'\e[C' \
	      arrow_down=$'\e[B' arrow_left=$'\e[D' clear_line=$'\r\e[K' \
	      left=t right=t
	# For an X terminal or TTY with jfbterm
	local cool_graphic=( '‘' '’' '…'   '–'   '│' '─' '∨' '∧' '◆' )
	# For a regular TTY
	local poor_graphic=( "'" "'" '...' '-'   '|' '-' 'v' '^' '+' )
	graphic=("${cool_graphic[@]}")
	local oq=${graphic[0]}  # opening quote
	local cq=${graphic[1]}  # closing quote
	local el=${graphic[2]}  # ellipsis
	local da=${graphic[3]}  # en dash
	local vb=${graphic[4]}  # vertical bar
	local hb=${graphic[5]}  # horizontal bar
	local ad=${graphic[6]}  # arrow down
	local au=${graphic[7]}  # arrow up
	local di=${graphic[8]}  # diamond
	chosen_idx=0
	[ "${OVERRIDE_DEFAULT:-}" ] && chosen_idx="$OVERRIDE_DEFAULT"
	[ "${FUNCNAME[1]}" = carousel ] && mode=carousel
	prompt="${1:-}" && shift
	while option="${1:-}"; [ "$option" ]; do
		optvals+=("${option#*---}")
		option=${option%---*}
		[ "${option/_*_}" ] || {
			# Option specified _like this_ is to be selected by default.
			[ "$OVERRIDE_DEFAULT" ] || chosen_idx=${#options[@]}
			# Erasing underscores.
			option=${option#_} option=${option%_}
		}
		options+=("${option}")
		shift
	done
	[ ${#options[@]} -eq 2 ] && {
		mode=bivariant
		[ $chosen_idx -eq 0 ] && right= || left=
	}
	[ -v NON_INTERACTIVE ] && {
		CHOSEN=${options[chosen_idx]}
		return
	}
	until [ -v choice_is_confirmed ]; do
		[ -v BAHELITE_MENU_CLEAR_SCREEN ] && clear
		case "$mode" in
			bivariant)
				echo -en "$prompt ${left:+$__g}${options[0]}${left:+$__s <} ${right:+> $__g}${options[1]}${right:+$__s} "
				;;
			carousel)
				[ $chosen_idx -eq 0 ] && left=
				[ $chosen_idx -eq $(( ${#options[@]} -1 )) ] && right=
				echo -en "$prompt ${left:+$__g}<|$s ${options[chosen_idx]} $__s${right:+$__g}|>$__s "
				;;
			*)
				echo -e "\n\n/${hb}${hb}${hb} $prompt ${hb}${hb}${hb}${hb}${hb}${hb}"
				for ((i=0; i<${#options[@]}; i++)); do
					[ $i -eq $chosen_idx ] && pre="$__g${di}$__s" || {
						[ $i -eq 0 ] && pre="$__g${au}$__s" || {
							[ $i -eq $(( ${#options[@]} -1 )) ] && pre="$__g${ad}$__s" || pre="${vb}"
						}
					}
					eval echo -e \"$pre ${options[i]}\"\$\{${optvals[i]}:+:\ \$${optvals[i]}\}
				done
				echo -en "${__g}Up$s/${__g}Dn$__s: select parameter, ${__g}Enter$__s: confirm. "
				;;
			esac
		read -sn1
		[ "$REPLY" = $'\e' ] && read -sn2 rest && REPLY+="$rest"
		if [ "$REPLY" ]; then
			case "$REPLY" in
				"$arrow_left"|"$arrow_down"|',')
					case "$mode" in
						bivariant) left=t right= chosen_idx=0;;
						carousel)
							[ $chosen_idx -eq 0 ] && left= || {
								((chosen_index--, 1))
								right=t
							}
							;;
						*)
							[ $chosen_idx -eq $(( ${#options[@]} -1)) ] \
								|| ((chosen_idx++, 1))
							;;
					esac
					;;
				"$arrow_right"|"$arrow_up"|'.')
					case "$mode" in
						bivariant) left= right=t chosen_idx=1;;
						carousel)
							if [ $chosen_idx -eq $(( ${#options[@]}-1)) ]; then
								right=
							else
								((chosen_index++, 1))
								left=t
							fi
							;;
						*)
							[ $chosen_idx -eq 0 ] || ((chosen_idx--, 1))
							;;
					esac
					;;
			esac
			[[ "$mode" =~ ^(bivariant|carousel)$ ]] && echo -en "$clear_line"
		else
			echo
			choice_is_confirmed=t
		fi
	done
	CHOSEN=${options[chosen_idx]}
	xtrace_on
	return 0
}

return 0