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

### Create groups
if ! group_exists mosquitto; then
    if command_exists groupadd; then
        groupadd --system mosquitto
    elif command_exists addgroup; then
        addgroup -S mosquitto
    else
        echo "WARNING: Could not create group: mosquitto" >&2
    fi
fi

### Create users
# Create user with no home(--no-create-home), no login(--shell) and in group mosquitto(--gid)
if ! user_exists mosquitto; then
    if command_exists useradd; then
        useradd --system --no-create-home --shell /sbin/nologin --gid mosquitto mosquitto
    elif command_exists adduser; then
        adduser -g "" -H -D mosquitto -G mosquitto
    else
        echo "WARNING: Could not create user: mosquitto" >&2
    fi
fi
