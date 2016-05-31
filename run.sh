#!/bin/bash
#
# speedtest/run.sh - Calculate downstream and upstream bandwidth to measure
# DSL or Cable connection quality.
#
# (c) 2016, Eelco M. Glasl <eelco.glasl@gmail.com>
# speedtest.tele2.net offers standardized download files with sizes/names like
# 1000GB, 100GB, 50GB, 10GB, 1GB, 500MB, 200MB, 50MB, 10MB, 1MB, 512KB, 100KB,
# 1MB etc. ending at ".zip".
#
# INSTALLATION:
# 1. Change DNF if necessary (different file size?)
# 2. Create a cronjob with content as shown below
# 3. Check if LOG gets created
# 4. LOG can be opened with Excel, create bandwidth graps during 1 month
#
# CRONJOB:
# 0 * * * * ${HOME}/speedtest/run.sh down && ${HOME}/speedtest/run.sh up

LANG="en_US"                              # For proper handling of decimal point
DIR="${HOME}/speedtest/"                  # My directory
WWW="/var/www/html/speedtest/"            # Public Web directory
BIN="/usr/bin/curl"                       # cURL binary
URL="ftp://speedtest.tele2.net/"          # Download URL
DNF="10MB.zip"                            # Download file to test bandwidth
UPF="upload/$(/bin/date +%N).zip"         # Upload file name, unique
LOG="${WWW}$(/bin/date -u +%Y-%m).csv"    # Create a new log every month

# Time stamp and format of log file entries, see "man curl: -w"
TST="$(/bin/date -u +%d-%H%M)"
FMT="%{remote_ip},%{size_download},%{speed_download},%{size_upload},%{speed_upload},%{time_namelookup},%{time_connect},%{time_total}"

# If upload file does not exist, download it first
test -f ${DIR}${DNF} || ${BIN} -f -s ${URL}${DNF} \
  -o ${DIR}${DNF} 2>&1 >/dev/null

# If log file does not exist, create it
test -f ${LOG} || echo -e "time_stamp,${FMT}" \
  | sed -e 's/[%{}]//g' >${LOG}

case ${1} in
  "down" )
    # echo "Download!"
    echo "${TST},${FMT}\n" | ${BIN} -w "@-" -s ${URL}${DNF} \
      -o /dev/null >>${LOG}
    ;;
  "up" )
    # echo "Upload!"
    echo "${TST},${FMT}\n" | ${BIN} -w "@-" -T ${DIR}${DNF} \
      -s ${URL}${UPF} >>${LOG}
    ;;
  *)
    echo "usage: ${0} [ down | up ]"
    ;;
esac

# eof
