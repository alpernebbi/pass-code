#!/usr/bin/env bash

test_description='pass-code test skeleton'
cd "$(dirname "$0")"
. ./setup.sh

test_expect_success 'set up password store' '
	"$PASS" init $KEY1 &&
	"$PASS" code generate a 32
'

test_expect_success 'pass-code edit password works' '
	export FAKE_PASSWORD=".Gob<9sl)N[(~Xu2#DZV3v?CDt*2sM]w" &&
	EDITOR=tee "$PASS" code edit a <<< "$FAKE_PASSWORD" &&
	diff -U99 - <("$PASS" code show a) <<< "$FAKE_PASSWORD"
'

test_done
