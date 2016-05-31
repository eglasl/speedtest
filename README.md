# speedtest

## Purpose

Measure the real downlink and uplink bandwidth of your DSL or Calbe Internet connection every hour to create a bandwidth log.

## Installation

* Clone the sript in ${HOME}/speedtest
* Eventually create /var/www/html/speedlink if you want to download the log from your private web server
* Create a cronjob: 0 * * * * test -x ${HOME}/speedtest/run.sh && ${HOME}/speedtest/run.sh down && ${HOME}/speedtest/run.sh up
* Use LibreOffice Calc to create graphs from the log in CSV
