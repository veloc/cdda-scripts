#!/bin/bash
########################################################
# TODO:
# General:	UPDATE VARIABLE AND FUNCTION EXPLANATION
#		find a way to run the script in the chroot
#		adapt dgl-create-chroot to not create a chroot but
#		 use the lxc-container instead.
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
version="v.0.0.5"
error="0"
criticalerror="0"
packages="libncurses5-dev git-core g++ make autogen autoconf libncurses5 libncursesw5 libncursesw5-dev libncursesw5-dev bison flex sqlite3 libsqlite3-dev"
lxc_packages="sed debootstrap lxc libvirt-bin dnsmasq-base screen"
checkdeptask="Check Dependencies"

main_menu_list="LXC_Menu DDA_Menu Everything(NOT_WORKING!) QUIT"
dda_tasks="Chroot_to_LXC-Container Check_dependencies Download_Cataclysm-DDA Compile_Cataclysm-DDA Download_dgamelaunch Compile_dgamelaunch set-up_game Everything Main_Menu QUIT"
lxc_tasks="Check_LXC_Dependencies Setup_LXC_CGroup Generate_and_modify_LXC_configs Setup_LXC_Container Main_Menu QUIT"

bridge_config_file="/etc/libvirt/qemu/networks/lxc.xml"

#setting default values
defaultddagit="https://github.com/C0DEHERO/Cataclysm-DDA.git"
defaultdgamegit="https://github.com/C0DEHERO/dgamelaunch.git"
defaultddatarget="/var/lib/lxc/cataclysm/rootfs/opt/CDDA/"
defaultdgametarget="/var/lib/lxc/cataclysm/rootfs/opt/DDA/dgamelaunch/"

# strings
depmissingmsg="\e[31mMissing!\e[37m"
depokmsg="\e[32mInstalled!\e[37m"
welcomemsg="This script will (sometime in the future) download, [merge?,] compile and setup a chroot enviroment for Cataclysm-DDA with _shared Worlds_\n\nCurrent Version:\t$version\n\n"
continue="Press [Enter] key to continue, press [CTRL+C] to cancel."

getlinkmsgstr="Will now clone"
ddalinkmsg="$getlinkmsgstr $defaultddagit into $defaultddatarget\n"
dgamelinkmsg="$getlinkmsgstr $defaultdgamegit into $defaultdgametarget\n"

selected="You have selected "

# Error MSGs
generrormsg="\e[31mError\e[37m:"
nocddadirgiven="\e[31mError\e[37m: No CDDA Dir given. Please run Step (2) first!\n\n"
deperrormsg="$generrormsg Dependencies missing!\nPlease run the following command to install the missing dependencies and try again:\n\n\taptitude install $missing\n\n"
novalmsg="No valid Entry!"

# FUNCTIONS
########################################################
# MENUS
########################################################

main_menu()
{
# generating task list
  printf "\n"
  tasksel=0		# setting $tasksel to 0 to be able to count the tasks 
  for task in $main_menu_list
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
   1) lxc_menu;;
   2) dda_menu;;
   3) all_stuff;;
   9) crit_err;;
   *) printf "\n$generrormsg $novalmsg No valid Entry, please try again\n";;
  esac 
}

dda_menu()
{
 printf "\n"
# generating task list
  tasksel=0		# setting $tasksel to 0 to be able to count the tasks 
  for task in $dda_tasks
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
   1) chroot_to_lxc;;
   2) check_dda_packages;;
   3) clone_dda;;
   4) comp_cdda;;
   5) clone_dgame;;
   6) comp_dgame;;
   7) setup_game;;
   8) dda_all;;
   9) main_menu;;
   10) crit_err;;
   *) printf "\n$generrormsg $novalmsg No valid Entry, please try again\n";;
  esac
}

lxc_menu()
{
while [ "$criticalerror" == "0" ]
 do
  printf "\n"
# generating task list
  lxc_tasksel=0             # setting $tasksel to 0 to be able to count the tasks
  for lxc_task in $lxc_tasks	# this is for setting a task "do all"
   do
    lxc_tasksel=$((lxc_tasksel +1))
    printf "($lxc_tasksel) - %b\n" $lxc_task
  done
  lxc_tasksel=1             # setting $tasksel to 1 to be the default task
  printf "\n"
  printf "Please make your selection by entering the coresponding number, default is [1]: "
  read lxc_tasksel

  if [ "$lxc_tasksel" == "" ]; then
   lxc_tasksel="1"
  fi
 
#switch case for lxc task selection
  case "$lxc_tasksel" in
   1) check_lxc_packages;;
   2) lxc_cgroup;;
   3) lxc_mod_configs;;
   4) setup_lxc_container;;
   5) main_menu;;
   9) crit_err;;
   *) printf "\n$generrormsg $novalmsg No valid Entry, please try again\n";;
  esac 
done
}

###############################################
# LXC Stuff
###############################################

check_lxc_packages() 
{
 clear
 printf "$selected to check for LXC Dependencies.\n"
 printf "Now checking for dependencies...\n"
 read -p "$continue"

# checking for required packages:
 deperror="0"
 lxc_missing=""
 printf "Checking Dependencies:\n"
 for lxc_package in $lxc_packages
  do
   check=$(cat /var/lib/dpkg/status | grep Package | grep $lxc_package)
   if [ "" == "$check" ]; then
    lxc_missing+="$lxc_package "
    printf "%-20s%b\n" $lxc_package $depmissingmsg
    deperror="1"
   else
    printf "%-20s%b\n" $lxc_package $depokmsg
   fi
 done  

# Print a list of the missing packages
 printf "\nMissing Packages:\n$lxc_missing\n\n"

 if [ "$deperror" == "1" ]; then
  installdeps=""
  printf  "Shall we install the missing dependencies? (y)es or (n)o:\n"
  read installdeps

  if [ "$installdeps" == "n" ]; then
   criticalerror="1"
   printf "$deperrormsg"

  elif [ "$installdeps" == "y" ]; then
   printf "installing dependencies:\n$lxc_missing\n"
   read -p "$continue"
   aptitude install $lxc_missing

  else
   printf "$novalmsg"
  fi

 else
 read -p "Deperror says $deperror, $continue"
 fi
}

lxc_cgroup()
{
 clear
 fstab="/etc/fstab"
 fstab_backup="/etc/fstab.backup.lxc_cgroup"

 printf "$selected to set up the cgroup-Mountpouint for LXC.\n"

 if [ "$(cat $fstab | grep cgroup)" == "" ]; then
  target="$fstab_backup"
  check_target_file
  printf "backing up $fstab to $fstab_backup!\n\n"  
  cp $fstab $fstab_backup

  if [ $? -ne 0 ]; then
   printf "$generrormsg: Failed to copy $fstab to $fstab_backup"
   return 1
  fi

  printf "adding cgroup line to $fstab...\n\n"
cat << EOF >> /etc/fstab
cgroup  /sys/fs/cgroup  cgroup  defaults  0   0
EOF

  printf "trying to mount /sys/fs/cgroup...\n\n"
  mount /sys/fs/cgroup 

  if [ $? -ne 0 ]; then
   printf "$generrormsg: Mounting failed!\n\n"
   return 1
  fi

 else
  printf "Skipping modification to $fstab:\nThere seemes to be a cgroup mountpoint allready!\n"

 fi 
 read -p "$continue"
}

lxc_mod_configs()
{
 clear
 lxc_template="/usr/lib64/lxc/templates/lxc-debian"
 lxc_temp="/tmp/lxc-debian"
 gwdg="http://ftp5.gwdg.de/pub/linux/debian/debian"

 printf "$selected to modify the debian template generation file and create a config file for the network of the container\n\n"
 printf "Modifying $lxc_template... "

 if [ -f "$lxc_template" ]; then
  cp $lxc_template $lxc_template.backup
  sed "113s/.*/squeeze \$cache\/partial-\$arch http:\/\/ftp5.gwdg.de\/pub\/linux\/debian\/debian/g" $lxc_template > $lxc_temp
  if [ $? -ne 0 ]; then
   printf "$generrormsg: Unable to modify Line 113 in File $lxc_template\n"
   return 1
  else
   printf "Done!\n\n"
   printf "Removing dhcp-client from package-list of container..."

   if [ "$(sed '93!d' $lxc_temp | grep dhcp)" == "" ]; then
    printf "\nNo DHCP-Client entry in File $lxc_temp, line 93 found. Skipping...\n"

   else 
    sed -i.back -e '93d' $lxc_temp

    if [ $? -ne 0 ]; then
     printf "$generrormsg: Unable to delete line 93 in $lxc_temp...\n"
     return 1

    else
     cp $lxc_temp $lxc_template
     printf "Done!\n"
    fi

   fi
  fi
 else
  printf "\n$generrormsg: $lxc_template seems to be missing!\n"
 fi

 printf "Creating lxc-container network config dir... "
 mkdir -p /lxc/cataclysm/
 if [ $? -ne 0 ]; then
  printf "\n$generrormsg: Unable to create /lxc/cataclysm/\n"
  return 1
 else
  printf "Done!\n"
 fi

 printf "Creating lxc-container network config file... "
 cat_config="/lxc/cataclysm/config"
 if [ -f "$cat_config" ]; then
  printf "\n$generrormsg: $cat_config allready exists!\n"

 else
  cat << EOF > /lxc/cataclysm/config
lxc.network.type = veth
lxc.network.flags = up
lxc.network.link = lxcbr0
lxc.network.hwaddr = 00:FF:AA:00:00:01
lxc.network.ipv4 = 192.168.123.2/24
EOF
  printf "Done!\n"
 fi

 printf "Creating network bridge config for the host... "
 if [ -f "$bridge_config_file" ]; then
  printf "\ngenerrormsg: $bridgeconfigfile allready exists!\n"
 else
  cat << EOF > $bridge_config_file
<network>
 <name>lxc</name>
 <uuid>e58bbb2b-4b27-807a-68c4-e182dcf47258</uuid>
 <forward mode='nat'/>
 <bridge name='lxcbr0' stp='off' delay='0' />
 <ip address='192.168.123.1' netmask='255.255.255.0'>
   <dhcp>
    <range start='192.168.123.100' end='192.168.123.254' />
   </dhcp>
  </ip>
</network>
EOF
  printf "Done!\n"
 fi
 read -p "$continue"
}

setup_lxc_container()
{
 clear
 printf "$selected to setup the LXC Container.\n"
 printf "This step will take some time!\n"
 read -p "$continue\n"

 printf "Setting up bridge and marking it for autostart...\n"
 virsh -c lxc:/// net-define $bridge_config_file
 virsh -c lxc:/// net-start lxc
 virsh -c lxc:/// net-autostart lxc

 printf "Creating container, this may take some time... \n"
 read -p "$continue\n"
 lxc-create -n cataclysm -t debian -f /lxc/cataclysm/config
}

####################################################
# GENERAL
####################################################

check_target_file()
{
 echo -e "\nChecking for existing file...\n"
 if [ -f "$target" ]; then
  echo -e "\n$target allready exists!\n"
  error="1"
  read -p "$continue"
 else
  echo -e "\n$target will be created!\n"
 fi
}

check_target_dir()
{
 echo -e "\nChecking for existing folder...\n"
 if [ -d "$target" ]; then
  echo -e "\n$target allready exists!\n"
  error="1"
  read -p "$continue"
 else
  echo -e "\n$target will be created!\n"
 fi
}

###################################################
# DDA Stuff
###################################################

chroot_to_lxc()
{
 chroot /var/lib/lxc/cataclysm/rootfs
}

check_dda_packages() 
{
 clear
 printf "$selected to check for rhe dependencies to _compile_ CDDA.\n"
 printf "Now checking for dependencies...\n"
 read -p "$continue"

# checking for required packages:
 deperror="0"
 missing=""
 printf "Checking Dependencies:\n"
 for dda_package in $dda_packages
  do
   check=$(cat /var/lib/dpkg/status | grep Package | grep $dda_package)
   if [ "" == "$check" ]; then
    dda_missing+="$dda_package "
    printf "%-20s%b\n" $dda_package $depmissingmsg
    deperror="1"
   else
    printf "%-20s%b\n" $dda_package $depokmsg
   fi
 done  

# Print a list of the missing packages
 printf "\nMissing Packages:\n$dda_missing\n\n"

 if [ "$deperror" == "1" ]; then
  printf  "Shall we install the missing dependencies? (y)es or (n)o:\n"
  read installdeps

  if [ "$installdeps" == "n" ]; then
   criticalerror="1"
   printf "$deperrormsg"

  elif [ "$installdeps" == "y" ]; then
   printf "installing dependencies:\n$dda_missing\n"
   read -p "$continue"
   aptitude install $dda_missing

  else
   printf "$novalmsg"
  fi

 else
 read -p "Deperror says $deperror, $continue"
 fi
}

clone_dda()
 {
  clear
  target="$defaultddatarget"

  printf "$ddalinkmsg"
  read -p "$continue"

  wanted="$defaultddagit"
  wanted_short=$(basename $wanted .git)

  wanted_cdda="$wanted_short"
  target_cdda="$target"

  check_target_dir

# create target folder
  if [ "$error" == "1" ]; then
   echo -e "\nAborting because $target allready exists..."
  else
   echo -e "\nCreating $target\n"
   mkdir -p "$target"
   cd "$target"
   echo -e "\n Now cloning $wanted into $target\n"
# ask user, if settings are ok
   read -p "$continue"
   git clone $wanted $target
  fi
 }

clone_dgame()
 {
  clear
  target="$defaultdgametarget"

  printf "$dgamelinkmsg"
  read -p "$continue"
 
  wanted="$defaultdgamegit"
  wanted_short=$(basename $wanted .git)

  check_target_dir

# create target folder
  if [ "$error" == "1" ]; then
   echo -e "\nAborting because $target allready exists..."
  else
   echo -e "\nCreating $target\n"
   mkdir -p "$target"
   cd "$target"
   echo -e "\n Now cloning $wanted into $target\n"
# ask user, if settings are ok
   read -p "$continue"
   git clone $wanted $target
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
  printf "Will now try to compile $defaultddagit in $defaultddatarget...\n"
  target_dir="$target_cdda"
  compile_stuff
 }

comp_dgame()
 {
  clear
  printf "Will now try to compile $defaultdgamegit in $defaultdgametarget...\n"
  target_dir="$defaultdgametarget"
  compile_stuff
 }

# MORE STUFF
########################################################
# Welcome
clear
echo -e $welcomemsg
read -p "$continue"

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
  main_menu
# generating task list
#  tasksel=0		# setting $tasksel to 0 to be able to count the tasks 
#  for task in $tasks
#   do
#    tasksel=$((tasksel +1))
#    printf "($tasksel) - %b\n" $task 
#  done
#  tasksel=1		# setting $tasksel to 1 to be the default task
#  printf "\n"
#  printf "Please make your selection by entering the coresponding number, default is [1]: "
#  read tasksel
#
#  if [ "$tasksel" == "" ]; then
#   tasksel="1"
#  fi

#switch case for task selection
#  case "$tasksel" in
#   1) lxc_menu;;
#   2) check_packages;;
#   3) clone_stuff;;
#   4) comp_cdda;;
#   5) clone_stuff;;
#   9) crit_err;;
#   *) printf "\n$generrormsg $novalmsg No valid Entry, please try again\n";;
#  esac 

done
