#!/bin/bash

# Azure CLI command to list all disks
disks=$(az disk list --query "[?diskState!='Attached']")

# Prompt user to choose whether to delete unattached disks
echo "Enter your threshold value:"
read  UNMOUNTED_VOLUME_THRESHOLD

# discord webhook url
YOUR_DISCORD_WEBHOOK_URL=https://discordapp.com/api/webhooks/1207409980861452298/LSQcwyl73zi1WQMiO6as64OFLhpjD91l0V1jH3VMvCaoAwds_8ZLDBNKABOekZWsnx7m

# Counter for unmounted volumes
count=1

# Array to store details of unmounted volumes
unmounted_volumes=()

# Loop through each disk customizing a message
for disk in $(echo "${disks}" | jq -c '.[]'); do
    name=$(echo "${disk}" | jq -r '.name')
    resource_group=$(echo "${disk}" | jq -r '.resourceGroup')
    size=$(echo "${disk}" | jq -r '.diskSizeGB')
    tags=$(echo "${disk}" | jq -r '.tags | to_entries | map("\(.key)=\(.value)") | join(", ")')

    unmounted_volumes+=( " **Disk Number :** ${count} \n \t **Name:** ${name}\n \t **Resource Group:** ${resource_group}\n \t **Size:** ${size}GB \n \t **Tags:** ${tags}")

    ((count++))
done

# message alert send on the discord how many total number of volumes
count=$((count - 1))
message="**Total number of unmounted managed volumes:** ${count}.\n \n"
curl -H "Content-Type: application/json" -X POST -d "{\"content\":\"${message}\"}" $YOUR_DISCORD_WEBHOOK_URL

message_no_exceed="Total number of unmounted managed disk doesn't exceed from the threshold value"

# Send details of unmounted volumes to Discord
if [ ${#unmounted_volumes[@]} -gt $UNMOUNTED_VOLUME_THRESHOLD ]; then
    for volume in "${unmounted_volumes[@]}"; do
        # Use curl to send message to Discord webhook
        curl -H "Content-Type: application/json" -X POST -d "{\"content\":\"${volume}\"}" $YOUR_DISCORD_WEBHOOK_URL
        # curl -H "Content-Type: application/json" -X POST -d "{\"content\":\"**${volume}** _${volume}_ \`${volume}\`\"}" $YOUR_DISCORD_WEBHOOK_URL
    done
else
    
    curl -H "Content-Type: application/json" -X POST -d "{\"content\":\"${message_no_exceed}\"}" $YOUR_DISCORD_WEBHOOK_URL

fi
