#!/bin/sh
set -eu

normalize_bool() {
	name=$1
	value=$2

	case "$value" in
		[Tt][Rr][Uu][Ee])
			printf '%s\n' true
			;;
		[Ff][Aa][Ll][Ss][Ee])
			printf '%s\n' false
			;;
		*)
			printf 'error: input %s must be true or false, got %s\n' "$name" "$value" >&2
			exit 2
			;;
	esac
}

input_paths=${INPUT_PATHS:-}
input_config_file=${INPUT_CONFIG_FILE:-}
input_ignore=${INPUT_IGNORE:-}
input_shellcheck=${INPUT_SHELLCHECK-shellcheck}
input_pyflakes=${INPUT_PYFLAKES-pyflakes}
input_format=${INPUT_FORMAT:-}
input_no_color=${INPUT_NO_COLOR:-true}
input_oneline=${INPUT_ONELINE:-false}

no_color=$(normalize_bool no-color "$input_no_color")
oneline=$(normalize_bool oneline "$input_oneline")
cr=$(printf '\r')
tmp_dir=${RUNNER_TEMP:-/tmp}/actionlint-action.$$

mkdir "$tmp_dir"
trap 'rm -rf "$tmp_dir"' EXIT HUP INT TERM
printf '%s\n' "$input_ignore" >"$tmp_dir/ignore"
printf '%s\n' "$input_paths" >"$tmp_dir/paths"

set --

if [ -n "$input_config_file" ]; then
	set -- "$@" -config-file "$input_config_file"
fi

while IFS= read -r line || [ -n "$line" ]; do
	line=${line%"$cr"}
	if [ -n "$line" ]; then
		set -- "$@" -ignore "$line"
	fi
done <"$tmp_dir/ignore"

set -- "$@" "-shellcheck=$input_shellcheck"
set -- "$@" "-pyflakes=$input_pyflakes"

if [ -n "$input_format" ]; then
	set -- "$@" -format "$input_format"
fi

if [ "$no_color" = true ]; then
	set -- "$@" -no-color
fi

if [ "$oneline" = true ]; then
	set -- "$@" -oneline
fi

while IFS= read -r line || [ -n "$line" ]; do
	line=${line%"$cr"}
	if [ -n "$line" ]; then
		set -- "$@" "$line"
	fi
done <"$tmp_dir/paths"

exec actionlint "$@"
