#!/bin/bash
########################################################
# TODO:
# Line 117:	GIT DOWNLOADING PART
#		determine if the user entered basenamepath or
#		a downloadpath with added branch and getting
#		both separated
# Line 202:	SWITCH CASE
#		Add cases 3 to 7 and the needed functions	
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
# criticalerror		= Critical error, pogram abort
# tasks			= List of available tasks
# task			= task to run
########################################################
# Strings:
# deperrormsg		= error message displayed if dep is missing
# depmissingmsg		= red formatted dependency missing message
# depokmsg		= green formatted dependency ok message
# welcomemsg		= welcome message
# continue		= standard waiting for input message
########################################################
# Functions:
# checkpackages()	= Checks for required packages in $packages
# dldda()		= downloads Cataclysm-DDA Source from git
# criterr()		= Sets $criticalerror to 1
########################################################
# version history:
# v.0.0.3 adding switch/case menu for task selection and creating functions (fr)
# v.0.0.2 added some colours and the check for required packages (fr)
# v.0.0.1 creation phase (fr)
########################################################

# STUFF
########################################################
# declaring variables
version="v.0.0.3"
error="0"
SCRIPTPATH=`pwd -P`
packages="vim git gcc make autogen autoconf libncurses5 libncursesw5 libncursesw5-dev libncursesw5-dev bison flex sqlite3 libsqlite3-dev"
criticalerror="0"
checkdeptask="Check Dependencies"
tasks="Check_dependencies Download_Cataclysm-DDA Compile_Cataclysm-DDA Download_dgamelaunch Compile_dgamelaunch set-up_game Everything QUIT" 

# strings
depmissingmsg="\e[31mMissing!\e[37m"
depokmsg="\e[32mOK!\e[37m"
deperrormsg="Error: $package not installed!"
welcomemsg="This script will (sometime in the future) download, [merge?,] compile and setup a chroot enviroment for Cataclysm-DDA with _shared Worlds_\n\nCurrent Version:\t$version\n\n"
continue="Press [Enter] key to continue, press [CTRL+C] to cancel."


# FUNCTIONS
########################################################
checkpackages() 
{
 printf "you have selected %s" $tasksel
 printf "now checking for dependencies..."
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
  printf "\nyou entered %s\n" $installdeps

  if [ "$installdeps" == "n" ]; then
   criticalerror="1"
   printf "Error: Dependencies missing!\nPlease run the following command to install the missing dependencies and try again:\n\n\taptitude install $missing\n\n"

  elif [ "$installdeps" == "y" ]; then
   printf "installing dependencies:\n$missing\n"
   read -p "$continue"
   aptitude install $missing

  else
   printf "no valid entry detected...\n"
  fi

 else
 read -p "Deperror says $deperror, $continue"
 fi
}

dldda()
 {
# What version shall we download?
  echo "please enter the desired CDDA-Version (Git Link, default is [ https://github.com/C0DEHERO/Cataclysm-DDA.git ]):"
  read wanted_cdda
  [ -z "$wanted_cdda" ] && echo -e "You entered nothing, we큞l use https://github.com/C0DEHERO/Cataclysm-DDA.git\n" || echo -e "You entered $wanted_cdda\n" 
  if [$wanted_cdda == ""]; then
   wanted_cdda="https://github.com/C0DEHERO/Cataclysm-DDA.git"
  fi

# getting the short version of the Git Repo
  if [ "$wanted_cdda" -ne 1 ]; then
   wanted_cdda_short=$(basename $wanted_cdda .git)
  else
   wanted_cdda_branch=$(echo "$wanted_cdda{@: -1}")
   wanted_cdda=$(echo "$wanted_cdda{1}")
  fi

# Where shall we download it to?
  echo "please enter full target path for the CDDA download, default is [ $HOME/CDDA/ ]:"
  read target_cdda
  [ -z "$target_cdda" ] && echo -e "You enterd nothing, we큞l use $HOME/CDDA\n" || echo -e "You entered $target_cdda\n"
  if [$target_cdda == ""]; then
   target_cdda="$HOME/CDDA"
  fi

# now summarizing settings
  echo -e "\nChosen Settings:"
  echo -e "\nDownload Version:\t$wanted_cdda"
  echo -e "Target Directory:\t$target_cdda"

# check if folder settings are valid
# todo: check if entry is spelled correctly
  echo -e "\nChecking for existing folder...\n"
  if [ -d "$target_cdda" ]; then
   echo -e "\n$target_cdda allready exists!\n"
   error="1"
  else 
   echo -e "\n$target_cdda will be created!\n"
  fi

# ask user, if settings are ok
  read -p "Press [Enter] key to start downloading, press [CTRL+C] to cancel."

# create target folder
  if [ error == 1 ]; then
   echo -e "\nAborting because $target_cdda allready exists..."
  else
   echo -e "\nCreating $target_cdda\n"
   mkdir -p "$target_cdda"
   cd "$target_cdda"
   echo -e "\n Now cloning $wanted_cdda into $target_cdda\n"
   git clone $wanted_cdda
   cd $wanted_cdda_short 
  fi
 }

criterr()
 {
  criticalerror="1"
  printf "Exiting, Good Bye!\n\n"
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

#switch case for task selection
  case $tasksel in
   1) checkpackages;;
   2) dldda;;
   8) criterr;;
   *) printf "dum-di-dum";;
  esac 

# What version shall we download?
#   echo "please enter the desired CDDA-Version (Git Link, default is [ https://github.com/C0DEHERO/Cataclysm-DDA.git ]):"
#   read wanted_cdda
#   [ -z "$wanted_cdda" ] && echo -e "You entered nothing, we큞l use https://github.com/C0DEHERO/Cataclysm-DDA.git\n" || echo -e "You entered $wanted_cdda\n" 
#   if [$wanted_cdda == ""]; then
#    wanted_cdda="https://github.com/C0DEHERO/Cataclysm-DDA.git"
#   fi
#
# getting the short version of the Git Repo
#   wanted_cdda_branch=$(echo $wanted_cdda | xargs -1)
#wanted_cdda_short=$(basename $wanted_cdda .git)

# Where shall we download it to?
#   echo "please enter full target path for the CDDA download, default is [ $HOME/CDDA/ ]:"
#   read target_cdda
#   [ -z "$target_cdda" ] && echo -e "You enterd nothing, we큞l use $HOME/CDDA\n" || echo -e "You entered $target_cdda\n"
#   if [$target_cdda == ""]; then
#    target_cdda="$HOME/CDDA"
#   fi

# now summarizing settings
#   echo -e "\nChosen Settings:"
#   echo -e "\nDownload Version:\t$wanted_cdda"
#   echo -e "Target Directory:\t$target_cdda"

# check if folder settings are valid
# todo: check if entry is spelled correctly
#   echo -e "\nChecking for existing folder...\n"
#   if [ -d "$target_cdda" ]; then
#    echo -e "\n$target_cdda allready exists!\n"
#    error="1"
#   else 
#    echo -e "\n$target_cdda will be created!\n"
#   fi
#
# ask user, if settings are ok
#   read -p "Press [Enter] key to start downloading, press [CTRL+C] to cancel."

# create target folder
#   if [ error == 1 ]; then
#    echo -e "\nAborting because $target_cdda allready exists..."
#   else
#    echo -e "\nCreating $target_cdda\n"
#    mkdir -p "$target_cdda"
#    cd "$target_cdda"
#    echo -e "\n Now cloning $wanted_cdda into $target_cdda\n"
#    git clone $wanted_cdda
#    cd $wanted_cdda_short 
#    read -p "Press [Enter] key to start compiling, press [CTRL+C] to cancel."
#    make
#   fi
 done
