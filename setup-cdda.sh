#!/bin/bash
########################################################
# TODO:
# Line 117:	GIT DOWNLOADING PART
#		determine if the user entered basenamepath or
#		a downloadpath with added branch and getting
#		both separated. These are needed to (at least)
#		to enter the folder where cdda will be built.
#
# Line 202:	SWITCH CASE
#		Add cases 4 to 7 and the needed functions	
# 
# General:	UPDATE VARIABLE AND FUNCTION EXPLANATION
# 		Test LXC-Stuff
#		find a way to run the script in the chroot
########################################################
# Variables:
# wanted_cdda 		= CDDA Version to pull from GIT
# wanted_cdda_short	= shortname of Downloaded CDDA
# target_cdda 		= CDDA Target Download dir
# SCRIPTPATH		= Current working dir
# version		= scriptversion
# error			= set to 1 if target folder exists
# deperror		= set to value if dependency is missing
# packages		= list of packages to check
# missing		= list of missing packages
# criticalerror		= Critical error, pogram abort (or chosen exit)
# tasks			= List of available tasks
# task			= task to run
########################################################
# Strings:
# deperrormsg		= error message displayed if dep is missing
# depmissingmsg		= red formatted dependency missing message
# depokmsg		= green formatted dependency ok message
# welcomemsg		= welcome message
# continue		= standard waiting for input message
# novalmsg		= message that user-input is not as expeected
# getddalinkmsg		= message that asks for dda download link
########################################################
# Functions:
# check_packages()	= Checks for required packages in $packages
# dl_dda()		= downloads Cataclysm-DDA Source from git
# crit_err()		= Sets $criticalerror to 1
# comp_stuff()		= general compile command
# comp_dda()		= compile dda with comp_stuff()
# dl_dgamelaunch()	= should download dgamelaunch from git
########################################################
# version history:
# v.0.0.5 trying to implement lxc linux-containers for security
# v.0.0.4 pushed to github: https://github.com/veloc/cdda-scripts.git
# v.0.0.3 adding switch/case menu for task selection and creating functions (fr)
# v.0.0.2 added some colours and the check for required packages (fr)
# v.0.0.1 creation phase (fr)
########################################################

# STUFF
########################################################
# declaring variables
version="v.0.0.4"
error="0"
criticalerror="0"
packages="libncurses5-dev git-core g++ make autogen autoconf libncurses5 libncursesw5 libncursesw5-dev libncursesw5-dev bison flex sqlite3 libsqlite3-dev debootstrap lxc libvirt-bin dnsmasq-base screen"
checkdeptask="Check Dependencies"
tasks="Check_dependencies Download_Cataclysm-DDA Compile_Cataclysm-DDA Download_dgamelaunch Compile_dgamelaunch set-up_game Everything QUIT" 

#setting default values
defaultddagit="https://github.com/C0DEHERO/Cataclysm-DDA.git"
defaultdgamegit="https://github.com/C0DEHERO/dgamelaunch.git"
defaultddatarget="$HOME/CDDA/"
defaultdgametarget="$HOME/dgamelaunch/"

# strings
depmissingmsg="\e[31mMissing!\e[37m"
depokmsg="\e[32mInstalled!\e[37m"
welcomemsg="This script will (sometime in the future) download, [merge?,] compile and setup a chroot enviroment for Cataclysm-DDA with _shared Worlds_\n\nCurrent Version:\t$version\n\n"
continue="Press [Enter] key to continue, press [CTRL+C] to cancel."
getlinkmsgstr="Please enter the Version to clone as a Git Link, default is"
getddalinkmsg="$getlinkmsgstr [ $defaultddagit ]:"
getdgamelinkmsg="$getlinkmsgstr [ $defaultdgamegit ]:"
gettargetmsgstr="Please enter full target path for the download, default is"
getddatargetmsg="$gettargetmsgstr [ $defaultddatarget ]:"
getdgametarget="$gettargetmsgstr [ $defaultdgametarget ]:"
selected="You have selected "

# Error MSGs
generrormsg="\e[31mError\e[37m:"
nocddadirgiven="\e[31mError\e[37m: No CDDA Dir given. Please run Step (2) first!\n\n"
deperrormsg="$generrormsg Dependencies missing!\nPlease run the following command to install the missing dependencies and try again:\n\n\taptitude install $missing\n\n"
novalmsg="No valid Entry!"

# FUNCTIONS
########################################################
#lxc_cgroup()
#{
# clear
# printf "backing up /etc/fstab to /etc/fstab.backup!"  
# cp /etc/fstab /etc/fstab.backup
# if [ $? -ne 0 ]; then
#  printf "$generrormsg"
#  return 1
# fi
#
# printf "adding cgroup line to /etc/fstab"
# cat << EOF >> /etc/fstab
# cgroup  /sys/fs/cgroup  cgroup  defaults  0   0
# EOF
#
# printf "trying to mount /sys/fs/cgroup..."
# mount /sys/fs/cgroup 
# if [ $? -ne 0 ]; then
#  printf "$generrormsg"
#  return 1
# fi
#
#}
#
#lxc_mod_configs()
#{
# clear
# printf "replacing lenny with squeeze in debian lxc-template and changing server to http://ftp5.gwdg.de/pub/linux/debian/debian"
#sed 113s/.*/squeeze $cache/partial-$arch http://ftp5.gwdg.de/pub/linux/debian/debian" /usr/lib64/lxc/templates/lxc-debian
# if [ $? -ne 0 ]; then
#  printf "$generrormsg"
#  return 1
# fi
#
# printf "removing dhcp-client from package-list of container"
# sed 93d /usr/lib64/lxc/templates/lxc-debian
# if [ $? -ne 0 ]; then
#  printf "$generrormsg"
#  return 1
# fi
#
# printf "creating lxc-container network config dir"
# mkdir -p /lxc/cataclysm/
# if [ $? -ne 0 ]; then
#  printf "$generrormsg"
#  return 1
# fi
#
# printf "creating lxc-container network config file"
# cat << EOF > /lxc/cataclysm/config
# lxc.network.type = veth
# lxc.network.flags = up
# lxc.network.link = lxcbr0
# lxc.network.hwaddr = 00:FF:AA:00:00:01
# lxc.network.ipv4 = 192.168.123.2/24
# EOF
#
# printf "creating host-network bridge config to allow connection to the container"
# cat << EOF > /var/lib/libvirt/network/lxc.xml
# <network>
#  <name>lxc</name>
#  <uuid>e58bbb2b-4b27-807a-68c4-e182dcf47258</uuid>
#  <forward mode='nat'/>
#  <bridge name='lxcbr0' stp='off' delay='0' />
#  <ip address='192.168.123.1' netmask='255.255.255.0'>
#    <dhcp>
#      <range start='192.168.123.100' end='192.168.123.254' />
#    </dhcp>
#  </ip>
# </network>
# EOF
#}
#
#setup_lxc_container()
#{
# printf "setting up bridge and marking it for autostart"
# virsh -c lxc:/// net-define /etc/libvirt/qemu/networks/lxc.xml
# virsh -c lxc:/// net-startn lxc
# virsh -c lxc:/// net-autostart lxc
#
# printf "creating container, this may take some time"
# lxc-create -n cataclysm -t debbian -f /lxc/cataclysm/config
#}
#
#

check_packages() 
{
 clear
 printf "$selected $tasksel"
 printf "Now checking for dependencies...\n"
 read -p "$continue"

# checking for required packages:
 deperror="0"
 missing=""
 printf "Checking Dependencies:\n"
 for package in $packages
  do
   check=$(cat /var/lib/dpkg/status | grep Package | grep $package)
   if [ "" == "$check" ]; then
    missing+="$package "
    printf "%-20s%b\n" $package $depmissingmsg
    deperror="1"
   else
    printf "%-20s%b\n" $package $depokmsg
   fi
 done  

# Print a list of the missing packages
 printf "\nMissing Packages:\n$missing\n\n"

 if [ "$deperror" == "1" ]; then
  printf  "Shall we install the missing dependencies? (y)es or (n)o:\n"
  read installdeps

  if [ "$installdeps" == "n" ]; then
   criticalerror="1"
   printf "$deperrormsg"

  elif [ "$installdeps" == "y" ]; then
   printf "installing dependencies:\n$missing\n"
   read -p "$continue"
   aptitude install $missing

  else
   printf "$novalmsg"
  fi

 else
 read -p "Deperror says $deperror, $continue"
 fi
}

clone_stuff()
 {
  clear
  if [ "$tasksel" == "2" ]; then # selected cdda to clone
   getlinkmsg="$getddalinkmsg"
   defaultgit=$defaultddagit
   gettargetmsg="$getddatargetmsg"
   defaulttarget="$defaultddatarget"

  elif [ "$tasksel" == "4" ]; then # selected dgamelaunch to clone
   getlinkmsg="$getdgamelinkmsg"
   defaultgit="$defaultdgamegit"
   gettargetmsg="$getdgametargetmsg"
   defaulttarget="$defaultdgametarget"

  else
   printf "$novalmsg"
  fi

# What version shall we download?
#  echo "please enter the desired CDDA-Version (Git Link, default is [ https://github.com/C0DEHERO/Cataclysm-DDA.git ]):"

  printf "$getlinkmsg"
  read wanted
  [ -z "$wanted" ] && echo -e "$novalmsg We will use $defaultgit\n" || echo -e "You entered $wanted\n" 
# getting the short version of the Git Repo

  if [ "$(echo $wanted | wc -w)" == "1" ]; then
   wanted_short=$(basename $wanted .git)

  elif [ "$(echo $wanted | wc -w)" == "2" ]; then
   wanted_branch=$(echo "$wanted" | awk '{ print $(NF) }')
   wanted=$(echo "$wanted" | awk '{ print $(1) }')
   wanted_short=$(basename $wanted .git)

  else
   printf "$novalmsg Using the default..."
   wanted="$defaultgit"
   wanted_short=$(basename $wanted .git)
  fi

  if [ "$tasksel" == "2" ]; then # selected cdda to clone
   wanted_cdda="$wanted_short"
   target_cdda="$target"

  elif [ "$tasksel" == "4" ]; then # selected dgamelaunch to clone
   wanted_dgame="$wanted_short"
   target_dgame="$target"

  else
   printf "$novalmsg"
  fi

# Where shall we download it to?
#  echo "please enter full target path for the CDDA download, default is [ $HOME/CDDA/ ]:"
  printf "$gettargetmsg"
  read target
  [ -z "$target" ] && echo -e "$novalmsg We will use $defaulttarget\n" || echo -e "You entered $target\n"
  if [$target == ""]; then
   target="$defaulttarget"
  fi

# now summarizing settings
  printf "\nChosen Settings:"

  if [ -n "$wanted_branch" ]; then
   printf "\nDownload Version:\t$wanted\nBranch: $wanted_branch"
  else
   printf "\nDownload Version:\t$wanted"
  fi 

  printf "\nTarget Directory:\t$target"

# check if folder settings are valid
# todo: - check if entry is spelled correctly
# 	- option to clear target folder
  echo -e "\nChecking for existing folder...\n"
  if [ -d "$target" ]; then
   echo -e "\n$target allready exists!\n"
   error="1"
  else 
   echo -e "\n$target will be created!\n"
  fi

# ask user, if settings are ok
  read -p "$continue"

# create target folder
  if [ "$error" == "1" ]; then
   echo -e "\nAborting because $target allready exists..."
  else
   echo -e "\nCreating $target\n"
   mkdir -p "$target"
   cd "$target"
   echo -e "\n Now cloning $wanted into $target\n"

   if [ -n "$wanted_branch" ]; then
    git clone -b $wanted_branch $wanted $target
   else
    git clone $wanted $target
   fi 
  fi
 }

crit_err()
 {
  criticalerror="1"
  printf "Exiting, Good Bye!\n\n"
 }

compile_stuff()
 {
  cd $target_dir
  make
 }

comp_cdda()
 {
  clear
  if [ -n "$target_cdda" ]; then
   printf "$nocddadirgiven\n Trying default: $defaultddatarget"
   target_cdda="$defaultddatarget"
  elif [ -n "wanted_cdda" ]; then
   printf "\nNo wanted CDDA given\n\n"
   wanted_cdda=$
  else
   printf "Will now compile $wanted_cdda in $target_cdda"
   target_dir="$target_cdda"
   compilestuff
  fi
 }


# MORE STUFF
########################################################
# Welcome
clear
echo -e $welcomemsg
read -p "$continue"
printf "\n"

# EXITING STUFF
########################################################

# CHECKING FOR ROOT PRIVILEGUES
if [ "$(id -u)" != "0" ]; then
    echo "This script should be run as 'root'"
    exit 1
fi

# BEGINNING MAIN WHILE LOOP
while [ "$criticalerror" == "0" ]
 do

# generating task list
  tasksel=0		# setting $tasksel to 0 to be able to count the tasks 
  for task in $tasks
   do
    tasksel=$((tasksel +1))
    printf "($tasksel) - %b\n" $task 
  done
  tasksel=1		# setting $tasksel to 1 to be the default task
  printf "\n"
  printf "Please make your selection by entering the coresponding number, default is [1]: "
  read tasksel

  if [ "$tasksel" == "" ]; then
   tasksel="1"
  fi

#switch case for task selection
  case "$tasksel" in
   1) check_packages;;
   2) clone_stuff;;
   3) comp_cdda;;
   4) clone_stuff;;
   8) crit_err;;
   *) printf "\n$generrormsg $novalmsg No valid Entry, please try again\n";;
  esac 

done
