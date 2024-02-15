#!/bin/bash

# Azure CLI command to list all disks
disks=$(az disk list --query "[?diskState!='Attached']")

# Prompt user to choose whether to delete unattached disks
echo "Enter your threshold value:"
read  UNMOUNTED_VOLUME_THRESHOLD

# Discord webhook url
YOUR_DISCORD_WEBHOOK_URL="https://discord.com/api/webhooks/1207684722302652446/hgy3GF-k-H9G5jULRZhY8pQrpY-jzABJ5yUKcHXHNWdAz0jH5lI7dkOZ6pPtCa2sJQ_"

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

    unmounted_volumes+=( " Disk Number : ${count} \n--------------------------------------------------------\n \t Name: \t\t\t${name}\n \t Resource Group:   ${resource_group}\n \t Size:\t\t\t ${size}GB \n \t Tags:\t\t\t ${tags} \n")

    ((count++))
done

# message alert send on the discord how many total number of volumes
count=$((count - 1))

# Start of the box
message="\`\`\`" 

message+="Total number of unmounted managed volumes: ${count}.\n \n"

if [ $count -gt $UNMOUNTED_VOLUME_THRESHOLD ]; 
then
    # Add details of unmounted volumes to the message
    for volume in "${unmounted_volumes[@]}"; do
        message+="${volume}\n"
    done
else
    message+="Total number of unmounted managed disk doesn't exceed from the threshold value: $UNMOUNTED_VOLUME_THRESHOLD "
fi

# End of the box
message+="\`\`\`" 


curl -H "Content-Type: application/json" -X POST -d "{\"content\":\"${message}\"}" $YOUR_DISCORD_WEBHOOK_URL
