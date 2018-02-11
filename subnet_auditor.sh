#!/bin/bash
#
# This is the parser of connected subnets in Cisco/Juniper/Huawei configs.
#
# You need to be rude.
if [ "$EUID" -ne 0 ]
  then echo -e "\033[36;1;41m Run as root please. \033[0m"
  exit
fi
##################################################################
MODELS="c4900|c4948|c6509|ce5855|ce8850|ex4500|ex6210|ex8216|mx2010|mx2020|mx960|n56128|n7010|n7018|n93180|n9508|qfx5100"
WORKDIR="/usr/local/rancid/var/*/configs/"
EXISTING_NODES=`cat /etc/hosts | egrep $MODELS | awk '{ print $2 }' | tr '\n' '|'`
configs=`find $WORKDIR \( ! -regex '.*/\..*' \) | egrep $MODELS | egrep $EXISTING_NODES`
##################################################################
function analyzer()
{
device=`echo ${1} | awk -F'/' '{ print $NF }'`
  if [[ ${1} == *"n56128"* ]] || [[ ${1} = *"n7018"* ]] || [[ ${1} = *"n93180"* ]] || [[ ${1} = *"n7010"* ]] || [[ ${1} = *"n9508"* ]]; then
    ip4=`gawk '/^interface Vlan/{flag=1;next}/^$/{flag=0}flag' ${1} | egrep "ip address.*\..*" | gawk '{ print $3 }'`
    ip6=`gawk '/^interface Vlan/{flag=1;next}/^$/{flag=0}flag' ${1} | egrep "ipv6 address.*:.*" | gawk '{ print $3 }'`
  fi
  if [[ ${1} = *"c4900"* ]] || [[ ${1} = *"c4948"* ]] || [[ ${1} = *"c6509"* ]]; then
    ip4=`gawk '/^interface Vlan/{flag=1;next}/^!$/{flag=0}flag' ${1} | egrep "ip address.*\..*" | gawk '{ print $3 " " $4 }'`
    ip6=`gawk '/^interface Vlan/{flag=1;next}/^!$/{flag=0}flag' ${1} | egrep "ipv6 address.*:.*" | gawk '{ print $3 }'`
  fi
  if [[ ${1} = *"ex4500"* ]] || [[ ${1} = *"ex6210"* ]] || [[ ${1} = *"ex8216"* ]]; then
    ip4=`gawk '/^    vlan \{/{flag=1;next}/^    \}$/{flag=0}flag' ${1} | egrep "address.*\..*" | sed 's/;//g' | gawk '{ print $2 }'`
    ip6=`gawk '/^    vlan \{/{flag=1;next}/^    \}$/{flag=0}flag' ${1} | egrep "address.*:.*" | sed 's/;//g' | gawk '{ print $2 }'`
  fi
  if [[ ${1} = *"qfx5100"* ]]; then
    ip4=`gawk '/^    irb \{/{flag=1;next}/^    \}$/{flag=0}flag' ${1} | egrep "address.*\..*" | sed 's/;//g' | gawk '{ print $2 }'`
    ip6=`gawk '/^    irb \{/{flag=1;next}/^    \}$/{flag=0}flag' ${1} | egrep "address.*:.*" | sed 's/;//g' | gawk '{ print $2 }'`
  fi
  if [[ ${i} = *"ce5855"* ]] || [[ ${i} = *"ce8850"* ]]; then
    ip4=`gawk '/^interface Vlanif/{flag=1;next}/^#$/{flag=0}flag' ${1} | egrep "ip address.*\..*" | gawk '{ print $3 " " $4 }'`
    ip6=`gawk '/^interface Vlanif/{flag=1;next}/^#$/{flag=0}flag' ${1} | egrep "ipv6 address.*:.*" | gawk '{ print $3 }'`
  fi
  ##
  if [[ ${i} = *"mx2010"* ]] || [[ ${i} = *"mx2020"* ]] || [[ ${i} = *"mx960"* ]]; then
    ip4=`gawk '/^    irb \{/{flag=1;next}/^    \}$/{flag=0}flag' ${1} | egrep "address.*\..*" | sed 's/;//g' | gawk '{ print $2 }'`
    ip6=`gawk '/^    irb \{/{flag=1;next}/^    \}$/{flag=0}flag' ${1} | egrep "address.*:.*" | sed 's/;//g' | gawk '{ print $2 }'`
  fi
    sipcalc ${ip4} | egrep "Network address|bits" | sed 's/(bits)//g;' | awk '{ print $4 }' | sed 'N;s/\n/\//' | gawk -v dev=$device '{ print "\x22" $0 "\x22: " "\x22"dev "\x22," }'
    sipcalc ${ip6} | egrep "Subnet prefix" | cut -f4 -d" " | gawk -v dev=$device '{ print "\x22" $0 "\x22: " "\x22"dev "\x22," }'
}
##################################################################
export -f analyzer
echo "${configs}" | xargs -n 1 -P 10 -I {} bash -c 'analyzer "$@"' _ {}
exit 0
