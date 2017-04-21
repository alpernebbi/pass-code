#!/usr/bin/env bash

test_description='pass-code generate tests'
cd "$(dirname "$0")"
. ./setup.sh

test_expect_success 'setup password store' '
	"$PASS" init $KEY1
'

test_expect_success 'pass-code generate' '
	"$PASS" code generate alpha 32
'

test_expect_success 'pass-code generate --force' '
	"$PASS" code generate --force alpha 32
'

test_expect_success 'pass-code generated password has correct length' '
	password=$("$PASS" code show alpha) &&
	[[ "${#password}" -eq 32 ]]
'

test_expect_success 'pass-code generate encodes filename' '
	test_must_fail "$PASS" ls alpha
'

test_done
