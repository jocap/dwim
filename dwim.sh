#!/bin/sh

# dwim (do what i mean) is my own plan9-like plumber

err() { echo "$@" 1>&2; exit 1; }
usage="$0 phrase"

[ $# -gt 1 ] && err "$usage"
[ $# -eq 1 ] && p=$1 || p=$(xsel -o)
[ -z "$p" ] && err "$usage"

[ -z "$OPENER" ] && OPENER=u

case "$p" in
*:*)
	file=${p%%:*}
	line=${p#*:}; line=${line%:}

	dir=
	case "$file" in
	/*) ;;
	~*) ;;
	*)
		dir=$(xtitle)/
		[ ! -d "$dir" ] && err "couldn't retrieve directory"
		;;
	esac

	exec "$OPENER" "$EDITOR" -c ":$line" "$dir$file"
	;;
/*)
	exec "$OPENER" "$EDITOR" "${p%:}"
	;;
~*)
	exec "$OPENER" "$EDITOR" "${p%:}"
	;;
esac

err "no handler matched"
