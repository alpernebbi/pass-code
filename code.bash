#!/usr/bin/env bash

# pass-code, an extension for pass ( https://www.passwordstore.org/ )
# Copyright (C) 2017 Alper Nebi Yasak
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program. If not, see <http://www.gnu.org/licenses/>.

declare -A codec
codec_modified=false

# Decrypt the .passcode file and put it to an associative array so we
# don't need to re-decrpyt it every time we encode/decode something.
code_decrypt() {
	while read -r pair; do
		codec["Dx${pair##*:}"]="${pair%%:*}"
		codec["Ex${pair%%:*}"]="${pair##*:}"
	done <<< "$(cmd_show .passcode)"
}

# Will not print anything if code_decrypt not run or key not in mapping
code_encode() { while read -r dec; do echo "${codec[Dx$dec]}"; done; }
code_decode() { while read -r enc; do echo "${codec[Ex$enc]}"; done; }

# $1 is decoded, $2 is encoded
code_add() {
	codec["Dx$1"]="$2"
	codec["Ex$2"]="$1"
	codec_modified=true
}

code_remove() {
	unset codec["Dx$1"]
	unset codec["Ex$2"]
	codec_modified=true
}

# Generate a random encoded filename and map it to given decoded $1
code_add_random() {
	local dec="$1"
	local enc=""

	until code_is_file "$dec"; do
		read -r -n 16 enc \
			< <(LC_ALL=C tr -dc "0-9a-z" < /dev/urandom)

		if [[ ${#enc} -ne 16 ]]; then
			die "Could not generate a random filename."
		fi

		# Don't break one-to-one mapping
		if [[ -z "${codec[Ex$enc]+x}" ]]; then
			code_add "$dec" "$enc"
		else
			# Don't overload the CPU
			sleep 0.1
		fi
	done
}

# Lists decoded files, assuming encoded hierarchy is flat
code_list_files() {
	cmd_show \
		| tail -n +2 \
		| cut -d ' ' -f 2 \
		| code_decode
}

# Check if file/directory exists in codec
code_is_directory() {
	[[ -n "$1" ]] && (code_list_files | grep -q "^${1%%/}/")
}

code_is_file() {
	[[ -n "$1" && -n "${codec[Dx$1]+x}" ]]
}

# Check if codec is in valid format.
# Only [ExENC]=DEC and [DxDEC]=ENC are allowed.
# One-to-one mapping, so [Dx[ExENC]]=ENC and [Ex[DxDEC]]=DEC.
code_validate() {
	for key in "${!codec[@]}"; do
		if [[ "${key#Ex}" != "${key#Dx}" && (
			"${codec[Dx${codec[$key]}]}" = "${key#Ex}" ||
			"${codec[Ex${codec[$key]}]}" = "${key#Dx}"
		) ]]; then
			continue
		else
			die "pass-code internal mapping is invalid."
		fi
	done
}

# Print ENC:DEC pairs
code_as_colons() {
	for key in "${!codec[@]}"; do
		if [[ -n "${key#Ex}" && "${key#Ex}" != "$key" ]]; then
			echo "${key#Ex}:${codec[$key]}"
		fi
	done | sort -t ':' -k 2
}

# If we have modified the mappings, rewrite the .passcode file and
# put it back into the password-store.
code_encrypt() {
	if [[ "$codec_modified" = false ]]; then
		return
	fi

	code_validate
	code_as_colons \
		| cmd_insert ".passcode" --multiline --force \
		>/dev/null
}

# I'm going to cheat and create an equivalent folder hierarchy,
# and call the actual "tree" on it.
code_format_as_tree() {
	local subfolder="$1"

	# Sets $SECURE_TMPDIR. Don't warn since all files we create
	# are empty anyway.
	tmpdir nowarn
	local fakestore
	fakestore="$(mktemp -d "$SECURE_TMPDIR/fakestore.XXXXXXX")"

	# Input filenames are relative to password store
	while read -r relpath; do
		check_sneaky_paths "$relpath"
		mkdir -p "$(dirname "$fakestore/$relpath")"
		touch "$fakestore/$relpath"
	done

	# "Password Store" or name of the subfolder as the first line
	if [[ -z "$subfolder" ]]; then
		echo "Password Store"
	else
		echo "$subfolder"
	fi

	tree -C -l --noreport "$fakestore/$subfolder" \
		| tail -n +2
}

# Take newline seperated list of files, choose those in path/to/sub/
code_filter_subfolder() {
	local subfolder="$1"
	if [[ -z "$subfolder" ]]; then
		cat
	else
		# Accept "path/to/sub/" and "path/to/sub" as inputs
		grep "^${subfolder%%/}/"
	fi
}

# Encodes all encodable arguments, but leaves others intact.
#     code_encode_args "$@"
#     set -- "${encoded_args[@]}"
declare -a encoded_args
code_encode_args() {
	encoded_args=()

	for arg in "$@"; do
		encoded_args+=("${codec[Dx$arg]-$arg}")
	done
}

# Strip options (i.e. anything that starts with a dash)
#    code_positional_args "$@"
#    set -- "${positional_args[@]}"
declare -a positional_args
code_positional_args() {
	positional_args=()

	for arg in "$@"; do
		if [[ "${arg#-}" = "$arg" ]]; then
			positional_args+=("$arg")
		fi
	done
}

cmd_code_version() {
	cat <<- EOF
	$PROGRAM-code version 0.1.0
	EOF
}

cmd_code_ls() {
	local subfolder="$1"
	check_sneaky_paths "$subfolder"

	code_decrypt
	code_list_files \
		| code_filter_subfolder "$subfolder" \
		| code_format_as_tree "$subfolder"
}

cmd_code_show() {
	code_decrypt
	code_encode_args "$@"
	set -- "${encoded_args[@]}"
	cmd_show "$@"
}

cmd_code_insert() {
	code_decrypt

	# One positional arg, possibly not in codec
	code_positional_args "$@"
	local dec="${positional_args[0]}"
	code_is_file "$dec" || code_add_random "$dec"

	code_encode_args "$@"
	set -- "${encoded_args[@]}"
	cmd_insert "$@"
	code_encrypt
}

cmd_code_edit() {
	code_decrypt

	# One positional arg, maybe not in codec
	code_positional_args "$@"
	local dec="${positional_args[0]}"
	code_is_file "$dec" || code_add_random "$dec"

	code_encode_args "$@"
	set -- "${encoded_args[@]}"
	cmd_edit "$@"
	code_encrypt
}

cmd_code_generate() {
	code_decrypt

	# One (maybe two) positional args, first possibly not in codec
	# Second is a number or empty, irrelevant in both cases
	code_positional_args "$@"
	local dec="${positional_args[0]}"
	code_is_file "$dec" || code_add_random "$dec"

	code_encode_args "$@"
	set -- "${encoded_args[@]}"
	cmd_generate "$@"
	code_encrypt
}

cmd_code_copy_move() {
	code_decrypt

	# Prepended an action in the case statement, take that out
	local action="$1"
	shift

	# Check --force/-f since we have to do conflict handling
	local force=false
	for arg in "$@"; do
		if [[ "$arg" = "--force" || "$arg" = "-f" ]]; then
			force=true
			break
		fi
	done

	# Two positional args, first must be in codec; second may be.
	# Both might exist _both_ as a folder and as a file, since
	# pass uses .gpg suffixes. (i.e. x.gpg and x/ are both x)
	code_positional_args "$@"
	local from="${positional_args[0]}" from_is_dir=false
	local to="${positional_args[1]}" to_is_dir=false

	#  codec   |   a    |   a/   | d? a/ | f a | is_dir |
	# ---------|--------|--------|-------------|--------|
	# {a, a/*} | file   | folder |   y   |  y  |   a/   |
	# {a/*}    | folder | folder |   y   |  n  | a   a/ |
	# {a}      | file   | error  |   n   |  y  |        |
	# {}       | error  | error  |   n   |  n  |        |
	if code_is_directory "$from" && code_is_file "${from%/}"; then
		[[ "$from" == */ ]] && from_is_dir=true
	elif code_is_directory "$from"; then
		from_is_dir=true
	elif [[ "$from" == */ ]] || ! code_is_file "$from"; then
		die "Error: \`$from\` not in pass-code store."
	fi
	from="${from%/}"

	#  codec   |   b    |   b/    | d? b/ | f b | is_dir |
	# ---------|--------|---------|-------------|--------|
	# {b, b/*} | file   | folder  |   y   |  y  |   b/   |
	# {b/*}    | folder | folder  |   y   |  n  | b   b/ |
	# {b}      | file   | folder+ |   n   |  y  |   b/   |
	# {}       | file+  | folder+ |   n   |  n  |   b/   |
	if [[ "$to" == */ ]]; then
		to_is_dir=true
	elif code_is_directory "$to" && ! code_is_file "${to%/}"; then
		to_is_dir=true
	fi
	to="${to%/}"

	# Decide on what exactly needs to be done.
	local from_name to_dir to_name
	local -a from_files
	local -A pass_thru

	from_name="${from##*/}"

	# Array of things to copy. The false case is a single "$from"
	# file, which I copy to a single "$to" later on using another
	# if "$from_is_dir" branch.
	if [[ "$from_is_dir" = true ]]; then
		from_files=("$(code_list_files \
			| code_filter_subfolder "$from")")
	else
		from_files=("$from")
	fi

	# If we're copying into a directory, go into it
	if [[ "$to_is_dir" = true ]]; then
		to_dir="$to"
		to_name="$from_name"
		to="$to_dir/$to_name"
	else
		to_dir="${to%/*}"
		to_name="${to##*/}"
	fi

	# ``mv a x`` on {a/a, a/b, a/c, x/a/b} asks if we want
	# to overwrite x/a and doesn't move anything if we abort.
	# But it still doesn't copy anything if we --force, since mv
	# complains x/a isn't empty. However, ``cp a x`` in the same
	# situation copies all it can, asks whenever it needs to
	# overwrite and overwrites if you say so (or give --force). If
	# you reject the overwrite, it continues copying other files.

	# Hence, don't merge folders if we're on mv.
	[[ "$action" = "move" && "$from_is_dir" = true ]] && \
		code_is_directory "$to" && \
		die "Cannot move $from_name to $to: Directory not empty"

	local fenc tenc fdec tdec
	for fdec in "${from_files[@]}"; do
		fenc="${codec[Dx$fdec]}"

		# if "$from_is_dir" is true,
		# from="old/dir", fdec="old/dir/*"
		# tdec="new/dir/*" or tdec="new/old/dir/*"
		# depending on "$to_is_dir" manipulation above
		#
		# if "$from_is_dir" is false,
		# from="old/file", fdec="old/file", to="new/file"
		if [[ "$from_is_dir" = true ]]; then
			tdec="$to/${fdec#$from/}"
		else
			tdec="$to"
		fi

		# Ask on conflicts if not force
		if code_is_file "$tdec" && [[ "$force" != true ]]; then
			yesno "overwrite $tdec?" || continue
		fi

		# No need to change mapping if one exists
		# Just overwrite the encoded file
		code_is_file "$tdec" || code_add_random "$tdec"
		pass_thru["Fx$fenc"]="${codec[Dx$tdec]}"

		# Need to remove from-file mapping if we're moving
		if [[ "$action" = "move" ]]; then
			code_remove "$fdec" "$fenc"
		fi
	done

	# Since we haven't been interrupted out of running yet,
	# we can commit to our changes. Force everything since we
	# filtered out unwanted changes earlier.
	for fxfenc in "${!pass_thru[@]}"; do
		fenc="${fxfenc#Fx}"
		tenc="${pass_thru[Fx$fenc]}"
		cmd_copy_move "$action" --force "$fenc" "$tenc"
	done

	code_encrypt
}

# For testing internal functions.
# Exit with non-zero status to pause sharness and inspect manually.
cmd_code_test() {
	exit 0
}

case "$1" in
	version|--version|-v) shift; cmd_code_version "$@" ;;
	list|ls)              shift; cmd_code_ls "$@" ;;
	show)                 shift; cmd_code_show "$@" ;;
	insert|add)           shift; cmd_code_insert "$@" ;;
	edit)                 shift; cmd_code_edit "$@" ;;
	generate)             shift; cmd_code_generate "$@" ;;
	rename|mv)            shift; cmd_code_copy_move "move" "$@" ;;
	copy|cp)              shift; cmd_code_copy_move "copy" "$@" ;;
	test)                 shift; cmd_code_test "$@" ;;
	*) exit 1;;
esac
