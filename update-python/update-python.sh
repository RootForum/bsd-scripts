#!/bin/sh

# update-python
# updates Python within jails and ensures all meta ports are installed properly.
#
# Copyright (c) 2013 Jesco Freund <mail@daemotron.net>
#
# Permission to use, copy, modify, and distribute this software for any
# purpose with or without fee is hereby granted, provided that the above
# copyright notice and this permission notice appear in all copies.
#
# THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
# WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
# MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
# ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
# WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
# ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
# OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
#


VERSION="0.1.dev"

detect_binary() {
  local BINDIRS="/bin /usr/bin /sbin /usr/sbin /usr/local/bin /usr/local/sbin"
  local rval=""
  for i in $BINDIRS
  do
    if [ -x "${i}/${1}" ]
    then
      rval="${i}/${1}"
      break
    fi
  done
  echo $rval
}

b_awk=$(detect_binary "awk")
b_basename=$(detect_binary "basename")
b_cut=$(detect_binary "cut")
b_grep=$(detect_binary "grep")
b_jexec=$(detect_binary "jexec")
b_jls=$(detect_binary "jls")
b_pkg_info=$(detect_binary "pkg_info")
b_portaudit=$(detect_binary "portaudit")
b_portmaster=$(detect_binary "portmaster")
b_sed=$(detect_binary "sed")
b_sort=$(detect_binary "sort")
b_tail=$(detect_binary "tail")
b_wc=$(detect_binary "wc")

PORTMASTER_FLAGS="-dB --no-confirm"
EXCLUDE_JAILS="^999999"
sim_flag=0

cyan="\033[36m"
magenta="\033[35m"
red="\033[1;31m"
amber="\033[1;33m"
green="\033[1;32m"
white="\033[1;37m"
normal="\033[0m"

MODE=1

show_usage() {
  local FLAGS="[-hnqsvx]"
  if [ "${MODE}" -eq "1" ]
  then
    local USG="${red}usage: ${green}$($b_basename ${0}) ${normal}${FLAGS}"
  else
    local USG="usage: $($b_basename ${0}) ${FLAGS}"
  fi
  echo -e "$USG

   -h   show this help and exit
   -v   show version information and exit
   -n   do not use color escape sequences in output
   -q   quiet mode: write portmaster output to file
   -s   simulation mode: do not apply changes to the system
   -x   exclude jail number(s)

Please report any issues like bugs etc. via the BSD Scripts bug tracking
tool available at https://github.com/RootForum/bsd-scripts" >&2 && exit 0
}

show_version() {
  echo "`$b_basename $0` ${VERSION}

Copyright (c) 2013 Jesco Freund <mail@daemotron.net>
License: ISCL: ISC License <http://www.opensource.org/licenses/isc-license.txt>
This is free software: you are free to change and redistribute it.
There is NO WARRANTY, to the extent permitted by law.

Written by Jesco Freund." >&2 && exit 0
}

get_jails() {
  local jails="$($b_jls | $b_awk '/[0-9]+/ {print $1}' | $b_grep -E -v "${EXCLUDE_JAILS}" | $b_sort -n)"
  echo $jails
}

test_portmaster() {
  local jpath=$($b_jls | $b_grep -E "^[[:space:]]*${i}[[:space:]]" | $b_awk '{print $4}')
  if [ ! -f ${jpath}${b_portmaster} -a ! -x ${jpath}${b_portmaster} ]
  then
    echo "False"
  else
    echo "True"
  fi
}

run_update() {
  # declare local variables (dash bug)
  local len=""
  local jid=""
  local meta_0=""
  local meta_1=""
  local meta_2=""
  local pm=""
  local major=""
  local minor=""
  
  for i in $(get_jails)
  do
    # format jail id
    len=$(echo $i | $b_wc -c)
    if [ "$len" -lt "3" ]
    then
      jid="0${i}"
    else
      jid="${i}"
    fi
    
    printf "${cyan}Jail ${jid}: "
    
    # test availability of portmaster
    pm=$(test_portmaster)
    if [ "$pm" = "False" ]
    then
      printf "${red}Error: ${white}portmaster not available in this jail.${normal}\n"
    else  
      # test jail for installed python
      meta_0=$($b_jexec $i $b_pkg_info | $b_grep -E '^python-' | $b_awk '{print $1}')
      meta_1=$($b_jexec $i $b_pkg_info | $b_grep -E '^python[0-9]{1}-' | $b_awk '{print $1}')
      meta_2=$($b_jexec $i $b_pkg_info | $b_grep -E '^python[0-9]{2}-' | $b_awk '{print $1}')
      
      if [ -z "$meta_2" ]
      then
        printf "${amber}python not installed in this jail.${normal}\n"
      else
        major=$(echo "${meta_2}" | $b_sed 's/-.*//g' | $b_sed 's/python//g' | $b_cut -c 1)
        minor=$(echo "${meta_2}" | $b_sed 's/-.*//g' | $b_sed 's/python//g' | $b_cut -c 2)
        printf "${magenta}Python ${major}.${minor} ${white}detected. "
        
        if [ "$sim_flag" -ne "1" ]
        then
          printf "Performing update... "
          { $b_jexec $i $b_portmaster $PORTMASTER_FLAGS lang/python${major}${minor} ; } >/dev/null 2>/dev/null
          { $b_jexec $i $b_portmaster $PORTMASTER_FLAGS lang/python${major} ; } >/dev/null 2>/dev/null
          { $b_jexec $i $b_portmaster $PORTMASTER_FLAGS lang/python ; } >/dev/null 2>/dev/null
          printf "${green}done${normal}\n"
        else
          printf "${normal}\n"
        fi
      fi
    fi
  done
}

# TEST ARGUMENTS

if [ "$#" -lt "1" ]
then
  show_usage
  exit 1
fi

action="run_update"

while [ "$#" -gt "0" ]
do
  case ${1} in
    -n)
      MODE=0
      red=""
      amber=""
      green=""
      white=""
      normal=""
      cyan=""
      magenta=""
      shift
      ;;
    -q)
      PORTMASTER_FLAGS="${PORTMASTER_FLAGS} -H"
      shift
      ;;
    -v|--version)
      action="show_version"
      shift
      ;;
    -h)
      action="show_usage"
      shift
      ;;
    -s)
      sim_flag=1
      shift
      ;;
    -x)
      if [ "$#" -gt "1" ]
      then
        EXCLUDE_JAILS="${2}"
      else
        printf "${red}Error: ${white} no argument supplied for -x${normal}\n"
        exit 1
      fi
      shift 2
      ;;
    *)
      action="show_usage"
      break
      ;;
  esac
done

case ${action} in
  run_update)
    run_update
    ;;
  show_version)
    show_version
    ;;
  *)
    show_usage
    ;;
esac

exit 0