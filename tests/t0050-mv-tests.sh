#!/usr/bin/env bash

test_description='Test mv command'
cd "$(dirname "$0")"
. ./setup.sh
PASS="$SHARNESS_TEST_DIRECTORY/pass-code.sh"

INITIAL_PASSWORD="bla bla bla will we make it!!"

test_expect_success 'Basic move command' '
	"$PASS" init $KEY1 &&
	"$PASS" git init &&
	"$PASS" insert -e cred1 <<<"$INITIAL_PASSWORD" &&
	"$PASS" mv cred1 cred2 &&
	test_must_fail "$PASS" show cred1 &&
	"$PASS" show cred2
'

test_expect_success 'Directory creation' '
	"$PASS" mv cred2 directory/ &&
	test_must_fail "$PASS" show cred2 &&
	"$PASS" show directory/cred2
'

test_expect_success 'Directory creation with file rename and empty directory removal' '
	"$PASS" mv directory/cred2 "new directory with spaces"/cred &&
	test_must_fail "$PASS" show directory/cred2 &&
	"$PASS" show "new directory with spaces"/cred
'

test_expect_success 'Directory rename' '
	"$PASS" mv "new directory with spaces" anotherdirectory &&
	test_must_fail "$PASS" show "new directory with spaces"/cred &&
	"$PASS" show anotherdirectory/cred
'

test_expect_success 'Directory move into new directory' '
	"$PASS" mv anotherdirectory "new directory with spaces"/ &&
	test_must_fail "$PASS" show anotherdirectory/cred &&
	"$PASS" show "new directory with spaces"/anotherdirectory/cred
'

test_expect_success 'Multi-directory creation and multi-directory empty removal' '
	"$PASS" mv "new directory with spaces"/anotherdirectory/cred new1/new2/new3/new4/thecred &&
	"$PASS" mv new1/new2/new3/new4/thecred cred &&
	test_must_fail "$PASS" show "new directory with spaces"/anotherdirectory/cred &&
	test_must_fail "$PASS" show new1/new2/new3/new4/thecred &&
	"$PASS" show cred
'

test_expect_success 'Password made it until the end' '
	[[ $("$PASS" show cred) == "$INITIAL_PASSWORD" ]]
'

test_expect_success 'Git is consistent' '
	[[ -z $(git status --porcelain 2>&1) ]]
'

test_done
