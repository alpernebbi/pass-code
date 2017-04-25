#!/usr/bin/env bash

test_description='Reencryption consistency'
cd "$(dirname "$0")"
. ./setup.sh
PASS="$SHARNESS_TEST_DIRECTORY/pass-code.sh"

INITIAL_PASSWORD="will this password live? a big question indeed..."

canonicalize_gpg_keys() {
	$GPG --list-keys --with-colons "$@" | sed -n 's/sub:[^:]*:[^:]*:[^:]*:\([^:]*\):[^:]*:[^:]*:[^:]*:[^:]*:[^:]*:[^:]*:[a-zA-Z]*e[a-zA-Z]*:.*/\1/p' | LC_ALL=C sort -u
}

gpg_keys_from_encrypted_file() {
	$GPG -v --no-secmem-warning --no-permission-warning --decrypt --list-only --keyid-format long "$1" 2>&1 | cut -d ' ' -f 5 | LC_ALL=C sort -u
}

gpg_file_from_code() {
	local enc="$("$PASS" show .passcode | grep ":$1$" | cut -d ':' -f 1)"
	echo "$PASSWORD_STORE_DIR/$enc.gpg"
}

gpg_keys_from_code() {
	gpg_keys_from_encrypted_file "$(gpg_file_from_code "$1")"
}

gpg_keys_from_group() {
	local output="$($GPG --list-config --with-colons | sed -n "s/^cfg:group:$1:\\(.*\\)/\\1/p" | head -n 1)"
	local saved_ifs="$IFS"
	IFS=";"
	local keys=( $output )
	IFS="$saved_ifs"
	canonicalize_gpg_keys "${keys[@]}"
}

test_expect_success 'Setup initial key and git' '
	"$PASS" init $KEY1 && "$PASS" git init
'

test_expect_success 'Root key encryption' '
	"$PASS" insert -e folder/cred1 <<<"$INITIAL_PASSWORD" &&
	[[ $(canonicalize_gpg_keys "$KEY1") == "$(gpg_keys_from_code "folder/cred1")" ]]
'

test_expect_success 'Reencryption root single key' '
	"$PASS" init $KEY2 &&
	[[ $(canonicalize_gpg_keys "$KEY2") == "$(gpg_keys_from_code "folder/cred1")" ]]
'

test_expect_success 'Reencryption root multiple key' '
	"$PASS" init $KEY2 $KEY3 $KEY1 &&
	[[ $(canonicalize_gpg_keys $KEY2 $KEY3 $KEY1) == "$(gpg_keys_from_code "folder/cred1")" ]]
'

test_expect_success 'Reencryption root multiple key with string' '
	"$PASS" init $KEY2 $KEY3 $KEY1 "pass test key 4" &&
	[[ $(canonicalize_gpg_keys $KEY2 $KEY3 $KEY1 $KEY4) == "$(gpg_keys_from_code "folder/cred1")" ]]
'

test_expect_success 'Reencryption root group' '
	"$PASS" init group1 &&
	[[ $(gpg_keys_from_group group1) == "$(gpg_keys_from_code "folder/cred1")" ]]
'

test_expect_success 'Reencryption root group with spaces' '
	"$PASS" init "big group" &&
	[[ $(gpg_keys_from_group "big group") == "$(gpg_keys_from_code "folder/cred1")" ]]
'

test_expect_success 'Reencryption root group with spaces and other keys' '
	"$PASS" init "big group" $KEY3 $KEY1 $KEY2 &&
	[[ $(canonicalize_gpg_keys $KEY3 $KEY1 $KEY2 $(gpg_keys_from_group "big group")) == "$(gpg_keys_from_code "folder/cred1")" ]]
'

test_expect_success 'Reencryption root group and other keys' '
	"$PASS" init group2 $KEY3 $KEY1 $KEY2 &&
	[[ $(canonicalize_gpg_keys $KEY3 $KEY1 $KEY2 $(gpg_keys_from_group group2)) == "$(gpg_keys_from_code "folder/cred1")" ]]
'

test_expect_success 'Reencryption root group to identical individual with no file change' '
	oldfile="$SHARNESS_TRASH_DIRECTORY/$RANDOM.$RANDOM.$RANDOM.$RANDOM.$RANDOM" &&
	"$PASS" init group1 &&
	cp "$(gpg_file_from_code "folder/cred1")" "$oldfile" &&
	"$PASS" init $KEY4 $KEY2 &&
	test_cmp "$(gpg_file_from_code "folder/cred1")" "$oldfile"
'

test_expect_failure 'Reencryption subfolder multiple keys, copy' '
	"$PASS" init -p anotherfolder $KEY3 $KEY1 &&
	"$PASS" cp folder/cred1 anotherfolder/ &&
	[[ $(canonicalize_gpg_keys $KEY1 $KEY3) == "$(gpg_keys_from_code "anotherfolder/cred1")" ]]
'

test_expect_failure 'Reencryption subfolder multiple keys, move, deinit' '
	"$PASS" init -p anotherfolder2 $KEY3 $KEY4 $KEY2 &&
	"$PASS" mv -f anotherfolder anotherfolder2/ &&
	[[ $(canonicalize_gpg_keys $KEY1 $KEY3) == "$(gpg_keys_from_code "anotherfolder2/anotherfolder/cred1")" ]] &&
	"$PASS" init -p anotherfolder2/anotherfolder "" &&
	[[ $(canonicalize_gpg_keys $KEY3 $KEY4 $KEY2) == "$(gpg_keys_from_code "anotherfolder2/anotherfolder/cred1")" ]]
'

#TODO: test with more varieties of move and copy!

test_expect_success 'Password lived through all transformations' '
	[[ $("$PASS" show anotherfolder2/anotherfolder/cred1) == "$INITIAL_PASSWORD" ]]
'

test_expect_success 'Git picked up all changes throughout' '
	[[ -z $(git status --porcelain 2>&1) ]]
'

test_done
