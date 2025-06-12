#!/bin/sh
set -e

command_exists() {
    command -V "$1" >/dev/null 2>&1
}

group_exists() {
    name="$1"
    if command_exists id; then
        id -g "$name" >/dev/null 2>&1
    elif command_exists getent; then
        getent group "$name" >/dev/null 2>&1
    else
        # Fallback to plain grep, as busybox does not have getent
        grep -q "^${name}:" /etc/group
    fi
}

user_exists() {
    name="$1"
    if command_exists id; then
        id -u "$name" >/dev/null 2>&1
    elif command_exists getent; then
        getent passwd "$name" >/dev/null 2>&1
    else
        # Fallback to plain grep, as busybox does not have getent
        grep -q "^${name}:" /etc/passwd
    fi
}

remove_user() {
    name="$1"
    if user_exists "$name"; then
        if command_exists userdel; then
            userdel "$name"
        elif command_exists deluser; then
            deluser "$name"
        else
            echo "WARNING: Could not delete group: $name" >&2
        fi
    fi
}

remove_group() {
    name="$1"
    if group_exists "$name"; then
        if command_exists groupdel; then
            groupdel "$name"
        elif command_exists delgroup; then
            delgroup "$name"
        else
            echo "WARNING: Could not delete group: $name" >&2
        fi
    fi
}

purge_configs() {
    if [ -d "/etc/mosquitto" ]; then
        rm -rf /etc/mosquitto
    fi
}

purge_var_log() {
    if [ -d "/var/log/mosquitto" ]; then
        rm -rf /var/log/mosquitto
    fi
}


case "$1" in
    purge)
        remove_user "mosquitto"
        remove_group "mosquitto"
        purge_configs
        purge_var_log
    ;;
esac
