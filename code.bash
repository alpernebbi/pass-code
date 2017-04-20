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
		if [[ "${key#Ex}" != "$key" ]]; then
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
		| cmd_insert ".passcode" --multiline --force
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

cmd_code_version() {
	cat <<- EOF
	$PROGRAM-code version 0.1.0
	EOF
}

# Assumes the encoded hierarchy is flat
cmd_code_ls() {
	local subfolder="$1"
	check_sneaky_paths "$subfolder"

	code_decrypt
	cmd_show \
		| tail -n +2 \
		| cut -d ' ' -f 2 \
		| code_decode \
		| code_filter_subfolder "$subfolder" \
		| code_format_as_tree "$subfolder"
}


case "$1" in
	version|--version|-v) shift; cmd_code_version "$@" ;;
	list|ls)              shift; cmd_code_ls "$@" ;;
	*) exit 1;;
esac
