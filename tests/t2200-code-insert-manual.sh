#!/usr/bin/env bash

test_description='pass-code ls with manually written .passcode'
cd "$(dirname "$0")"
. ./setup.sh

test_expect_success 'setup password store' '
	"$PASS" init $KEY1
'

test_expect_failure 'pass-code insert --echo succeeds' '
	"$PASS" code insert --echo a/a/a/a <<< "a/a/a/a" &&
	"$PASS" code insert --echo a/a/b   <<< "a/a/b"   &&
	"$PASS" code insert --echo a/b/a   <<< "a/b/a"   &&
	"$PASS" code insert --echo a/c     <<< "a/c"     &&
	"$PASS" code insert --echo b/a     <<< "b/a"     &&
	"$PASS" code insert --echo d/d/a   <<< "d/d/a"   &&
	"$PASS" code insert --echo d/d/b   <<< "d/d/b"   &&
	"$PASS" code insert --echo d/d/c   <<< "d/d/c"   &&
	"$PASS" code insert --echo e/f     <<< "e/f"     &&
	"$PASS" code insert --echo g       <<< "g"
'

remove_colors() { sed -e "s/\x1B\[[0-9;]*m//g"; }

test_expect_failure 'pass-code insert folder hierarchy is correct' '
	diff -U99 - \
		<("$PASS" code ls | remove_colors) \
		<<- "_EOF_"
	Password Store
	|-- a
	|   |-- a
	|   |   |-- a
	|   |   |   `-- a
	|   |   `-- b
	|   |-- b
	|   |   `-- a
	|   `-- c
	|-- b
	|   `-- a
	|-- d
	|   `-- d
	|       |-- a
	|       |-- b
	|       `-- c
	|-- e
	|   `-- f
	`-- g
	_EOF_
'

test_expect_failure 'pass-code inserted passwords are correct' '
	diff -U99 - <("$PASS" code show a/a/a/a) <<< "a/a/a/a" &&
	diff -U99 - <("$PASS" code show a/a/b)   <<< "a/a/b"   &&
	diff -U99 - <("$PASS" code show a/b/a)   <<< "a/b/a"   &&
	diff -U99 - <("$PASS" code show a/c)     <<< "a/c"     &&
	diff -U99 - <("$PASS" code show b/a)     <<< "b/a"     &&
	diff -U99 - <("$PASS" code show d/d/a)   <<< "d/d/a"   &&
	diff -U99 - <("$PASS" code show d/d/b)   <<< "d/d/b"   &&
	diff -U99 - <("$PASS" code show d/d/c)   <<< "d/d/c"   &&
	diff -U99 - <("$PASS" code show e/f)     <<< "e/f"     &&
	diff -U99 - <("$PASS" code show g)       <<< "g"
'

test_expect_failure 'pass-code insert --multiline succeeds' '
	"$PASS" code insert --multiline mul/ti/line <<- _EOF_
	First line.
	Second line.
	Third line.
	Fourth line.
	Fifth line.
	_EOF_
'

test_expect_failure 'pass-code insert --multiline value is correct' '
	diff -U99 - <("$PASS" code show mul/ti/line) <<- _EOF_
	First line.
	Second line.
	Third line.
	Fourth line.
	Fifth line.
	_EOF_
'

test_done
