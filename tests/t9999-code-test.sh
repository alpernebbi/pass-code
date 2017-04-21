#!/usr/bin/env bash

test_description='pass-code internal testing'
cd "$(dirname "$0")"
. ./setup.sh

test_expect_success 'run pass-code internal tests' '
	"$PASS" init $KEY1 &&
	"$PASS" code test || test_pause
'

test_done
