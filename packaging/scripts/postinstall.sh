#!/bin/sh
set -e

if command -V systemctl >/dev/null 2>&1; then
    systemctl daemon-reload ||:
    systemctl restart mosquitto ||:
fi
