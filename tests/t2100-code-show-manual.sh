#!/usr/bin/env bash

test_description='pass-code show with manually written .passcode'
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


test_expect_success 'pass code show output matches pass show output' '
	diff -U99 \
		<("$PASS" show puap5y6t5nq6r75v) \
		<("$PASS" code show a/a/a/a) &&
	diff -U99 \
		<("$PASS" show niozt3shbhobwjit) \
		<("$PASS" code show a/a/b) &&
	diff -U99 \
		<("$PASS" show 6qjue4yxea7a2bfy) \
		<("$PASS" code show a/b/a) &&
	diff -U99 \
		<("$PASS" show frp6mxk35daczom6) \
		<("$PASS" code show a/c) &&
	diff -U99 \
		<("$PASS" show na6afjbulshsnket) \
		<("$PASS" code show b/a) &&
	diff -U99 \
		<("$PASS" show aksqm5aw4lbn5fmp) \
		<("$PASS" code show d/d/a) &&
	diff -U99 \
		<("$PASS" show jlkgltkeh5pmfogs) \
		<("$PASS" code show d/d/b) &&
	diff -U99 \
		<("$PASS" show s3bhz3rmtjo5ugai) \
		<("$PASS" code show d/d/c) &&
	diff -U99 \
		<("$PASS" show dz4bbay7a55q65ie) \
		<("$PASS" code show e/f) &&
	diff -U99 \
		<("$PASS" show r3orhjgnwrixi6gg) \
		<("$PASS" code show g)
'

test_done
