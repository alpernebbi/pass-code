#!/usr/bin/env bash

test_description='pass-code rm tests'
cd "$(dirname "$0")"
. ./setup.sh

test_expect_success 'set up password-store' '
	"$PASS" init $KEY1
'

test_expect_success 'pass-code rm file works' '
	"$PASS" code generate a &&
	"$PASS" code rm a <<< "Y" &&
	test_must_fail "$PASS" code show a
'

test_expect_success 'pass-code rm folder requires --recursive' '
	"$PASS" code generate b/1 &&
	"$PASS" code generate b/2 &&
	"$PASS" code generate b/3 &&
	test_must_fail "$PASS" code rm b &&
	"$PASS" code rm b --recursive &&
	test_must_fail "$PASS" code show b/3
'

test_done
