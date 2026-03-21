#!/bin/bash

# Professional Bitcoin Peer Monitor
# Uses modern library architecture with caching and API integration
# Author: Bitcoin Node Monitor Project
# Version: 3.1.0

# Script directory detection
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [[ -f "$SCRIPT_DIR/.env" ]]; then
    set -a
    source "$SCRIPT_DIR/.env"
    set +a
fi

# Source required libraries
source "$SCRIPT_DIR/lib/node_info.sh"
source "$SCRIPT_DIR/lib/currency_manager.sh"

# Color definitions
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly CYAN='\033[0;36m'
readonly WHITE='\033[1;37m'
readonly BOLD='\033[1m'
readonly NC='\033[0m'

# Configuration
readonly CONTAINER_NAME="bitcoin-node"
readonly MAX_DISPLAY_PEERS=20
RPC_USER=${BTC_RPC_USER:-"bitcoinrpc"}
RPC_PASS=${BTC_RPC_PASS:-""}

bitcoin_cli() {
    docker exec "$CONTAINER_NAME" bitcoin-cli -rpcuser="$RPC_USER" -rpcpassword="$RPC_PASS" "$@"
}

# Function to get peer information
get_peer_info() {
    local peer_data
    peer_data=$(bitcoin_cli getpeerinfo 2>/dev/null)
    
    if [[ $? -ne 0 ]]; then
        echo -e "${RED}❌ Failed to get peer data. Ensure node is running and container is correct.${NC}"
        return 1
    fi
    
    echo "$peer_data"
}

# Function to display peer information with country info
display_peer_info() {
    local peer_data="$1"
    
    # Get basic peer count
    local peer_count
    peer_count=$(echo "$peer_data" | jq '. | length')
    
    echo -e "${BOLD}${GREEN}🌐 Bitcoin Node Peer Information${NC}"
    echo -e "${CYAN}═══════════════════════════════════════${NC}"
    echo -e "${WHITE}📊 Total Connected Peers: ${BOLD}$peer_count${NC}"
    echo -e "${CYAN}═══════════════════════════════════════${NC}"
    
    if [[ $peer_count -eq 0 ]]; then
        echo -e "${YELLOW}⚠️  No peers connected${NC}"
        return 0
    fi
    
    # Display peer details with country information
    local displayed=0
    echo "$peer_data" | jq -r '.[] | "\(.addr) \(.inbound) \(.version) \(.subver) \(.bytesrecv) \(.bytessent)"' | while read -r addr inbound version subver bytesrecv bytessent; do
        if [[ $displayed -ge $MAX_DISPLAY_PEERS ]]; then
            echo -e "${YELLOW}... and $((peer_count - MAX_DISPLAY_PEERS)) more peers${NC}"
            break
        fi
        
        # Clean IP address for geolocation
        local clean_ip
        clean_ip=$(echo "$addr" | cut -d':' -f1 | sed 's/\[//g' | sed 's/\]//g')
        
        # Get country information using our library
        local country_info
        country_info=$(get_country_info_from_ip "$clean_ip")
        
        local flag name
        if [[ $? -eq 0 ]]; then
            flag=$(echo "$country_info" | jq -r '.flag // "🏳️"')
            name=$(echo "$country_info" | jq -r '.name // "Unknown"')
        else
            flag="🏳️"
            name="Unknown"
        fi
        
        # Format connection type
        local connection_type
        if [[ "$inbound" == "true" ]]; then
            connection_type="${GREEN}IN${NC}"
        else
            connection_type="${BLUE}OUT${NC}"
        fi
        
        # Format data transfer
        local recv_mb sent_mb
        recv_mb=$(echo "scale=2; $bytesrecv / 1024 / 1024" | bc)
        sent_mb=$(echo "scale=2; $bytessent / 1024 / 1024" | bc)
        
        # Clean up subver
        local clean_subver
        clean_subver=$(echo "$subver" | sed 's/^\/\(.*\)\/$/\1/' | cut -c1-20)
        
        echo -e "${flag} ${WHITE}$addr${NC} [$connection_type] ${CYAN}($name)${NC}"
        echo -e "   Version: ${YELLOW}$version${NC} Client: ${YELLOW}$clean_subver${NC}"
        echo -e "   Data: ${WHITE}↓${recv_mb}MB${NC} ${WHITE}↑${sent_mb}MB${NC}"
        echo
        
        ((displayed++))
    done
    
    # Show connection statistics
    echo -e "${CYAN}═══════════════════════════════════════${NC}"
    local inbound_count outbound_count
    inbound_count=$(echo "$peer_data" | jq '[.[] | select(.inbound == true)] | length')
    outbound_count=$(echo "$peer_data" | jq '[.[] | select(.inbound == false)] | length')
    
    echo -e "${WHITE}📈 Connection Statistics:${NC}"
    echo -e "   Inbound:  ${GREEN}$inbound_count${NC} connections"
    echo -e "   Outbound: ${BLUE}$outbound_count${NC} connections"
    
    # Show network diversity
    local unique_countries
    unique_countries=$(echo "$peer_data" | jq -r '.[] | .addr' | while read -r addr; do
        local clean_ip
        clean_ip=$(echo "$addr" | cut -d':' -f1 | sed 's/\[//g' | sed 's/\]//g')
        local country_info
        country_info=$(get_country_info_from_ip "$clean_ip")
        if [[ $? -eq 0 ]]; then
            echo "$country_info" | jq -r '.name // "Unknown"'
        else
            echo "Unknown"
        fi
    done | sort | uniq | wc -l)
    
    echo -e "   Network Diversity: ${YELLOW}$unique_countries${NC} countries"
    
    # Health assessment
    local health_status
    if [[ $peer_count -ge 8 ]]; then
        health_status="${GREEN}✅ Healthy${NC}"
    elif [[ $peer_count -ge 4 ]]; then
        health_status="${YELLOW}⚠️  Moderate${NC}"
    else
        health_status="${RED}❌ Poor${NC}"
    fi
    
    echo -e "   Network Health: $health_status"
    echo -e "${CYAN}═══════════════════════════════════════${NC}"
}

# Main execution
main() {
    # Initialize libraries
    if ! init_node_info; then
        echo -e "${RED}❌ Failed to initialize node info library${NC}"
        exit 1
    fi
    
    if ! init_currency_manager; then
        echo -e "${RED}❌ Failed to initialize currency manager library${NC}"
        exit 1
    fi
    
    # Get and display peer information
    local peer_data
    peer_data=$(get_peer_info)
    
    if [[ $? -eq 0 ]]; then
        display_peer_info "$peer_data"
    else
        echo -e "${RED}❌ Failed to retrieve peer information${NC}"
        exit 1
    fi
}

# Run main function
main "$@"
