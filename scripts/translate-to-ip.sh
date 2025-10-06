#!/bin/bash
# filepath: /Users/dotkaio/.config/get_ips.sh

# Function to resolve domain to IP
resolve_domain() {
    local domain=$1
    local ips=$(dig +short "$domain" | grep -E '^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$')
    if [ ! -z "$ips" ]; then
        echo "$domain -> $ips"
    fi
}

# Create temporary file for storing results
tmp_file=$(mktemp)

# Process domains from both files in parallel
while read -r line; do
    # Skip comments and empty lines
    [[ $line =~ ^[[:space:]]*# ]] && continue
    [[ -z $line ]] && continue
    
    # Extract domain from line
    domain=$(echo "$line" | grep -v '^;' | tr -d ' ')
    if [ ! -z "$domain" ]; then
        resolve_domain "$domain" >> "$tmp_file" &
    fi
done < /Users/dotkaio/.config/blocked/blocked

while read -r line; do
    # Skip comments and empty lines
    [[ $line =~ ^[[:space:]]*# ]] && continue
    [[ -z $line ]] && continue
    
    # Extract domain from line
    domain=$(echo "$line" | grep -v '^;' | tr -d ' ')
    if [ ! -z "$domain" ]; then
        resolve_domain "$domain" >> "$tmp_file" &
    fi
done < /Users/dotkaio/.config/blocked/blocked-no-ip

# Wait for all background processes to complete
wait

# Sort and remove duplicates from results
sort -u "$tmp_file"

# Cleanup
rm "$tmp_file"