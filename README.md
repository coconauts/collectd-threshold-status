## Description

This `status.sh` script will parse the collectd's threshold log from syslog and it will generate a HTML file with the status of all the servers.

Note: Obviously, this script doesn't know about old entries but it will update the status as soon as they show some info in the log.

## Installation

Locate the script inside the web folder (eg: /etc/collectd-web/status)

The bash script should run periodically in cron `crontab -e`

    */5 * * * * cd /etc/collectd-web/status && ./status.sh >> status.log 2>&1

You can change the script frequence (for example, `*/30`), but if you reduce the frequency, update the script to take more lines from the log (60 by default)

## How to use

Depending of your collectd-web setup, it might be in:

    http://localhost/status