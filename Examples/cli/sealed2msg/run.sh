#!/bin/sh

export ENV_IN_ONE_TIME_SECRET_FILENAME=../msg2sealed/.secrets/key1time.dat

export ENV_IN_SEALED_FILENAME=../msg2sealed/helo.msg.sealed.dat

./sealed2msg
