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

declare -A codec_dec
declare -A codec_enc

# Decrypt the .passcode file and put it to associative arrays so we
# don't need to re-decrpyt it every time we encode/decode something.
code_decrypt() {
	codec=($(cmd_show .passcode))

	for c in "${codec[@]}"; do
		# Bash interprets stuff that start with digit as
		# integers, so put an 'x' before the keys.
		codec_enc["x${c##*:}"]="${c%%:*}"
		codec_dec["x${c%%:*}"]="${c##*:}"
	done
}

# Will not print anything if code_decrypt not run or key not in mappings
code_encode() {
	while read -r line; do
		echo "${codec_enc[x$line]}"
	done
}

code_decode() {
	while read -r line; do
		echo "${codec_dec[x$line]}"
	done
}

cmd_code_version() {
	cat <<- EOF
	$PROGRAM-code version 0.1.0
	EOF
}

case "$1" in
	version|--version|-v) shift; cmd_code_version "$@" ;;
	*) exit 1;;
esac
