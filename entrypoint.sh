#!/bin/bash
set -m
/usr/sbin/nginx -g 'daemon off;' &
/usr/sbin/sshd -D
fg %1