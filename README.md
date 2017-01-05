# speedtest - Bandwidth and Link test wrapper around cURL

## Purpose

Measure the real downlink and uplink bandwidth of your Internet connection.
Called by cronjob, creates CSV log to be opend with spreadsheet

## Installation

* Clone the sript in /var/speedtest
* Eventually create /var/www/html/speedtest if you want to download the log from your private web server or create /var/log/speedtest or whatever
* Call ./blurl.sh once to create symlinks
* Create a cronjob: "01 0,6,12,18 * * * test -x /var/speedtest/combined && /var/speedtest/combined"
* Use LibreOffice Calc to create graphs from the log in CSV
