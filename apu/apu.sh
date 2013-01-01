#!/bin/sh

# Automatic Perl Upgrader
# upgrades Perl to a specified version in all active jails
#
# Copyright (c) 2012, 2013 Jesco Freund <mail@daemotron.net>
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


cyan="\033[36m"
magenta="\033[35m"
red="\033[1;31m"
amber="\033[1;33m"
green="\033[1;32m"
white="\033[1;37m"
normal="\033[0m"

MODE=1
PORTMASTER_FLAGS="-dB --no-confirm"
PORTS_DIR="/usr/ports/lang"

# FUNCTIONS

show_usage() {
        local FLAGS="[-hnqv]"
        if [ "${MODE}" -eq "1" ]
        then
                local USG="${red}usage: ${green}$($b_basename ${0}) ${normal}${FLAGS} [version]"
        else
                local USG="usage: $($b_basename ${0}) ${FLAGS} [version]"
        fi
        echo -e "$USG

   -h   show this help and exit
   -v   show version information and exit
   -n   do not use color escape sequences in output
   -q   quiet mode: write portmaster output to file
   
   version
        upgrade perl interpreter to indicated version.
        Expected format: x.yy (like in ports directory)

Please report any issues like bugs etc. via the root-tools bug tracking
tool available at https://github.com/RootForum/bsd-scripts/issues" >&2 && exit 0
}


show_version() {
        if [ -z "$VERSION" ]
        then
                local VER="development version r${revstring}"
        else
                local VER="$VERSION"
        fi
        echo "`$b_basename $0` ${VER}

Copyright (c) 2012, 2013 Jesco Freund <mail@daemotron.net>
License: ISCL: ISC License <http://www.opensource.org/licenses/isc-license.txt>
This is free software: you are free to change and redistribute it.
There is NO WARRANTY, to the extent permitted by law.

Written by Jesco Freund." >&2 && exit 0
}


get_jails() {
        local jails="$($b_jls | $b_awk '/[0-9]+/ {print $1}' | $b_sort -n)"
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


upgrade_jails() {
	local ldir="${PORTS_DIR}/perl${1}"
        for i in $(get_jails)
        do
                local jname=$($b_jls | $b_grep -E "^[[:space:]]*${i}[[:space:]]" | $b_awk '{print $3}')
                local str="${cyan}Updating jail ${i}: ${magenta}${jname}${normal}\n"
                printf "${str}"
                pm=$(test_portmaster)
                if [ "$pm" = "True" ]
                then
                        local p_version=$($b_jexec $i $b_pkg_info | $b_awk '/perl-/ {print $1}'  | $b_sed 's/perl.*\-//g' | $b_awk -F '.' '{print $1"."$2}')
                        if [ "$p_version" = "$1" ]
                        then
                                echo -e "${green}Info: ${white}nothing to be done - installed Perl version is already ${1}.${normal}"
                        else
                                if [ -z "$p_version" ]
                                then
                                        echo -e "${green}Info: ${white}Perl not installed in this jail.${normal}"
                                else
                                        local tdir=$($b_jls -j $i path)
                                        tdir="${tdir}${ldir}"
                                        if [ -d "${tdir}" ]
                                        then
                                                $b_jexec $i $b_portmaster ${PORTMASTER_FLAGS} -o lang/perl${1} lang/perl${p_version}
                                                $b_jexec $i $b_portmaster ${PORTMASTER_FLAGS} -r perl-
                                                echo -e "${green}Success: ${white}updated perl from $p_version to ${1}.${normal}"
                                        else
                                                echo -e "${red}Error: ${white}port for Perl version $1 does not exist.${normal}"
                                        fi
                                fi
                        fi
                else
                        echo -e "${red}Error: ${white}portmaster not available in this jail.${normal}"
                fi
                echo
                echo
        done
}


# TEST ARGUMENTS

if [ "$#" -lt "1" ]
then
        show_usage
        exit 1
fi

action="upgrade_jails"

while [ "$#" -gt "1" ]
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
                -h|--help)
                        action="show_usage"
                        shift
                        ;;
                *)
                        action="show_usage"
                        break
                        ;;
        esac
done


case ${1} in
        -v|--version)
                action="show_version"
                ;;
        -h|--help)
                action="show_usage"
                ;;
        *)
                target_version=$(echo ${1} | $b_grep -E '[0-9]{1}\.[0-9]{2}' | $b_awk -F '.' '{print $1"."$2}')
                ;;
esac
                

case ${action} in
        show_version)
                show_version
                ;;
        show_usage)
                show_usage
                ;;
        upgrade_jails)
                upgrade_jails "${target_version}"
                ;;
        *)
                show_usage
                ;;
esac

exit 0

