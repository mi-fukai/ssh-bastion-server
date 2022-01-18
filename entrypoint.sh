#!/bin/bash
exec /sbin/init
systemctl daemon-reload
systemctl start sshd.service
systemctl start nginx.service
