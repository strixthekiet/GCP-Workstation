#!/bin/bash
auth_token=$1
zone_id=$2
shift 2  # Remove first two arguments (auth_token and zone_id)

# Remaining arguments are the DNS records
records=("$@")

# Proxy status: true (Cloudflare CDN on) or false (DNS only)
proxied=false

# --- END CONFIGURATION ---

# 1. Get Current Public IP
echo "Fetching current public IP..."
current_ip=$(curl -s https://api.ipify.org)

if [[ -z "$current_ip" ]]; then
    echo "Error: Could not determine public IP."
    exit 1
fi

echo "Current IP is: $current_ip"

# 2. Loop through records and update
for record_name in "${records[@]}"; do
    echo "--------------------------------------------------"
    echo "Processing: $record_name"

    # Get the DNS Record ID for this name
    # We filter by type=A and name=$record_name
    record_info=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones/$zone_id/dns_records?type=A&name=$record_name" \
        -H "Authorization: Bearer $auth_token" \
        -H "Content-Type: application/json")

    # Extract ID and current IP from Cloudflare
    record_id=$(echo "$record_info" | jq -r '.result[0].id')
    cf_ip=$(echo "$record_info" | jq -r '.result[0].content')
    success=$(echo "$record_info" | jq -r '.success')

    if [[ "$success" != "true" ]]; then
        echo "Error fetching record details. Check your Zone ID and Token."
        echo "Response: $(echo "$record_info" | jq -r '.errors[0].message')"
        continue
    fi

    if [[ "$record_id" == "null" ]]; then
        echo "Record '$record_name' does not exist in Cloudflare. Creating it..."
        
        create_response=$(curl -s -X POST "https://api.cloudflare.com/client/v4/zones/$zone_id/dns_records" \
            -H "Authorization: Bearer $auth_token" \
            -H "Content-Type: application/json" \
            --data "{\"type\":\"A\",\"name\":\"$record_name\",\"content\":\"$current_ip\",\"ttl\":1,\"proxied\":$proxied}")
            
        if [[ $(echo "$create_response" | jq -r '.success') == "true" ]]; then
             echo "Successfully created $record_name pointing to $current_ip"
        else
             echo "Failed to create record."
             echo "Error: $(echo "$create_response" | jq -r '.errors[0].message')"
        fi
        
    elif [[ "$cf_ip" == "$current_ip" ]]; then
        echo "IP matches. No update needed for $record_name."
    else
        echo "IP mismatch (Cloudflare: $cf_ip vs Current: $current_ip). Updating..."
        
        update_response=$(curl -s -X PUT "https://api.cloudflare.com/client/v4/zones/$zone_id/dns_records/$record_id" \
            -H "Authorization: Bearer $auth_token" \
            -H "Content-Type: application/json" \
            --data "{\"type\":\"A\",\"name\":\"$record_name\",\"content\":\"$current_ip\",\"ttl\":1,\"proxied\":$proxied}")

        if [[ $(echo "$update_response" | jq -r '.success') == "true" ]]; then
            echo "Success! Updated $record_name to $current_ip"
        else
            echo "Failed to update record."
            echo "Error: $(echo "$update_response" | jq -r '.errors[0].message')"
        fi
    fi
done

echo "--------------------------------------------------"
echo "Done."