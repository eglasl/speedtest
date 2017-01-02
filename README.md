# speedtest

## Purpose

Measure the real downlink and uplink bandwidth of your DSL or Cable connection by cronjob to create a bandwidth log.

## Installation

* Clone the sript in /var/speedtest
* Eventually create /var/www/html/speedtest if you want to download the log from your private web server or create /var/log/speedtest or whatever
* Create symlinks in /var/speedtest from "./ookla.sh" to "./incoming", "./outgoing" and "./combined"
* Create a cronjob: "01 0,6,12,18 * * * test -x /var/speedtest/combined && /var/speedtest/combined"
* Use LibreOffice Calc to create graphs from the log in CSV
