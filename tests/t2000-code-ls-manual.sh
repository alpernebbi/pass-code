#!/usr/bin/env bash

test_description='pass-code ls with manually written .passcode'
cd "$(dirname "$0")"
. ./setup.sh

test_expect_success 'setup .passcode.gpg manually' '
	"$PASS" init $KEY1
	"$PASS" insert --multiline .passcode <<- "_EOF_" >/dev/null
	puap5y6t5nq6r75v:a/a/a/a
	niozt3shbhobwjit:a/a/b
	6qjue4yxea7a2bfy:a/b/a
	frp6mxk35daczom6:a/c
	na6afjbulshsnket:b/a
	aksqm5aw4lbn5fmp:d/d/a
	jlkgltkeh5pmfogs:d/d/b
	s3bhz3rmtjo5ugai:d/d/c
	dz4bbay7a55q65ie:e/f
	r3orhjgnwrixi6gg:g
	_EOF_
'

test_expect_success 'setup encoded filenames' '
	"$PASS" insert --echo puap5y6t5nq6r75v <<< "a/a/a/a"
	"$PASS" insert --echo niozt3shbhobwjit <<< "a/a/b"
	"$PASS" insert --echo 6qjue4yxea7a2bfy <<< "a/b/a"
	"$PASS" insert --echo frp6mxk35daczom6 <<< "a/c"
	"$PASS" insert --echo na6afjbulshsnket <<< "b/a"
	"$PASS" insert --echo aksqm5aw4lbn5fmp <<< "d/d/a"
	"$PASS" insert --echo jlkgltkeh5pmfogs <<< "d/d/b"
	"$PASS" insert --echo s3bhz3rmtjo5ugai <<< "d/d/c"
	"$PASS" insert --echo dz4bbay7a55q65ie <<< "e/f"
	"$PASS" insert --echo r3orhjgnwrixi6gg <<< "g"
'

test_expect_success 'pass ls output should be scrambled' '
	diff -U99 - <("$PASS" ls) <<- "_EOF_"
	Password Store
	|-- 6qjue4yxea7a2bfy
	|-- aksqm5aw4lbn5fmp
	|-- dz4bbay7a55q65ie
	|-- frp6mxk35daczom6
	|-- jlkgltkeh5pmfogs
	|-- na6afjbulshsnket
	|-- niozt3shbhobwjit
	|-- puap5y6t5nq6r75v
	|-- r3orhjgnwrixi6gg
	`-- s3bhz3rmtjo5ugai
	_EOF_
'

test_expect_failure 'pass-code ls output should be decoded' '
	diff -U99 - <("$PASS" code ls) <<- "_EOF_"
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

test_expect_failure 'pass-code ls subfolder 1' '
	diff -U99 - <("$PASS" code ls a) <<- "_EOF_"
	a
	|-- a
	|   |-- a
	|   |   `-- a
	|   `-- b
	|-- b
	|   `-- a
	`-- c
	_EOF_
'

test_expect_failure 'pass-code ls subfolder 2' '
	diff -U99 - <("$PASS" code ls a/a) <<- "_EOF_"
	a/a
	|-- a
	|   `-- a
	`-- b
	_EOF_
'

test_expect_failure 'pass-code ls subfolder 3' '
	diff -U99 - <("$PASS" code ls a/a) <<- "_EOF_"
	a/a/a
	`-- a
	_EOF_
'

test_expect_failure 'pass-code ls subfolder 4' '
	diff -U99 - <("$PASS" code ls d) <<- "_EOF_"
	d
	`-- d
	    |-- a
	    |-- b
	    `-- c
	_EOF_
'

test_done
