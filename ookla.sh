#!/bin/bash
#
# speedtest/ookla.sh - Calculate downstream and upstream bandwidth to measure
# DSL or Cable connection quality.
#
# (c) 2016, Eelco M. Glasl <eelco.glasl@gmail.com>
# speedtest.tele2.net offers standardized download files with sizes/names like
# 10GB, 1GB, 100MB, 10MB, 1MB, 100KB, 1KB
# etc. ending at ".zip". See http://speedtest.tele2.net/
#
# INSTALLATION:
# 1. Change WWW if necessary or set to "./"
# 2. Change DNF if necessary for different file size
# 3. Create a cronjob with content as shown below
# 4. Check if LOG gets created
# 5. LOG can be opened with spreadsheet to create bandwidth graphs during 1 month
# 6. Create symbolic links from ./ookla.sh to ./incoming and ./outgoing
#
# CRONJOB:
# 0 * * * * ${HOME}/speedtest/incoming && ${HOME}/speedtest/outgoing

# Get stripped basename of called script
SELF="${0}"; BASE="${SELF##*/}"; CORE="${BASE%.*}"

LANG="en_US.UTF-8"                        # Froper handling of decimal point
DIR="/root/speedtest/"                    # My directory
WWW="/var/log/speedtest/"                 # Public Web directory
BIN="/usr/bin/curl"                       # cURL binary
URL="ftp://speedtest.tele2.net/"          # Download URL
DNF="10MB.zip"                            # Download file to test bandwidth
UPF="upload/$(/bin/date +%N).zip"         # Upload file name, unique
LOG="${WWW}$(/bin/date -u +%Y-%m)"        # Create a new log every month

# Time stamp and format of log file entries, see "man curl: -w"
TST="$(/bin/date -u +%d-%H%M)"
FMT="%{remote_ip},%{size_download},%{speed_download},%{size_upload},%{speed_upload},%{time_namelookup},%{time_connect},%{time_total}"

# If upload file does not exist, download it first
test -f ${DIR}${DNF} || ${BIN} -f -s ${URL}${DNF} \
  -o ${DIR}${DNF} 2>&1 >/dev/null

case ${CORE} in
  "incoming" )
    # echo "${CORE} testing download speed!"
    OUT="${LOG}.${CORE}.csv"
    test -f ${OUT} || echo -e "time_stamp,${FMT}" \
      | sed -e 's/[%{}]//g' >${OUT}
    echo "${TST},${FMT}\n" | ${BIN} -w "@-" -s ${URL}${DNF} \
      -o /dev/null >>${OUT}
    exit 0
    ;;
  "outgoing" )
    # echo "${CORE} testing upload speed!"
    OUT="${LOG}.${CORE}.csv"
    test -f ${OUT} || echo -e "time_stamp,${FMT}" \
      | sed -e 's/[%{}]//g' >${OUT}
    echo "${TST},${FMT}\n" | ${BIN} -w "@-" -T ${DIR}${DNF} \
      -s ${URL}${UPF} >>${OUT}
    exit 0
    ;;
  *)
    echo "usage: [ incoming | outgoing ]"
    exit 1
    ;;
esac

# eof
