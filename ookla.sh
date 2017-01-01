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
# 5. LOG can be opened with spreadsheet to create graphs during 1 month
# 6. Create symbolic links from ./ookla.sh to ./incoming and ./outgoing
#
# CRONJOB:
# 0 * * * * /var/speedtest/incoming && /var/speedtest/outgoing
# or:
# 0 * * * * /var/speedtest/combined

#####################
##  Configuration  ##
#####################

LANG="en_US.UTF-8"                        # Accurate handling of decimal point
DIR="/var/speedtest/"                     # My directory
WWW="/var/log/speedtest/"                 # Save the log files here
BIN="/usr/bin/curl"                       # cURL binary
URL="ftp://speedtest.tele2.net/"          # Download URL of OOKLA
API="https://api.ipify.org?format=text"   # Get my public IP in text format
DNF="10MB.zip"                            # Download file to test bandwidth
UPF="upload/$(date +%N).zip"              # Upload file name, unique
LOG="${WWW}$(date +%Y-%m)"                # Create a new log every month

# Format of curl date (for curl -w)
FMT="%{remote_ip},%{size_download},%{speed_download},%{size_upload},%{speed_upload},%{time_namelookup},%{time_connect},%{time_total}"

# Get my public IP address via API but check output before use
PIP="$(${BIN} -f -s ${API} | egrep -o '[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+')"

# Get my local IP address of external NIC
# LIP="$(host $(hostname -s) | egrep -o '[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+')"
LIP="$(ip route get 8.8.8.8 | awk '/8.8.8.8/ {print $NF}')"

# Get my stripped basename
SELF="${0}"; BASE="${SELF##*/}"; CORE="${BASE%.*}"


#######################
##  Basic functions  ##
#######################

function testdata {
  # If test data file for upload does not exist, download it first
  ${BIN} -f -s ${URL}${DNF} -o ${DIR}${DNF} 2>&1 >/dev/null
}

function logfiles {
  # Create log file for the first time
  echo -e "time_stamp,data_flow,local_ip,public_ip,${FMT}" \
    | sed -e 's/[%{}]//g' >${OUT}
}

function incoming {
  # echo "Script \"${CORE}\" on public IP ${PIP} testing download speed!"
  # Set time stamp
  TST="$(date +%Y-%m-%dT%H:%M:%S%z)"
  # Perform the download
  echo "${TST},incoming,${LIP},${PIP},${FMT}\n" \
    | ${BIN} -w "@-" -s ${URL}${DNF} \
    -o /dev/null >>${OUT}
}

function outgoing {
  # echo "Script \"${CORE}\" on public IP ${PIP} testing upload speed!"
  # Set time stamp
  TST="$(date +%Y-%m-%dT%H:%M:%S%z)"
  # Perform the upload
  echo "${TST},outgoing,${LIP},${PIP},${FMT}\n" \
    | ${BIN} -w "@-" -T ${DIR}${DNF} \
    -s ${URL}${UPF} >>${OUT}
}


###################
##  Main script  ##
###################

case ${CORE} in

  "incoming" )
    OUT="${LOG}.${CORE}.csv"
    test -f "${OUT}"       || logfiles
    test -f "${DIR}${DNF}" || testdata
    incoming
    exit 0
    ;;

  "outgoing" )
    OUT="${LOG}.${CORE}.csv"
    test -f "${OUT}"       || logfiles
    test -f "${DIR}${DNF}" || testdata
    outgoing
    exit 0
    ;;

  "combined" )
    OUT="${LOG}.${CORE}.csv"
    test -f "${OUT}"       || logfiles
    test -f "${DIR}${DNF}" || testdata
    incoming
    outgoing
    exit 0
    ;;

  * )
    echo "Usage: [ combined | incoming | outgoing ]"
    echo "OOKLA Speedtest wrapper, (c) 2017 by eelco.glasl@gmail.com"
    echo "  combined - write combined download and upload log"
    echo "  incoming - write download log"
    echo "  outgoing - write upload log"
    exit 1
    ;;

esac

# eof
