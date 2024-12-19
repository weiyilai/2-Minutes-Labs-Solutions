clear

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

# Array of color codes excluding black and white
TEXT_COLORS=($RED $GREEN $YELLOW $BLUE $MAGENTA $CYAN)
BG_COLORS=($BG_RED $BG_GREEN $BG_YELLOW $BG_BLUE $BG_MAGENTA $BG_CYAN)

# Pick random colors
RANDOM_TEXT_COLOR=${TEXT_COLORS[$RANDOM % ${#TEXT_COLORS[@]}]}
RANDOM_BG_COLOR=${BG_COLORS[$RANDOM % ${#BG_COLORS[@]}]}

#----------------------------------------------------start--------------------------------------------------#

echo "${RANDOM_BG_COLOR}${RANDOM_TEXT_COLOR}${BOLD}Starting Execution${RESET}"

# Step 1: Set the default zone from project metadata
echo -e "${GREEN}${BOLD}Step 2: Setting the default zone from project metadata...${RESET}"
export ZONE=$(gcloud compute project-info describe \
--format="value(commonInstanceMetadata.items[google-compute-default-zone])")

# Step 2: Fetching Project ID and Project Number
echo -e "${YELLOW}${BOLD}Step 3: Fetching Project ID and Project Number...${RESET}"
export PROJECT_ID=$(gcloud config get-value project)

export PROJECT_NUMBER=$(gcloud projects describe ${PROJECT_ID} \
    --format="value(projectNumber)")

mkdir stackdriver-lab
cd stackdriver-lab

# Step 3: Download necessary files
echo -e "${MAGENTA}${BOLD}Step 5: Downloading necessary files for the lab...${RESET}"
curl -LO https://github.com/QUICK-GCP-LAB/2-Minutes-Labs-Solutions/raw/refs/heads/main/Configuring%20and%20Using%20Cloud%20Logging%20and%20Cloud%20Monitoring/stackdriver-lab/activity.sh
curl -LO https://github.com/QUICK-GCP-LAB/2-Minutes-Labs-Solutions/raw/refs/heads/main/Configuring%20and%20Using%20Cloud%20Logging%20and%20Cloud%20Monitoring/stackdriver-lab/apache2.conf
curl -LO https://github.com/QUICK-GCP-LAB/2-Minutes-Labs-Solutions/raw/refs/heads/main/Configuring%20and%20Using%20Cloud%20Logging%20and%20Cloud%20Monitoring/stackdriver-lab/basic-ingress.yaml
curl -LO https://github.com/QUICK-GCP-LAB/2-Minutes-Labs-Solutions/raw/refs/heads/main/Configuring%20and%20Using%20Cloud%20Logging%20and%20Cloud%20Monitoring/stackdriver-lab/gke.sh
curl -LO https://github.com/QUICK-GCP-LAB/2-Minutes-Labs-Solutions/raw/refs/heads/main/Configuring%20and%20Using%20Cloud%20Logging%20and%20Cloud%20Monitoring/stackdriver-lab/linux_startup.sh
curl -LO https://github.com/QUICK-GCP-LAB/2-Minutes-Labs-Solutions/raw/refs/heads/main/Configuring%20and%20Using%20Cloud%20Logging%20and%20Cloud%20Monitoring/stackdriver-lab/pubsub.sh
curl -LO https://github.com/QUICK-GCP-LAB/2-Minutes-Labs-Solutions/raw/refs/heads/main/Configuring%20and%20Using%20Cloud%20Logging%20and%20Cloud%20Monitoring/stackdriver-lab/setup.sh
curl -LO https://github.com/QUICK-GCP-LAB/2-Minutes-Labs-Solutions/raw/refs/heads/main/Configuring%20and%20Using%20Cloud%20Logging%20and%20Cloud%20Monitoring/stackdriver-lab/sql.sh
curl -LO https://github.com/QUICK-GCP-LAB/2-Minutes-Labs-Solutions/raw/refs/heads/main/Configuring%20and%20Using%20Cloud%20Logging%20and%20Cloud%20Monitoring/stackdriver-lab/windows_startup.ps1

# Step 4: Update setup.sh with the current zone
echo -e "${CYAN}${BOLD}Step 6: Updating 'setup.sh' with the current zone...${RESET}"
sed -i "s/us-west1-b/$ZONE/g" setup.sh

# Step 5: Make necessary scripts executable and run setup
echo -e "${RED}${BOLD}Step 7: Making scripts executable and running 'setup.sh'...${RESET}"
chmod +x setup.sh
chmod +x gke.sh
chmod +x pubsub.sh
./setup.sh

# Step 6: Create a BigQuery dataset for logs
echo -e "${GREEN}${BOLD}Step 8: Creating a BigQuery dataset named 'project_logs'...${RESET}"
bq mk project_logs

# Step 7: Create logging sinks for VM and Load Balancer logs
echo -e "${YELLOW}${BOLD}Step 9: Creating logging sinks for VM and Load Balancer logs...${RESET}"
gcloud logging sinks create vm_logs \
    bigquery.googleapis.com/projects/$DEVSHELL_PROJECT_ID/datasets/project_logs \
    --log-filter='resource.type="gce_instance"'

gcloud logging sinks create load_bal_logs \
    bigquery.googleapis.com/projects/$DEVSHELL_PROJECT_ID/datasets/project_logs \
    --log-filter="resource.type=\"http_load_balancer\""

# Step 8: Add IAM policy for the service account
echo -e "${BLUE}${BOLD}Step 10: Adding IAM policy for the service account...${RESET}"
gcloud projects add-iam-policy-binding $DEVSHELL_PROJECT_ID \
  --member=serviceAccount:service-$PROJECT_NUMBER@gcp-sa-logging.iam.gserviceaccount.com \
  --role=roles/bigquery.dataEditor

# Step 9: Pause for 15 seconds to allow setup to complete
echo -e "${MAGENTA}${BOLD}Step 11: Pausing for 15 seconds...${RESET}"
sleep 15

# Step 10: Fetch the table ID from the BigQuery dataset
echo -e "${CYAN}${BOLD}Step 12: Fetching the table ID from the 'project_logs' dataset...${RESET}"
ID=$(bq ls --project_id $DEVSHELL_PROJECT_ID --dataset_id project_logs --format=json | jq -r '.[0].tableReference.tableId')

sleep 15

# Step 11: Query logs from BigQuery
echo -e "${RED}${BOLD}Step 13: Querying logs from BigQuery...${RESET}"
bq query --use_legacy_sql=false \
"
SELECT
  logName, resource.type, resource.labels.zone, resource.labels.project_id,
FROM
  \`$DEVSHELL_PROJECT_ID.project_logs.$ID\`
"
# Step 12: Create a logging metric for 403 errors
echo -e "${GREEN}${BOLD}Step 14: Creating a logging metric for 403 errors...${RESET}"
gcloud logging metrics create 403s \
    --description="Counts syslog entries with resource.type=gce_instance" \
    --log-filter="resource.type=\"gce_instance\" AND logName=\"projects/$DEVSHELL_PROJECT_ID/logs/syslog\""

echo

# Function to display a random congratulatory message
function random_congrats() {
    MESSAGES=(
        "${GREEN}Congratulations For Completing The Lab! Keep up the great work!${RESET}"
        "${CYAN}Well done! Your hard work and effort have paid off!${RESET}"
        "${YELLOW}Amazing job! You’ve successfully completed the lab!${RESET}"
        "${BLUE}Outstanding! Your dedication has brought you success!${RESET}"
        "${MAGENTA}Great work! You’re one step closer to mastering this!${RESET}"
        "${RED}Fantastic effort! You’ve earned this achievement!${RESET}"
        "${CYAN}Congratulations! Your persistence has paid off brilliantly!${RESET}"
        "${GREEN}Bravo! You’ve completed the lab with flying colors!${RESET}"
        "${YELLOW}Excellent job! Your commitment is inspiring!${RESET}"
        "${BLUE}You did it! Keep striving for more successes like this!${RESET}"
        "${MAGENTA}Kudos! Your hard work has turned into a great accomplishment!${RESET}"
        "${RED}You’ve smashed it! Completing this lab shows your dedication!${RESET}"
        "${CYAN}Impressive work! You’re making great strides!${RESET}"
        "${GREEN}Well done! This is a big step towards mastering the topic!${RESET}"
        "${YELLOW}You nailed it! Every step you took led you to success!${RESET}"
        "${BLUE}Exceptional work! Keep this momentum going!${RESET}"
        "${MAGENTA}Fantastic! You’ve achieved something great today!${RESET}"
        "${RED}Incredible job! Your determination is truly inspiring!${RESET}"
        "${CYAN}Well deserved! Your effort has truly paid off!${RESET}"
        "${GREEN}You’ve got this! Every step was a success!${RESET}"
        "${YELLOW}Nice work! Your focus and effort are shining through!${RESET}"
        "${BLUE}Superb performance! You’re truly making progress!${RESET}"
        "${MAGENTA}Top-notch! Your skill and dedication are paying off!${RESET}"
        "${RED}Mission accomplished! This success is a reflection of your hard work!${RESET}"
        "${CYAN}You crushed it! Keep pushing towards your goals!${RESET}"
        "${GREEN}You did a great job! Stay motivated and keep learning!${RESET}"
        "${YELLOW}Well executed! You’ve made excellent progress today!${RESET}"
        "${BLUE}Remarkable! You’re on your way to becoming an expert!${RESET}"
        "${MAGENTA}Keep it up! Your persistence is showing impressive results!${RESET}"
        "${RED}This is just the beginning! Your hard work will take you far!${RESET}"
        "${CYAN}Terrific work! Your efforts are paying off in a big way!${RESET}"
        "${GREEN}You’ve made it! This achievement is a testament to your effort!${RESET}"
        "${YELLOW}Excellent execution! You’re well on your way to mastering the subject!${RESET}"
        "${BLUE}Wonderful job! Your hard work has definitely paid off!${RESET}"
        "${MAGENTA}You’re amazing! Keep up the awesome work!${RESET}"
        "${RED}What an achievement! Your perseverance is truly admirable!${RESET}"
        "${CYAN}Incredible effort! This is a huge milestone for you!${RESET}"
        "${GREEN}Awesome! You’ve done something incredible today!${RESET}"
        "${YELLOW}Great job! Keep up the excellent work and aim higher!${RESET}"
        "${BLUE}You’ve succeeded! Your dedication is your superpower!${RESET}"
        "${MAGENTA}Congratulations! Your hard work has brought great results!${RESET}"
        "${RED}Fantastic work! You’ve taken a huge leap forward today!${RESET}"
        "${CYAN}You’re on fire! Keep up the great work!${RESET}"
        "${GREEN}Well deserved! Your efforts have led to success!${RESET}"
        "${YELLOW}Incredible! You’ve achieved something special!${RESET}"
        "${BLUE}Outstanding performance! You’re truly excelling!${RESET}"
        "${MAGENTA}Terrific achievement! Keep building on this success!${RESET}"
        "${RED}Bravo! You’ve completed the lab with excellence!${RESET}"
        "${CYAN}Superb job! You’ve shown remarkable focus and effort!${RESET}"
        "${GREEN}Amazing work! You’re making impressive progress!${RESET}"
        "${YELLOW}You nailed it again! Your consistency is paying off!${RESET}"
        "${BLUE}Incredible dedication! Keep pushing forward!${RESET}"
        "${MAGENTA}Excellent work! Your success today is well earned!${RESET}"
        "${RED}You’ve made it! This is a well-deserved victory!${RESET}"
        "${CYAN}Wonderful job! Your passion and hard work are shining through!${RESET}"
        "${GREEN}You’ve done it! Keep up the hard work and success will follow!${RESET}"
        "${YELLOW}Great execution! You’re truly mastering this!${RESET}"
        "${BLUE}Impressive! This is just the beginning of your journey!${RESET}"
        "${MAGENTA}You’ve achieved something great today! Keep it up!${RESET}"
        "${RED}You’ve made remarkable progress! This is just the start!${RESET}"
    )

    RANDOM_INDEX=$((RANDOM % ${#MESSAGES[@]}))
    echo -e "${BOLD}${MESSAGES[$RANDOM_INDEX]}"
}

# Display a random congratulatory message
random_congrats

echo -e "\n"  # Adding one blank line

cd

remove_files() {
    # Loop through all files in the current directory
    for file in *; do
        # Check if the file name starts with "gsp", "arc", or "shell"
        if [[ "$file" == gsp* || "$file" == arc* || "$file" == shell* ]]; then
            # Check if it's a regular file (not a directory)
            if [[ -f "$file" ]]; then
                # Remove the file and echo the file name
                rm "$file"
                echo "File removed: $file"
            fi
        fi
    done
}

remove_files