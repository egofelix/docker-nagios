#!/bin/bash
kill -HUP `supervisorctl status nagios4 | grep -o -E 'pid [0-9]+' | awk '{print $2}'`
