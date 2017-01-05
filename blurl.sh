#!/bin/bash
#
# speedtest/blurl.sh - Bandwidth and Link tester wrapped around cURL:
# Calculate downstream and upstream bandwidth
# to measure DSL or Cable connection quality.
#
# (c) 2016, Eelco M. Glasl <eelco.glasl@gmail.com>
# speedtest.tele2.net offers standardized download files with sizes/names like
# 10GB, 1GB, 100MB, 10MB, 1MB, 100KB, 1KB
# etc. ending at ".zip". See http://speedtest.tele2.net/
#
# INSTALLATION:
# 1. Change WWW if necessary or set to "./"
# 2. Change ULS and DLS if necessary for different file size
# 3. Create a cronjob with content as shown below
# 4. Check if LOG gets created
# 5. LOG can be opened with spreadsheet to create graphs during 1 month
# 6. Create symbolic links from ./ookla.sh to ./incoming, ./outgoing,
#    ./combined and ./checksum
#
# CRONTAB:
# 00 00,06,12,18  * * * /var/speedtest/combined
# 10 00          01 * * /var/speedtest/checksum
#
# The logfile will have a name like "2017-01.combined.csv" with the following
# rows after the first call. The checksum file att every first of the month
# will look like "2017-01.combined.sha256sum"
#
# ROW EXAMPLE:
# time_stamp,data_flow,local_ip,public_ip,remote_ip,size_download,speed_download,size_upload,speed_upload,time_namelookup,time_connect,time_total,sha256sum
# 2017-01-02T13:07:55+0100,incoming,10.59.17.198,213.61.137.106,90.130.70.73,10485760,6966731.000,0,0.000,0.004,0.019,1.505,8f16fc487a358d369d45f2030e3629aca3480d798c5153e32ed44e9b67a12f48
# 2017-01-02T13:07:57+0100,outgoing,10.59.17.198,213.61.137.106,90.130.70.73,0,0.000,10485760,6959582.000,0.004,0.017,1.507,55cee35735ffe0ac1f64aaafd45de03479022fa5d1fde68c8dac45973051e8b4
#
# VERIFY ROW:
# $ echo -n "${PASTE_COMPLETE_ROW_MINUS_LAST_COLUMN}" | sha256sum

#####################
##  Configuration  ##
#####################

LANG="en_US.UTF-8"                        # Accurate handling of decimal point
DIR="/var/speedtest/"                     # My directory
WWW="/var/log/speedtest/"                 # Save the log files here
BIN="/usr/bin/curl"                       # cURL binary
URL="ftp://speedtest.tele2.net/"          # Download URL of Speedtest.net
API="https://api.ipify.org?format=text"   # API to get public IP in text format
DLS="100MB.zip"                           # Download test source file
ULS="10MB.zip"                            # Upload test soure file
ULT="upload/$(date +%N).zip"              # Upload test target file
LOG="$(date +%Y-%m)"                      # Create a new log every month
CHK="sha256sum"                           # Tool to add checksum to rows

# Format of curl csv data (for curl -w)
FMT="%{remote_ip},%{size_download},%{speed_download},%{size_upload},%{speed_upload},%{time_namelookup},%{time_connect},%{time_total}"

# Get my public IP address via API but check output before use
PIP="$( ${BIN} -f -s ${API} | egrep -o '[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+' )"

# Get my local IP address of external NIC
# LIP="$(host $(hostname -s) | egrep -o '[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+')"
LIP="$( ip route get 8.8.8.8 | awk '/8.8.8.8/ {print $NF}' )"

# Get my stripped basename
SELF="${0}"; BASE="${SELF##*/}"; CORE="${BASE%.*}"


#######################
##  Basic functions  ##
#######################

function testdata {
  # If test data file for upload does not exist, download it first
  ${BIN} -f -s ${URL}${ULS} -o ${DIR}${ULS} 2>&1 >/dev/null
}

function logfiles {
  # Create log file for the first time
  echo -e "time_stamp,data_flow,local_ip,public_ip,${FMT},${CHK}" \
    | sed -e 's/[%{}]//g' >${OUT}
}

function incoming {
  # echo "Script \"${CORE}\" on public IP ${PIP} testing download speed!"
  # Set time stamp
  TST="$( date +%Y-%m-%dT%H:%M:%S%z )"
  # Perform the download
  ROW="$( echo "${TST},incoming,${LIP},${PIP},${FMT},\n" \
    | ${BIN} -w "@-" -s ${URL}${DLS} -o /dev/null )"
  # Generate checksum of row and append to output
  SUM="$( echo -n ${ROW} | ${CHK} | awk '{print $1}' )"
  echo "${ROW}${SUM}" >>${OUT}
}

function outgoing {
  # echo "Script \"${CORE}\" on public IP ${PIP} testing upload speed!"
  # Set time stamp
  TST="$( date +%Y-%m-%dT%H:%M:%S%z )"
  # Perform the upload
  ROW="$( echo "${TST},outgoing,${LIP},${PIP},${FMT},\n" \
    | ${BIN} -w "@-" -T ${DIR}${ULS} -s ${URL}${ULT} )"
  # Generate checksum of row and append to output
  SUM="$( echo -n ${ROW} | ${CHK} | awk '{print $1}' )"
  echo "${ROW}${SUM}" >>${OUT}
}

function checksum {
  # Upon creation of a new log file, generate checksums of closed log files
  # Use with crontab: "10 00 01 * * /var/speedtest/checksum"
  cd ${WWW}
  for LF1 in *.csv; do
    LF2="${LF1%.*}"
    LF3="${LF2%.*}"
    if [ -s ${LF2}.${CHK} ]; then
      echo "${0}: ${LF1} old file skipped"
    elif [ "${LF3}" == "${LOG}" ]; then
      echo "${0}: ${LF1} new file skipped"
    else
      ${CHK} ${LF2}.csv >${LF2}.${CHK}
      echo "${0}: ${LF1} generated ${LF2}.${CHK}"
    fi
  done
}

function symlinks {
  # Create necessary symbolic links if they do not exist yet
  cd ${DIR}
  for SYM in ${LNK}; do
    if [ ! -f ./${SYM} ]; then
      echo "${0}: create symlink ${SYM}"
      ln -s ./${BASE} ./${SYM}
    fi
  done
}

###################
##  Main script  ##
###################

case ${CORE} in

  "incoming" )
    OUT="${WWW}${LOG}.${CORE}.csv"
    test -f "${OUT}"       || logfiles
    test -f "${DIR}${ULS}" || testdata
    incoming
    exit 0
    ;;

  "outgoing" )
    OUT="${WWW}${LOG}.${CORE}.csv"
    test -f "${OUT}"       || logfiles
    test -f "${DIR}${ULS}" || testdata
    outgoing
    exit 0
    ;;

  "combined" )
    OUT="${WWW}${LOG}.${CORE}.csv"
    test -f "${OUT}"       || logfiles
    test -f "${DIR}${ULS}" || testdata
    incoming
    outgoing
    exit 0
    ;;

  "checksum" )
    checksum
    exit 0
    ;;

  "blurl" )
    LNK="incoming outgoing combined checksum"
    symlinks
    echo "${0}: call again as: ${LNK}"
    exit 1
    ;;

  * )
    echo "Usage: [ combined | incoming | outgoing | checksum | blurl.sh ]"
    echo "BLURL 1.0.0, a Bandwidth and Link tester wrapped around cURL"
    echo "(c) 2017 by eelco.glasl@gmail.com - call script as"
    echo "  - blurl.sh: create symlinks in ${DIR}"
    echo "  - combined: write a combined download and upload log"
    echo "  - incoming: write a download test log"
    echo "  - outgoing: write an upload test log"
    echo "  - checksum: create a checksum file of each closed log file."
    exit 1
    ;;

esac

# eof
