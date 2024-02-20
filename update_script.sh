#!/bin/bash

# Azure CLI command to list all disks
disks=$(az disk list --query "[?diskState=='Unattached']")

# Prompt user to choose whether to delete unattached disks
echo "Enter your threshold value:"
read UNMOUNTED_VOLUME_THRESHOLD

# Discord webhook url
YOUR_DISCORD_WEBHOOK_URL="https://discord.com/api/webhooks/1207684722302652446/hgy3GF-k-H9G5jULRZhY8pQrpY-jzABJ5yUKcHXHNWdAz0jH5lI7dkOZ6pPtCa2sJQ_"

# Counter for unmounted volumes
count=1

# Get the length of disks array
length=$(echo "$disks" | jq length)
echo $length

# Initialize an array to hold messages
messages=()

# Iterate over each disk
for (( i=0; i<$length; i++ )); do
    # Extract disk information
    disk=$(echo "$disks" | jq -r ".[$i]")
    name=$(jq -r '.name' <<< "$disk")
    resource_group=$(jq -r '.resourceGroup' <<< "$disk")
    size=$(jq -r '.diskSizeGB' <<< "$disk")
    tags=$(jq -r '.tags | to_entries | map("\(.key)=\(.value)") | join(", ")' <<< "$disk")

    message="\`\`\`" 

    # Construct the message for the disk
    message+="Disk Number : $count\n--------------------------------------------------------\nName: $name\n\nResource Group: $resource_group\n\nSize: ${size}GB\n\nTags: $tags\n"
    
    message+="\`\`\`" 

    # Append the message to the messages array
    messages+=("$message")
    
    # Increment the counter
    ((count++))
done

# Check if the number of unmounted volumes exceeds the threshold
if (( length > UNMOUNTED_VOLUME_THRESHOLD )); then
    # Initialize a variable to hold the cumulative message
    cumulative_message=""

    # Iterate over the messages array
    for msg in "${messages[@]}"; do
        # Check if the length of the cumulative message exceeds 1500 characters
        if (( ${#cumulative_message} > 1500 && ${#cumulative_message} < 2000 )); then
            # Send the cumulative message to Discord webhook
            curl -H "Content-Type: application/json" -X POST -d "{\"content\":\"$cumulative_message\"}" "$YOUR_DISCORD_WEBHOOK_URL"
            # Reset the cumulative message
            cumulative_message=""
        fi
        
        # Append the current message to the cumulative message
        temp_msg="$cumulative_message\n$msg"
        
        # Check if the length of the new cumulative message exceeds 2000 characters
        if (( ${#temp_msg} > 2000 )); then
            # Send the current message separately
            curl -H "Content-Type: application/json" -X POST -d "{\"content\":\"$cumulative_message\"}" "$YOUR_DISCORD_WEBHOOK_URL"
            # Reset the cumulative message
            cumulative_message="$msg"
        else
            # Update the cumulative message
            cumulative_message="$temp_msg"
        fi
    done

    # Check if there's any remaining message
    if [ -n "$cumulative_message" ]; then
        # Send the remaining cumulative message
        curl -H "Content-Type: application/json" -X POST -d "{\"content\":\"$cumulative_message\"}" "$YOUR_DISCORD_WEBHOOK_URL"
    fi
fi
