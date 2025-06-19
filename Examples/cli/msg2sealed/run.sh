#!/bin/sh

export ENV_IN_MSG_FILENAME=./helo.msg.plain.txt
export ENV_IN_ONE_TIME_SECRET_FILENAME=./.secrets/key1time.dat

mkdir -p ./.secrets

echo 'helo wrld' > "${ENV_IN_MSG_FILENAME}"

test -f "${ENV_IN_ONE_TIME_SECRET_FILENAME}" || \
  dd \
    if=/dev/urandom \
    of="${ENV_IN_ONE_TIME_SECRET_FILENAME}" \
    bs=32 \
    count=1 \
    status=progress \
    conv=fsync

./msg2sealed |
  dd \
    if=/dev/stdin \
    of=./helo.msg.sealed.dat \
    bs=1048576 \
    status=none

ls -l ./helo.msg.plain.txt
ls -l ./helo.msg.sealed.dat
cat ./helo.msg.sealed.dat | xxd
