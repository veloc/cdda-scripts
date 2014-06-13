#!/bin/bash
########################################################
# TODO:
# General:	UPDATE VARIABLE AND FUNCTION EXPLANATION
#		find a way to run the script in the chroot
#
#		adapt dgl-create-chroot to not create a chroot but
#		 use the lxc-container instead.
########################################################
# version history:
# v.0.0.6 trying to implement the stuff from CODEHEROs dgl-create-chroot script
# v.0.0.5 trying to implement lxc linux-containers for security
# v.0.0.4 pushed to github: https://github.com/veloc/cdda-scripts.git
# v.0.0.3 adding switch/case menu for task selection and creating functions (fr)
# v.0.0.2 added some colours and the check for required packages (fr)
# v.0.0.1 creation phase (fr)
########################################################

# STUFF
########################################################
# declaring some variables
VERSION="v.0.0.6"
ERROR="0"
CRITICALERROR="0"

# packagelists
DDA_PACKAGES="libncurses5-dev git-core g++ make autogen autoconf libncurses5 libncursesw5 libncursesw5-dev libncursesw5-dev bison flex sqlite3 libsqlite3-dev"
LXC_PACKAGES="sed debootstrap lxc libvirt-bin dnsmasq-base screen"

# menu stuff
MAIN_MENU_LIST="LXC Menu;DDA Menu;Everything (NOT WORKING!);QUIT"
DDA_TASKS="Chroot to LXC-Container;Check DDA Dependencies;Clone Cataclysm-DDA Git;Compile Cataclysm-DDA;Clone dgamelaunch Git;Compile dgamelaunch (NOT WORKING);set-up the game! (NOT WORKING);Everything (NOT WORKING);Main Menu;QUIT"
LXC_TASKS="Check LXC Dependencies;Setup LXC CGroup;Generate and modify LXC configs;Setup LXC Container;Main Menu;QUIT"

# setting default values
DEFAULTDDAGIT="https://github.com/C0DEHERO/Cataclysm-DDA.git"
DEFAULTDGAMEGIT="https://github.com/C0DEHERO/dgamelaunch.git"
DEFAULTDDATARGET="/var/lib/lxc/cataclysm/rootfs/opt/CDDA/"
DEFAULTDGAMETARGET="/var/lib/lxc/cataclysm/rootfs/opt/CDDA/dgamelaunch/"
CHROOT="/var/lib/lxc/cataclysm/rootfs"
BRIDGE_CONFIG_FILE="/etc/libvirt/qemu/networks/lxc.xml"

# strings
DEPMISSINGMSG="\e[31mMissing!\e[37m"
DEPOKMSG="\e[32mInstalled!\e[37m"
DONEMSG="\e[32mDone!\e[37m"
WELCOMEMSG="This script will (sometime in the future) download, [merge?,] compile and setup a secure chroot enviroment for Cataclysm-DDA with _shared Worlds_\n\nCurrent Version:\t$VERSION\n\n"
CONTINUE="Press [Enter] key to continue, press [CTRL+C] to cancel."

GETLINKMSGSTR="Will now clone"
DDALINKMSG="$GETLINKMSGSTR $DEFAULTDDAGIT into $DEFAULTDDATARGET\n"
DGAMELINKMSG="$GETLINKMSGSTR $DEFAULTDGAMEGIT into $DEFAULTDGAMETARGET\n"

SELECTED_TASK="You have selected "

# Error MSGs
GENERRORMSG="\e[31mError\e[37m:"
#NOCDDADIRGIVEN="\e[31mError\e[37m: No CDDA Dir given. Please run Step (2) first!\n\n" #seems unused
DEPERRORMSG="$GENERRORMSG Dependencies missing!\nPlease run the following command to install the missing dependencies and try again:\n\n\taptitude install"
NOVALMSG="No valid Entry!"

# FUNCTIONS
########################################################
# MENUS
########################################################
task_list()
{

 OLD_IFS="$IFS"
 IFS=";"
# generating task list
  printf "\n"
  TASKSEL=0             # setting $TASKSEL to 0 to be able to count the tasks
  for TASK in $menu
   do
    TASKSEL=$((TASKSEL +1))
    printf "($TASKSEL) - %b\n" $TASK
  done
  TASKSEL=1             # setting $TASKSEL to 1 to be the default task
  printf "\n"
  printf "Please make your selection by entering the coresponding number, default is [1]: "
  read TASKSEL

  if [ "$TASKSEL" == "" ]; then
   TASKSEL="1"
  fi
 IFS="$OLD_IFS"
}

main_menu()
{
 menu="$MAIN_MENU_LIST"
 task_list

#switch case for task selection
  case "$TASKSEL" in
   1) lxc_menu;;
   2) dda_menu;;
   3) all_stuff;;
   9) crit_err;;
   *) printf "\n$GENERRORMSG $NOVALMSG No valid Entry, please try again\n";;
  esac 
}

dda_menu()
{
 menu="$DDA_TASKS"
 task_list

#switch case for task selection
  case "$TASKSEL" in
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
   *) printf "\n$GENERRORMSG $NOVALMSG No valid Entry, please try again\n";;
  esac
}

lxc_menu()
{
 menu="$LXC_TASKS"
 task_list 

#switch case for lxc task selection
  case "$TASKSEL" in
   1) check_lxc_packages;;
   2) lxc_cgroup;;
   3) lxc_mod_configs;;
   4) setup_lxc_container;;
   5) main_menu;;
   9) crit_err;;
   *) printf "\n$GENERRORMSG $NOVALMSG No valid Entry, please try again\n";;
  esac 
}

###############################################
# LXC Stuff
###############################################

check_lxc_packages() 
{
 clear
 printf "$SELECTED_TASK to check for LXC Dependencies.\n"
 printf "Now checking for dependencies...\n"
 read -p "$CONTINUE"

 PACKAGES="$LXC_PACKAGES"
 check_packages
}

lxc_cgroup()
{
 clear
 FSTAB="/etc/fstab"
 FSTAB_BACKUP="/etc/fstab.backup.lxc_cgroup"

 printf "$SELECTED_TASK to set up the cgroup-Mountpouint for LXC.\n"

 if [ "$(cat $FSTAB | grep cgroup)" == "" ]; then
  TARGET="$FSTAB_BACKUP"
  check_target_file
  printf "backing up $FSTAB to $FSTAB_BACKUP!\n\n"  
  cp $FSTAB $FSTAB_BACKUP

  if [ $? -ne 0 ]; then
   printf "$GENERRORMSG\n\tFailed to copy $FSTAB to $FSTAB_BACKUP\n\n"
   return 1
  fi

  printf "adding cgroup line to $FSTAB...\n\n"
cat << EOF >> $FSTAB
cgroup  /sys/fs/cgroup  cgroup  defaults  0   0
EOF

  printf "trying to mount /sys/fs/cgroup...\n\n"
  mount /sys/fs/cgroup 

  if [ $? -ne 0 ]; then
   printf "$GENERRORMSG\n\tMounting failed!\n\n"
   return 1
  fi

 else
  printf "Skipping modification to $FSTAB:\n\tThere seemes to be a cgroup mountpoint allready!\n"

 fi 
 read -p "$CONTINUE"
}

lxc_mod_template()
{
 printf "Modifying $LXC_TEMPLATE... "

 if [ -f "$LXC_TEMPLATE" ]; then
  cp $LXC_TEMPLATE $LXC_TEMPLATE.backup
  sed "113s/.*/squeeze \$cache\/partial-\$arch http:\/\/ftp5.gwdg.de\/pub\/linux\/debian\/debian/g" $LXC_TEMPLATE > $LXC_TEMP
  if [ $? -ne 0 ]; then
   printf "$GENERRORMSG\n\tUnable to modify Line 113 in File $LXC_TEMPLATE\n\n"
   return 1
  else
   printf "$DONEMSG\n\n"
   printf "Removing dhcp-client from package-list of container..."

   if [ "$(sed '93!d' $LXC_TEMP | grep dhcp)" == "" ]; then
    printf "\nNo DHCP-Client entry in File $LXC_TEMP, line 93 found. \e[33mSkipping\e[37m...\n\n"

   else
    sed -i.back -e '93d' $LXC_TEMP

    if [ $? -ne 0 ]; then
     printf "$GENERRORMSG\n\tUnable to delete line 93 in $LXC_TEMP...\n\n"
     return 1

    else
     cp $LXC_TEMP $LXC_TEMPLATE
     printf "$DONEMSG\n"
    fi

   fi
  fi
 else
  printf "$GENERRORMSG\n\t$LXC_TEMPLATE seems to be missing!\n\n"
 fi
}

lxc_create_network_config()
{
 printf "Creating lxc-container network config dir... "
 mkdir -p /lxc/cataclysm/
 if [ $? -ne 0 ]; then
  printf "$GENERRORMSG\n\tUnable to create /lxc/cataclysm/\n\n"
  return 1
 else
  printf "$DONEMSG\n"
 fi

 printf "Creating lxc-container network config file... "
 CAT_CONFIG="/lxc/cataclysm/config"
 if [ -f "$CAT_CONFIG" ]; then
  printf "$GENERRORMSG\n\t$CAT_CONFIG allready exists!\n\n"

 else
  cat << EOF > $CAT_CONFIG
lxc.network.type = veth
lxc.network.flags = up
lxc.network.link = lxcbr0
lxc.network.hwaddr = 00:FF:AA:00:00:01
lxc.network.ipv4 = 192.168.123.2/24
EOF
  printf "$DONEMSG\n"
 fi
}

lxc_create_network_bridge()
{
 printf "Creating network bridge config for the host... "
 if [ -f "$BRIDGE_CONFIG_FILE" ]; then
  printf "$GENERRORMSG\n\t$BRIDGE_CONFIG_FILE allready exists!\n\n"
 else
  cat << EOF > $BRIDGE_CONFIG_FILE
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
  printf "$DONEMSG\n"
 fi
}

lxc_mod_configs()
{
 clear
 LXC_TEMPLATE="/usr/lib64/lxc/templates/lxc-debian"
 LXC_TEMP="/tmp/lxc-debian"
 LXC_SERVER="http://ftp5.gwdg.de/pub/linux/debian/debian"

 printf "$SELECTED_TASK to modify the debian template generation file and create a config file for the network of the container\n\n"

 lxc_mod_template
 lxc_create_network_config
 lxc_create_network_bridge

 read -p "$CONTINUE"
}

setup_lxc_container()
{
 clear
 printf "$SELECTED_TASK to setup the LXC Container.\n"
 printf "This step will take some time!\n"
 read -p "$CONTINUE\n"

#TODO: check if container allready exists!

 printf "Setting up bridge and marking it for autostart...\n"
 virsh -c lxc:/// net-define $BRIDGE_CONFIG_FILE
 virsh -c lxc:/// net-start lxc
 virsh -c lxc:/// net-autostart lxc

 printf "Creating container, this may take some time... \n"
 read -p "$CONTINUE\n"
 lxc-create -n cataclysm -t debian -f /lxc/cataclysm/config
}

####################################################
# GENERAL
####################################################
print_missing_packages()
{
 printf "\nMissing Packages:\n$MISSING\n\n"

 if [ "$DEPERROR" == "1" ]; then
  INSTALLDEPS=""
  printf  "Shall we install the missing dependencies? (y)es or (n)o:\n"
  read INSTALLDEPS

  if [ "$INSTALLDEPS" == "n" ]; then
   CRITICALERROR="1"
   printf "$DEPERRORMSG $MISSING\n\n"

  elif [ "$INSTALLDEPS" == "y" ]; then
   printf "installing dependencies:\n$MISSING\n"
   read -p "$CONTINUE"
   aptitude install $MISSING

  else
   printf "$NOVALMSG"
  fi

 else
 read -p "Deperror says $DEPERROR, $CONTINUE"
 fi
}

check_packages()
{
# checking for required packages:
 DEPERROR="0"
 MISSING=""
 printf "Checking Dependencies:\n"
 for PACKAGE in $PACKAGES
  do
   CHECK=$(cat /var/lib/dpkg/status | grep Package | grep $PACKAGE)
   if [ "" == "$CHECK" ]; then
    MISSING+="$PACKAGE "
    printf "%-20s%b\n" $PACKAGE $DEPMISSINGMSG
    DEPERROR="1"
   else
    printf "%-20s%b\n" $PACKAGE $DEPOKMSG
   fi
 done

 print_missing_packages
}

check_target_file()
{
 echo -e "\nChecking for existing file...\n"
 if [ -f "$TARGET" ]; then
  echo -e "\n$TARGET allready exists!\n"
  ERROR="1"
  read -p "$CONTINUE"
 else
  echo -e "\n$TARGET will be created!\n"
 fi
}

check_target_dir()
{
 echo -e "\nChecking for existing folder...\n"
 if [ -d "$TARGET" ]; then
  echo -e "\n$TARGET allready exists!\n"
  ERROR="1"
  read -p "$CONTINUE"
 else
  echo -e "\n$TARGET will be created!\n"
 fi
}

###################################################
# DDA Stuff
###################################################

chroot_to_lxc()
{
chroot $CHROOT
# CHROOT /var/lib/lxc/cataclysm/rootfs
}

check_dda_packages() 
{
 clear
 printf "$SELECTED_TASK to check for rhe dependencies to _compile_ CDDA.\n"
 printf "Now checking for dependencies...\n"
 read -p "$CONTINUE"
 
 PACKAGES="$DDA_PACKAGES"

 check_packages
}

clone_dda()
 {
  clear
  TARGET="$DEFAULTDDATARGET"

  printf "$DDALINKMSG"
  read -p "$CONTINUE"

  WANTED="$DEFAULTDDAGIT"
  WANTED_SHORT=$(basename $WANTED .git)

  check_target_dir

# create target folder
  if [ "$ERROR" == "1" ]; then
   echo -e "\nAborting because $TARGET allready exists..."
  else
   echo -e "\nCreating $TARGET\n"
   mkdir -p "$TARGET"
   cd "$TARGET"
   echo -e "\n Now cloning $WANTED into $TARGET\n"
# ask user, if settings are ok
   read -p "$CONTINUE"
   git clone $WANTED $TARGET
  fi
 }

clone_dgame()
 {
  clear
  TARGET="$DEFAULTDGAMETARGET"

  printf "$DGAMELINKMSG"
  read -p "$CONTINUE"
 
  WANTED="$DEFAULTDGAMEGIT"
  WANTED_SHORT=$(basename $WANTED .git)

  check_target_dir

# create target folder
  if [ "$ERROR" == "1" ]; then
   echo -e "\nAborting because $TARGET allready exists..."
  else
   echo -e "\nCreating $TARGET\n"
   mkdir -p "$TARGET"
   cd "$TARGET"
   echo -e "\n Now cloning $WANTED into $TARGET\n"
# ask user, if settings are ok
   read -p "$CONTINUE"
   git clone $WANTED $TARGET
  fi
 }

crit_err()
 {
  CRITICALERROR="1"
  printf "Exiting, Good Bye!\n\n"
 }

compile_stuff()
 {
  cd $TARGET_DIR
  make
 }

comp_cdda()
 {
  clear
  printf "Will now try to compile $DEFAULTDDAGIT in $DEFAULTDDATARGET...\n"
  TARGET_DIR="$DEFAULTDDATARGET"
  compile_stuff
 }

comp_dgame()
 {
  clear
  printf "Will now try to compile $DEFAULTDGAMEGIT in $DEFAULTDGAMETARGET...\n"
  TARGET_DIR="$DEFAULTDGAMETARGET"
  compile_stuff
 }

# MORE STUFF
########################################################
# Welcome
clear
echo -e $WELCOMEMSG
read -p "$CONTINUE"

# EXITING STUFF
########################################################

# CHECKING FOR ROOT PRIVILEGUES
if [ "$(id -u)" != "0" ]; then
    echo "This script should be run as 'root'"
    exit 1
fi

# BEGINNING MAIN WHILE LOOP
while [ "$CRITICALERROR" == "0" ]
 do
  main_menu
 done
