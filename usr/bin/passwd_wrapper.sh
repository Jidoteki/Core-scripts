#!/bin/sh
#
# Wrapper to display password conditions with retry
#
# MIT License
#
# Copyright (c) 2018 Alexander Williams, Unscramble <license@unscramble.jp>

set -e
set -u

passwd_tries=1
max_tries=3

try_passwd() {
  if [ "$passwd_tries" -le "$max_tries" ]; then
    passwd_tries=$(( $passwd_tries + 1 ))
    /bin/busybox.suid passwd "$@" || try_passwd
  else
    return 1
  fi
}

echo "Password conditions:"
echo -e "  * Minimum length: 6 characters"
echo -e "  * Must not be similar to username"
echo -e "  * Must not be similar to hostname"
echo -e "  * Must not be similar to old password"
echo -e "  * Requires at least 1 upper case, 1 lower case, 1 digit, and 1 special character"
echo ""

try_passwd "$@"
exit $?
