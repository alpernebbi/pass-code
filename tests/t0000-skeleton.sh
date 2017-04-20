#!/usr/bin/env bash

test_description='pass-code test skeleton'
cd "$(dirname "$0")"
. ./setup.sh

test_expect_success 'successful test example' '
	"$PASS" --help || true
'

test_done
