#!/usr/bin/env bash

title="iMirror"
version="0.4"

info() {
    echo -e ${title}"\nVersion: "${version}
}

usage() {
    info
    echo -e "\nUsage:\n"$0" -s=192.168.16.4 -w=/workspace/ -d=/var/www/  -v -m=700 -o=user:group -n\n\nOptions:
\t-m\t--chmod\t\t\tChmod Transfered Files on Server to permission#[Default: 750]
\t-o\t--chown\t\t\tChown Transfered Files on Server to user:group[Default: Current USer:Current User's Group]
\t  \t--debug\t\t\tSets Bash Debug Flag
\t-d\t--docroot\t\tMirror's Target SRC[Default: Current User's Home]
\t-x\t--exclude\t\tComma-Seprated List of Filename Patterns to ignore(Hidden Files will Always be Excluded)[Default: .conf,.mwb]
\t-h\t--help\t\t\tShows this Message & Exits
\t-n\t--notify\t\tNotifies about Completed Transfers via NotifyOSD
\t-p\t--port\t\t\tServer SSH Port
\t-s\t--server\t\tServer IP Address[Default: 192.168.1.6]
\t-u\t--username\t\tSSH Username[Default: Current User]
\t-t\t--watch\t\t\tComma-Seprated List of Events which Fire the Mirroring[Default: CLOSE_WRITE]
\t-w\t--workspace\t\tMirror's From SRC[Default: Current User's Home]
\t-v\t--verbose\t\tBe More Verbose
\t-V\t--version\t\tDisplays Version & Exists
\n\tNote: All Path should end with a trailing slash"
    exit 1
}

[[ $# -eq 0 ]] && usage

debug=0
chmod=0
chown=0
notify=0
verbose=0
exclude=0

workspace=$HOME/
devServer="192.168.1.6"
devServerPort=22
devServerUser=`whoami`
devW3DocRoot=$HOME/
devW3Owner=`whoami`:`whoami`
devW3Perms=750

excludeWorkspace=( "W3Documents" "ServerManual" ".mwb" )
watchEvents="CLOSE_WRITE"

while [ $# -gt 0 ]
do
    argValue=${1#*=}
    case "$1" in
	--debug) debug=1; set -x;;
	--version|-V) info && exit 0;;
	--help|-h) usage;;
	--chmod=*|-m=*) chmod=1
	    devW3Perms=${argValue};;
	--chmod|-m) chmod=1;;
	--chown=*|-o=*) chown=1
	    devW3Owner=${argValue};;
	--chown|-o) chown=1;;
	--docroot=*|-d=*) devW3DocRoot=${argValue};;
	--exclude=*|-x=*) exclude=1
	    ;; #excludeWorkspace=${argValue};;
	--exclude|-x) exclude=1;;
	--notify|-n) notify=1;;
	--port=*|-p=*) devServerPort=${argValue};;
	--server=*|-s=*) devServer=${argValue};;
	--username=*|-u=*) devServerUser=${argValue};;
	--watch=*|-t=*) ;;#watchEvents=${argValue};;
	--workspace=*|-w=*) workspace=${argValue};;
	--verbose|-v) verbose=1;;
	*) usage;;
    esac
    shift
done

[[ ${devServer} = "" ]] && usage

clear

if [[ ${verbose} -gt 0 ]]
then
    MSG=""
    MSG="Watch: "${workspace}" For: "${watchEvents}" Files, Ignore: "${excludeWorkspace[@]}" Patterns"
    echo ${MSG}
    MSG=""
    MSG="Mirror To: "${devServerUser}"@"${devServer}":"${devServerPort}":"${devW3DocRoot}
    echo ${MSG}
    MSG=""
    if [[ ${chown} -gt 0 ]]; then
	MSG="Change Owner To: "${devW3Owner}
    fi
    if [[ ${chmod} -gt 0 ]]; then
	if [[ -n ${MSG} ]]; then
	    MSG=${MSG}" "
	fi
	MSG=${MSG}"With: "${devW3Perms}" Permissions"
    fi
    if [[ -n ${MSG} ]]; then
	echo ${MSG}
    fi
    MSG="Notify on Success"
    if [[ ${notify} -eq 0 ]]; then
	MSG="Do NOT "${MSG}
    fi
    echo ${MSG}
    echo "Begin"
    echo
fi

excludePattern="/\..+/"

watchOptions="-q --monitor --recursive"
watchEvents="--event "${watchEvents}

mirrorOptions="--relative --times --human-readable --rsh=ssh"
if [[ ${chmod} -gt 0 ]]; then
    if [[ ${chown} -gt 0 ]]; then
	mirrorOptions=${mirrorOptions}" --chmod="${devW3Perms}
    fi
fi
if [[ ${verbose} -gt 0 ]]; then
    mirrorOptions=${mirrorOptions}" --verbose --progress"
fi

mirrorLog=""

cd ${workspace}

excludeWorkspace_joined=$(printf "|%s" "${excludeWorkspace[@]}")
excludeWorkspace_joined=${excludeWorkspace_joined:1}
excludePattern_effective="("${excludePattern}")|"${excludeWorkspace_joined}

watchOptions=${watchOptions}" --exclude "${excludePattern_effective}

inotifywait ${watchOptions} ${watchEvents} --timefmt '%d/%m/%y %H:%M' --format '%T %:e %w %f' ${workspace} | \
    while read iDate iTime iEvent iDir iFile; do
    iPath=${iDir}${iFile}
    iPath_relativeToWS=`echo "${iPath}" | sed 's_'${workspace}'__'`
    echo ${iPath_relativeToWS}" "${iEvent}"@"${iDate}" "${iTime}
    
    mirrorURL=${devServerUser}@${devServer}:${devW3DocRoot}
    if [ -e ${iPath_relativeToWS} ]; then
	rsync ${mirrorOptions} ${iPath_relativeToWS} ${mirrorURL} && \
	    echo ">> Mirrored" && \
	    echo && \
	    { if [[ ${notify} -gt 0 ]]; then notify-send -t 1000 -i "network-transmit" "Mirrored@`date`" ${iPath_relativeToWS}; fi }
	remoteURL=${devW3DocRoot}${iPath_relativeToWS}
	if [[ ${chown} -gt 0 ]]; then
	    if [[ ${chmod} -gt 0 ]]; then
		ssh ${devServerUser}@${devServer} "chown "${devW3User}":"${devW3Group}" "${remoteURL}" && chmod "${devW3Perms}" "${remoteURL} && \
		    echo ">> CH[Ownd|Mod]ed"
	    fi
	fi
    fi
done




exit 0

