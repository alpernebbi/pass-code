#!/usr/bin/env bash

test_description='Test rm'
cd "$(dirname "$0")"
. ./setup.sh
PASS="$SHARNESS_TEST_DIRECTORY/pass-code.sh"

test_expect_success 'Test "rm" command' '
	"$PASS" init $KEY1 &&
	"$PASS" generate cred1 43 &&
	"$PASS" rm cred1 &&
	test_must_fail "$PASS" show cred1
'

test_expect_success 'Test "rm" command with spaces' '
	"$PASS" generate "hello i have spaces" 43 &&
	"$PASS" show "hello i have spaces" &&
	"$PASS" rm "hello i have spaces" &&
	test_must_fail "$PASS" show "hello i have spaces"
'

test_expect_success 'Test "rm" of non-existent password' '
	test_must_fail "$PASS" rm does-not-exist
'

test_done
