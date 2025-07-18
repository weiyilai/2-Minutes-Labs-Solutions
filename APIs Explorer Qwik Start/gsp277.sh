#!/bin/bash
# Define color variables

BLACK=`tput setaf 0`
RED=`tput setaf 1`
GREEN=`tput setaf 2`
YELLOW=`tput setaf 3`
BLUE=`tput setaf 4`
MAGENTA=`tput setaf 5`
CYAN=`tput setaf 6`
WHITE=`tput setaf 7`

BG_BLACK=`tput setab 0`
BG_RED=`tput setab 1`
BG_GREEN=`tput setab 2`
BG_YELLOW=`tput setab 3`
BG_BLUE=`tput setab 4`
BG_MAGENTA=`tput setab 5`
BG_CYAN=`tput setab 6`
BG_WHITE=`tput setab 7`

BOLD=`tput bold`
RESET=`tput sgr0`
#----------------------------------------------------start--------------------------------------------------#

echo "${BG_MAGENTA}${BOLD}Starting Execution${RESET}"

export BUCKET="$(gcloud config get-value project)"         

gsutil mb -p $BUCKET gs://$BUCKET-bucket

curl -LO raw.githubusercontent.com/Cloud-Wala-Banda/Labs-Solutions/main/APIs%20Explorer%20Qwik%20Start/demo-image.jpg

gsutil cp demo-image.jpg gs://$BUCKET-bucket/demo-image.jpg

gsutil acl ch -u allUsers:R gs://$BUCKET-bucket/demo-image.jpg

echo "${BG_RED}${BOLD}Congratulations For Completing The Lab !!!${RESET}"

#-----------------------------------------------------end----------------------------------------------------------#