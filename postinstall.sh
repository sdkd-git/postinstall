#!/bin/bash
################################################################################
#Set Colour Schemes
RED='\033[0;31m'
YLLO='\033[1;33m'
LCYAN='\033[1;36m'
LGRN='\033[1;32m'
NC='\033[0m' # No Color
#Variables
installpkg='ansible git openssh-server'
################################################################################
cat <<"EOF"
                           (   (        ) (
                           )\ ))\ )  ( /( )\ )
                          (()/(()/(  )\()|()/(
                           /(_))(_))((_)\ /(_))
                          (_))(_))_|_ ((_|_))_
                          / __||   \ |/ / |   \
                          \__ \| |) |" <  | |) |
                          |___/|___/_|\_\ |___/
################################################################################
Author: Saideep Kavidi
Github: https://github.com/sdkd-git/
License: MIT License

This script can be used for post installation of Ubuntu 16.04 64bit OS for now.
Uncomment the packages you want to install from ansible/main.yml.
Make Sure you have customized Anisble-Playbook as per your requirement before
you begin the installation.
################################################################################
EOF
################################################################################
#Command exits with a nonzero exit value
set -e
#Check is user is running with permission
if ! [ $(id -u) = 0 ]; then
  echo -e "\n${YLLO}The script need to be run as root.${NC}" >&2
  exit 1
fi
#Generate Log File
logfile='/tmp/postinstall.log'
echo -e "\n \n \n \n$(date)\n$(uname -nir)\n" >> $logfile
#check for internet connectivity
echo -e "${LCYAN}Checking internet connectivity\n${NC}"
pngint="$(ping 8.8.8.8 -c 1 -W 4 -q)"
if [ $? -eq 0 ];
then
  echo -e "${LGRN}Connected to internet.\n${NC}"
else
  echo -e "${RED}Could not connect to internet. Stopping further actions..!\n${NC}" >&2
  exit 2
fi
dnsping="$(ping google.com -c 1 -W 4 -q)"
if ! [ $? = 0 ];
then
  echo -e "${RED}Could not resolve DNS. Stopping further actions..!\n${NC}" >&2
  exit 3
fi
################################################################################
#Create Temporary storage directory
echo -e "${YLLO}Cleaning previous Installation traces${NC}\n"
rm -rf /tmp/postinstall
mkdir -p /tmp/postinstall
################################################################################
#Script for auto update/autoremove and dist-upgrade.
apt-get update >> $logfile
if [ $? = 0 ]; then
  echo -e "${LGRN}Repository update Completed\n"
else
  echo -e "${RED}Repository Update failed\nExiting Installtion..!\n${NC}" >&2
  exit 4
fi
#Disabled for testing purpose
apt-get dist-upgrade -y >> $logfile
if [[ $? = 0 ]]; then
  echo -e "Upgrade completed\n"
else
  echo -e "${RED}Upgrade failed${NC}"
  exit 5
fi
################################################################################
#Repositories
ansirepo="/etc/apt/sources.list.d/ansible-ubuntu-ansible-xenial.list"
if [ ! -f "$checkansi" ]; then
  add-apt-repository -y ppa:ansible/ansible >> $logfile
  echo -e "${LGRN}Ansible Repository added successfully...!${NC}\n"
fi
apt-get update >> $logfile
#Install Packages
apt-get install $installpkg -y >> $logfile
if ! [ $? = 0 ];
  then
    echo -e "\n${LGRN} Installation failed for following packages $installpkg ${NC}\n" >&2
    echo -e "${RED} Stopping further actions..!${NC}\n" >&2
    exit 6
fi
#Check dependency packages and forcw install
echo -e "${YLLO}Checking and reinstalling for dependency packages${NC}\n"
apt-get install -f -y >> $logfile
apt-get autoremove -y >> $logfile
################################################################################
echo -e "Starting Ansible Playbook\n"
ansible-playbook ansible/main.yml | tee -a $logfile
################################################################################
#cleaning TemporaryFiles
echo -e "${YLLO}Cleaning Apt Cache${NC}"
apt-get -q clean
echo -e "${LGRN}APT Cache cleaned\n"
#Exit Message
echo -e "${LCYAN}Reboot system for applying changes.\n"
echo -e "${YLLO}Thanks for using the script...!\n"
