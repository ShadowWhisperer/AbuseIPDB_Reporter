#!/bin/bash

#
## https://www.abuseipdb.com/api.html
## https://www.abuseipdb.com/account/api
## https://www.abuseipdb.com/categories
#


# Set your API key #
####################
API_KEY="api-key"



#Colors
bn='\033[0;33m' #Brown
lb='\033[1;34m' #Light Blue
cn='\033[0;36m' #Cyan
lc='\033[1;36m' #Light Cyan
gn='\033[0;32m' #Green
lg='\033[1;32m' #Light Green
lp='\033[1;35m' #Light Purple
lr='\033[1;31m' #Light Red
yw='\033[1;33m' #Yellow
nc='\033[0m'    #No Color


function Help {
echo -e "
Usage: ./report.sh [OPTIONS]


Options: ${lr}*${nc} Must set all options

  ${lb}-i IP${nc}         IP to report
  ${cn}-c Category${nc}   Category number
  ${gn}-r Reason${nc}     Report details   ${lr}*${nc} Use \"\" or '' if contains space


Examples:
   ./report.sh ${lb}-i 0.0.0.0${nc} ${cn}-c 20${nc} ${gn}-r 'Malware, Bitcoin Miner'${nc}
   ./report.sh ${lb}-i 0.0.0.0${nc} ${cn}-c 15,22${nc} ${gn}-r 'Botnet, attacked SSH server'${nc}


No Flags:  ${lr}*${nc} Order matters, quotes do not
   ./report.sh ${lb}0.0.0.0${nc} ${cn}20${nc} ${gn}Malware, Bitcoin Miner${nc}
   ./report.sh ${lb}0.0.0.0${nc} ${cn}15,22${nc} ${gn}Botnet, Attacked SSH server${nc}




 Report Categories      https://www.abuseipdb.com/categories
==========================================================================
1  ${lp}DNS Compromise${nc}     9  ${lb}Open Proxy${nc}      17  Spoofing
2  ${lp}DNS Poisoning${nc}     10  ${bn}Web Spam${nc}        18  ${lc}Brute-Force${nc}
3  ${yw}Fraud Orders${nc}      11  ${bn}Email Spam${nc}      19  Bad Web Bot
4  ${lr}DDoS Attack${nc}       12  ${bn}Blog Spam${nc}       20  ${lg}Exploited Host${nc}
5  ${lc}FTP Brute-Force${nc}   13  ${lb}VPN IP${nc}          21  ${lg}Web App Attack${nc}
6  ${lr}Ping of Death${nc}     14  Port Scan       22  ${lc}SSH${nc}
7  ${yw}Phishing${nc}          15  ${lg}Hacking${nc}         23  ${lg}IoT Targeted${nc}
8  ${yw}Fraud VoIP${nc}        16  ${lg}SQL Injection${nc}

"
exit 0
}

clear
echo

#Requirements
if [[ "$API_KEY" == 'api-key' ]] || [[ -z "$API_KEY" ]]; then echo 'API Key not defined.' >&2 && exit 1; fi
if ! [ -x "$(command -v curl)" ]; then echo '"curl" is not installed.' >&2 && exit 1; fi



#############################################################################################################
# Set Arguements
#############################################################################################################

#No arguments
if [[ -z "$1" ]]; then Help; fi

#Terminal inputs
while getopts "hi:c:r:" opt; do
  case $opt in
    h) Help ;;
    i) IP=$OPTARG ;;
    c) CATEGORY=$OPTARG ;;
    r) REASON=$OPTARG ;;
    \?) echo "Invalid flag: -$OPTARG" >&2 && exit 1 ;;
    :) echo "Option -$OPTARG requires an argument." >&2 && exit 1 ;;
  esac
done

#Not Using Flags
if [[ "$1" =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
 IP="$1"
 CATEGORY="$2"
 args=("$@")
 REASON=("${args[@]:2}")
 REASON=$(printf "%s " "${REASON[@]}")
 REASON="$(awk '$1=$1' <<< "$REASON")"
fi


#############################################################################################################
# Check Arguements
#############################################################################################################

#Check IP
if [[ -z "$IP" ]]; then echo "IP not specified." >&2 && exit 1; fi
if [[ $IP =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
 IFS='.' read -r -a octets <<< "$IP"
 for octet in "${octets[@]}"; do
   if [ $octet -gt 255 ]; then echo "$IP is not a valid IP address." >&2 && exit 1; fi
 done
else echo "$IP is not a valid IP address." >&2 && exit 1
fi

#Check Category Number(s)
if [ -z "$CATEGORY" ]; then echo "\"Category\" number is not set. \"-h\" to show Category list" >&2 && exit 1; fi
if [[ "$CATEGORY" =~ ^[0-9]+$ ]]; then
 if [[ "$CATEGORY" -lt 1 || "$CATEGORY" -gt 23 ]]; then echo "\"Category\" number is not a valid category number. \"-h\" to show Category list" >&2 && exit 1; fi
else
 IFS=',' read -ra categories <<< "$CATEGORY"
 for category in "${categories[@]}"; do
  if ! [[ "$category" =~ ^[0-9]+$ ]]; then echo "\"Category\" input is not a number. \"-h\" to show Category list" >&2 && exit 1
   elif [[ "$category" -lt 1 || "$category" -gt 23 ]]; then
    echo "\"Category\" number is not a valid number. \"-h\" to show Category list" >&2 && exit 1
  fi
 done
fi

#Check Reason
if [ -z "$REASON" ]; then echo "\"Reason\" is not set. Why is this IP being reported?" >&2 && exit 1; fi
if [ ${#REASON} -lt 2 ]; then echo "\"Reason\" must be longer" >&2 && exit 1; fi


#############################################################################################################
# Submit Report
#############################################################################################################

#Send report to AbuseIPDB
RESPONSE="$(curl -s -X POST "https://api.abuseipdb.com/api/v2/report" -d "ip=$IP" -d "categories=$CATEGORY" -d "comment=$REASON" -H "Key: $API_KEY" -H "Accept: application/json")"

#Check for report errors
CHECK=$(echo "$RESPONSE" | grep -o "abuseConfidenceScore")
if [ ! -z "$CHECK" ]; then echo -e "${lg}IP address reported successfully.${nc}"
 else
 echo -e "${lr}Failed to send report !${nc}"
 echo
 echo "$RESPONSE"
fi

echo
echo
