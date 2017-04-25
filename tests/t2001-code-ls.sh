#!/usr/bin/env bash

test_description='pass-code ls tests'
cd "$(dirname "$0")"
. ./setup.sh

test_expect_success 'setup password store' '
	"$PASS" init $KEY1
'

remove_colors() { sed -e "s/\x1B\[[0-9;]*m//g"; }

test_expect_success 'pass-code ls file with spaces' '
	"$PASS" code generate "a long name with spaces" &&
	diff -U99 - \
		<("$PASS" code ls | remove_colors) \
		<<- "_EOF_"
	Password Store
	`-- a long name with spaces
	_EOF_
'

test_expect_success 'pass-code ls directory with spaces' '
	"$PASS" code generate "a long dir with spaces"/"other file" &&
	diff -U99 - \
		<("$PASS" code ls | remove_colors) \
		<<- "_EOF_"
	Password Store
	|-- a long dir with spaces
	|   `-- other file
	`-- a long name with spaces
	_EOF_
'

test_expect_success 'pass-code ls more folders with spaces' '
	"$PASS" code generate "dir a/dir b/dir c/cred c" &&
	"$PASS" code generate "dir a/dir b/dir d/cred d" &&
	diff -U99 - \
		<("$PASS" code ls | remove_colors) \
		<<- "_EOF_"
	Password Store
	|-- a long dir with spaces
	|   `-- other file
	|-- a long name with spaces
	`-- dir a
	    `-- dir b
	        |-- dir c
	        |   `-- cred c
	        `-- dir d
	            `-- cred d
	_EOF_
'

test_expect_success 'pass-code ls subfolders with spaces' '
	diff -U99 - \
		<("$PASS" code ls "dir a/dir b" | remove_colors) \
		<<- "_EOF_"
	dir a/dir b
	|-- dir c
	|   `-- cred c
	`-- dir d
	    `-- cred d
	_EOF_
'

test_done
