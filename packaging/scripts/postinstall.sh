#!/bin/sh
set -e

system_command_exists() {
    # Note: system commands might not be in the path for a non-root
    # user, e.g. under /sbin and /usr/sbin. This may result in some false
    # negatives. Use a modified path when checking the existence for
    # more consistent results
	PATH="$PATH:/sbin:/usr/sbin" command -v "$@" > /dev/null 2>&1
}

#
# Detect service manager
#
SERVICE_MANAGER=
if system_command_exists systemctl; then
    SERVICE_MANAGER="systemd"
elif system_command_exists rc-service; then
    SERVICE_MANAGER="openrc"
elif system_command_exists update-rc.d; then
    SERVICE_MANAGER="sysvinit"
elif [ -f /command/s6-rc ]; then
    SERVICE_MANAGER="s6_overlay"
elif system_command_exists runsv; then
    SERVICE_MANAGER="runit"
elif system_command_exists supervisorctl; then
    SERVICE_MANAGER="supervisord"
else
    echo "WARNING: Could not detect the init system. Only openrc,runit,systemd,sysvinit,s6_overlay,supervisord are supported" >&2
fi

case "$SERVICE_MANAGER" in
    systemd)
        systemctl daemon-reload ||:
        systemctl restart mosquitto ||:
        ;;
    sysvinit)
        cp /usr/lib/tedge-services/sysvinit/mosquitto /etc/init.d/

        if [ ! -e /var/log/syslog ]; then
            # log to stderr if syslog is not available
            if [ -f /etc/mosquitto/mosquitto.conf ]; then
                sed -i 's/^log_dest .*/log_dest stderr/' /etc/mosquitto/mosquitto.conf ||:
            fi
        fi

        update-rc.d mosquitto defaults ||:

        # Not all sysvinit systems support the enable/disable command
        update-rc.d mosquitto enable 2>/dev/null ||:

        if command -V service >/dev/null 2>&1; then
            service mosquitto restart
        else
            # Use stop then start as some services the pid file
            # does not get deleted quick enough before starting, which results in the start failing.
            # This problem was observed on an opto-22 device when restarting mosquitto
            /etc/init.d/mosquitto stop
            sleep 1
            /etc/init.d/mosquitto start
        fi
        ;;
esac
