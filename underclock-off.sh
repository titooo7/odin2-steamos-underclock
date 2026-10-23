#!/bin/bash
# Stock CPU clocks until underclock-on.sh or the next reboot.
sudo -n /usr/bin/systemctl stop odin2-underclock.service
