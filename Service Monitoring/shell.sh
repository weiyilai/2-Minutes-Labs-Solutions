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

# Step 1: Set Zone and Region
echo "${CYAN}${BOLD}Setting Zone and Region${RESET}"
export ZONE=$(gcloud compute project-info describe \
--format="value(commonInstanceMetadata.items[google-compute-default-zone])")

export REGION=$(gcloud compute project-info describe \
--format="value(commonInstanceMetadata.items[google-compute-default-region])")

# Step 2: Retrieve Access Token
echo "${MAGENTA}${BOLD}Retrieving Access Token${RESET}"
ACCESS_TOKEN=$(gcloud auth print-access-token)

# Step 3: Clone Repository
echo "${YELLOW}${BOLD}Cloning HelloLoggingNodeJS Repository${RESET}"
git clone https://github.com/haggman/HelloLoggingNodeJS.git

# Step 4: Change to Repository Directory
echo "${GREEN}${BOLD}Navigating to Repository Directory${RESET}"
cd HelloLoggingNodeJS

# Step 5: Create index.js File
echo "${BLUE}${BOLD}Creating index.js File${RESET}"
cat > app.yaml <<'EOF_END'
runtime: nodejs20
EOF_END

# Step 6: Create App Engine Application
echo "${RED}${BOLD}Creating App Engine Application${RESET}"
gcloud app create --region=$REGION

# Step 7: Deploy App Engine Application
echo "${CYAN}${BOLD}Deploying App Engine Application${RESET}"
gcloud app deploy --quiet

# Step 8: Create GCP Monitoring Service
echo "${MAGENTA}${BOLD}Creating GCP Monitoring Service${RESET}"
curl -X POST \
  -H "Authorization: Bearer $(gcloud auth print-access-token)" \
  -H "Content-Type: application/json" \
  -d '{
    "displayName": "default",
    "appEngine": {
     "moduleId": "default"
  }
}' \
  https://monitoring.googleapis.com/v3/projects/$DEVSHELL_PROJECT_ID/services

# Step 9: Retrieve Service ID
echo "${YELLOW}${BOLD}Retrieving Service ID${RESET}"
SERV_ID=$(curl -X GET \
  -H "Authorization: Bearer $ACCESS_TOKEN" \
  https://monitoring.googleapis.com/v3/projects/$DEVSHELL_PROJECT_ID/services \
  | jq -r '.services[] | select(.name | contains("gae")) | .name')

# Step 10: Create SLO for the Service
echo "${GREEN}${BOLD}Creating SLO for Service${RESET}"
RESP=$(curl -X POST \
  -H "Authorization: Bearer $ACCESS_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "displayName": "99.5% - Availability - Rolling 7 days",
    "goal": 0.995,
    "rollingPeriod": "604800s",
    "serviceLevelIndicator": {
      "basicSli": {
        "availability": {}
      }
    }
  }' \
  https://monitoring.googleapis.com/v3/$SERV_ID/serviceLevelObjectives)

NAME=$(echo $RESP | jq -r '.name')  


# Step 11: Create Email Notification Channel
echo "${BLUE}${BOLD}Creating Email Notification Channel${RESET}"
cat > email-channel.json <<EOF_END
{
  "type": "email",
  "displayName": "cloudwalabanda",
  "description": "Awesome",
  "labels": {
    "email_address": "$USER_EMAIL"
  }
}
EOF_END

gcloud beta monitoring channels create --channel-content-from-file="email-channel.json"

# Step 12: Retrieve Channel ID
echo "${RED}${BOLD}Retrieving Notification Channel ID${RESET}"
channel_info=$(gcloud beta monitoring channels list)
channel_id=$(echo "$channel_info" | grep -oP 'name: \K[^ ]+' | head -n 1)

# Step 13: Create Monitoring Policy
echo "${CYAN}${BOLD}Creating Monitoring Policy${RESET}"
cat > policy.json <<EOF_END
{
  "displayName": "Really short window test",
  "userLabels": {},
  "conditions": [
    {
      "displayName": "Really short window test",
      "conditionThreshold": {
        "filter": "select_slo_burn_rate(\"$NAME\", \"600s\")",
        "aggregations": [
          {
            "alignmentPeriod": "300s",
            "crossSeriesReducer": "REDUCE_NONE"
          }
        ],
        "comparison": "COMPARISON_GT",
        "duration": "0s",
        "trigger": {
          "count": 1
        },
        "thresholdValue": 1.5
      }
    }
  ],
  "alertStrategy": {
    "notificationPrompts": [
      "OPENED",
      "CLOSED"
    ]
  },
  "combiner": "OR",
  "enabled": true,
  "notificationChannels": [
    $channel_id
  ],
  "severity": "SEVERITY_UNSPECIFIED"
}
EOF_END

gcloud alpha monitoring policies create --policy-from-file="policy.json"

# Step 14: Redeploy Application
echo "${YELLOW}${BOLD}Redeploying Application${RESET}"
gcloud app deploy --quiet

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
