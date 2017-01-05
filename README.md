# blurl - Bandwidth and Link test wrapper around cURL

## Purpose

Measure the real downlink and uplink bandwidth of your Internet connection.
Called by cronjob, creates CSV log to be opend with spreadsheet

## Installation

* Clone the sript in /var/speedtest
* Eventually create /var/www/html/speedtest or /usr/share/nginx/html/speedtest or whatever if you want to download the log from your private web server, else create /var/log/speedtest
* Configure the settings in the script
* Call ./blurl.sh once to create all symlinks
* Create a cronjob "01 0,6,12,18 * * * /var/speedtest/combined"
* Create a cronjob "10         0 1 * * /var/speedtest/checksum"
* Use LibreOffice Calc to create graphs from the log in CSV
