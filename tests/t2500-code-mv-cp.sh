#!/usr/bin/env bash

test_description='pass-code mv and pass-code cp tests'
cd "$(dirname "$0")"
. ./setup.sh

test_expect_success 'set up password-store' '
	"$PASS" init $KEY1 &&
	"$PASS" code generate a
'

test_expect_failure 'pass-code mv moves files around' '
	"$PASS" code mv a b &&
	test_must_fail "$PASS" code show a &&
	"$PASS" code show b
'

test_expect_failure 'pass-code cp results in identical content' '
	"$PASS" code generate a 32 &&
	"$PASS" code cp --force a b &&
	diff -U99 <("$PASS" code show a) <("$PASS" code show b)
'

test_expect_success 'pass-code cp filenames are still encoded' '
	test_must_fail "$PASS" show a
	test_must_fail "$PASS" show b
'

test_expect_failure 'pass-code mv force with files' '
	"$PASS" code mv b a --force &&
	test_must_fail "$PASS" code show b
'

test_done
