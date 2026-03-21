#!/bin/bash

# Professional Bitcoin Node & Market Monitor
# Uses modern library architecture with configuration-driven approach
# Author: Bitcoin Node Monitor Project  
# Version: 3.0.0

# Script directory detection
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [[ -f "$SCRIPT_DIR/.env" ]]; then
    set -a
    source "$SCRIPT_DIR/.env"
    set +a
fi

# Source required libraries
source "$SCRIPT_DIR/lib/currency_manager.sh"
source "$SCRIPT_DIR/lib/node_info.sh"

# Color definitions  
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly PURPLE='\033[0;35m'
readonly CYAN='\033[0;36m'
readonly WHITE='\033[1;37m'
readonly BOLD='\033[1m'
readonly NC='\033[0m'

# Configuration
readonly CONTAINER_NAME="bitcoin-node"
readonly REFRESH_INTERVAL=30
readonly UPDATE_INTERVAL=10
RPC_USER=${BTC_RPC_USER:-"bitcoinrpc"}
RPC_PASS=${BTC_RPC_PASS:-""}

bitcoin_cli() {
    docker exec "$CONTAINER_NAME" bitcoin-cli -rpcuser="$RPC_USER" -rpcpassword="$RPC_PASS" "$@"
}

# Function to display header
display_header() {
    echo -e "${BOLD}${CYAN}============================================${NC}"
    echo -e "${BOLD}${YELLOW}    🟠 Bitcoin Node & Market Monitor     ${NC}"
    echo -e "${BOLD}${CYAN}============================================${NC}"
    echo -e "${WHITE}📅 $(date '+%Y-%m-%d %H:%M:%S')${NC}"
    echo -e "${CYAN}============================================${NC}"
    echo
}

# Function to get node status
get_node_status() {
    local sync_info network_info mempool_info
    
    sync_info=$(bitcoin_cli getblockchaininfo 2>/dev/null)
    network_info=$(bitcoin_cli getnetworkinfo 2>/dev/null)
    mempool_info=$(bitcoin_cli getmempoolinfo 2>/dev/null)
    
    if [[ $? -ne 0 || -z "$sync_info" ]]; then
        return 1
    fi
    
    # Create combined JSON output
    jq -n --argjson sync "$sync_info" \
          --argjson network "$network_info" \
          --argjson mempool "$mempool_info" \
          '{
              "headers": $sync.headers,
              "blocks": $sync.blocks,
              "connections": $network.connections,
              "mempool_size": $mempool.size,
              "mempool_bytes": $mempool.bytes
          }'
}

# Function to display node status
display_node_status() {
    local node_data="$1"
    
    echo -e "${BOLD}${GREEN}🔧 NODE STATUS${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    
    if [[ -z "$node_data" ]]; then
        echo -e "${RED}❌ Node connection failed${NC}"
        return 1
    fi
    
    local headers blocks connections mempool_size mempool_bytes
    headers=$(echo "$node_data" | jq -r '.headers')
    blocks=$(echo "$node_data" | jq -r '.blocks')
    connections=$(echo "$node_data" | jq -r '.connections')
    mempool_size=$(echo "$node_data" | jq -r '.mempool_size')
    mempool_bytes=$(echo "$node_data" | jq -r '.mempool_bytes')
    
    # Sync status with color
    local sync_status
    if [[ "$blocks" -eq "$headers" ]]; then
        sync_status="${GREEN}✅ Fully Synced${NC}"
    else
        local sync_percent
        sync_percent=$(echo "scale=2; $blocks * 100 / $headers" | bc)
        sync_status="${YELLOW}⚠️  Syncing ($sync_percent%)${NC}"
    fi
    
    # Peer status with color
    local peer_status
    if [[ "$connections" -ge 8 ]]; then
        peer_status="${GREEN}$connections${NC}"
    elif [[ "$connections" -ge 4 ]]; then
        peer_status="${YELLOW}$connections${NC}"
    else
        peer_status="${RED}$connections${NC}"
    fi
    
    echo -e "Status: $sync_status"
    echo -e "Height: ${WHITE}$(printf "%'d" $blocks)${NC} / ${WHITE}$(printf "%'d" $headers)${NC}"
    echo -e "Peers: $peer_status"
    echo -e "Mempool: ${WHITE}$(printf "%'d" $mempool_size)${NC} tx ($(echo "scale=1; $mempool_bytes/1024/1024" | bc) MB)"
    echo
}

# Function to fetch price for currency using library
fetch_currency_price() {
    local currency="$1"
    local currency_upper=$(echo "$currency" | tr '[:lower:]' '[:upper:]')
    
    # Try CryptoCompare API first
    local result
    result=$(curl -s --connect-timeout 5 --max-time 10 \
        "https://min-api.cryptocompare.com/data/pricemultifull?fsyms=BTC&tsyms=$currency_upper" 2>/dev/null)
    
    if [[ ! -z "$result" ]] && echo "$result" | jq . >/dev/null 2>&1 && [[ "$result" == *"CHANGEPCT24HOUR"* ]]; then
        local price change
        price=$(echo "$result" | jq -r ".RAW.BTC.$currency_upper.PRICE // 0")
        change=$(echo "$result" | jq -r ".RAW.BTC.$currency_upper.CHANGEPCT24HOUR // 0")
        
        if [[ "$price" != "0" ]]; then
            echo "$price|$change|CryptoCompare"
            return 0
        fi
    fi
    
    # Fallback to configured fallback value
    local fallback_price
    fallback_price=$(get_ath_fallback "$currency_upper")
    echo "$fallback_price|0|Fallback"
}

# Function to display market data using library
display_market_data() {
    echo -e "${BOLD}${PURPLE}💰 MARKET DATA ${CYAN}(Dynamic Multi-Currency)${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    
    # Get current time information
    local api_time sg_time jkt_time
    api_time=$(TZ='UTC' date '+%Y-%m-%d %H:%M:%S')
    sg_time=$(TZ='Asia/Singapore' date '+%Y-%m-%d %H:%M:%S')
    jkt_time=$(TZ='Asia/Jakarta' date '+%Y-%m-%d %H:%M:%S')
    
    echo -e "${CYAN}📡 Last fetched: $api_time UTC${NC}"
    echo -e "${CYAN}   Singapore: $sg_time SGT | Jakarta: $jkt_time WIB${NC}"
    echo
    
    # Get all supported currencies from library
    local currencies
    # Use read array instead of mapfile for compatibility
    IFS=$'\n' read -d '' -r -a currencies < <(get_supported_currencies)
    
    # Fetch and display prices for each currency
    for currency in "${currencies[@]}"; do
        local price_data flag symbol format
        
        # Get currency metadata from library
        flag=$(get_currency_flag "$currency")
        symbol=$(get_currency_symbol "$currency")
        format=$(get_display_format "$currency")
        
        # Fetch current price
        IFS='|' read price change provider <<< "$(fetch_currency_price "$currency")"
        
        # Format change indicator
        local change_indicator
        if (( $(echo "$change > 0" | bc -l 2>/dev/null || echo 0) )); then
            change_indicator="${GREEN}▲ $(printf "%.2f" "$change")%${NC}"
        elif (( $(echo "$change < 0" | bc -l 2>/dev/null || echo 0) )); then
            change_indicator="${RED}▼ $(printf "%.2f" "$change")%${NC}"
        else
            change_indicator="${YELLOW}═ 0.00%${NC}"
        fi
        
        # Format price according to currency configuration
        local formatted_price
        formatted_price=$(format_currency_price "$currency" "$price")
        
        echo -e "$flag ${currency}: ${WHITE}${formatted_price}${NC} $change_indicator ${CYAN}($provider)${NC}"
    done
    echo
}

# Function to display supply information
display_supply_info() {
    local node_data="$1"
    
    echo -e "${BOLD}${BLUE}⚡ SUPPLY INFO${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    
    if [[ -z "$node_data" ]]; then
        echo -e "${RED}❌ Supply data unavailable${NC}"
        return 1
    fi
    
    local blocks
    blocks=$(echo "$node_data" | jq -r '.blocks')
    
    # Calculate supply efficiently
    local current_height max_supply halving_interval current_era current_reward
    current_height=$blocks
    max_supply=21000000
    halving_interval=210000
    current_era=$((current_height / halving_interval))
    current_reward=$(echo "scale=8; 50 / (2 ^ $current_era)" | bc)
    
    # Simple supply calculation
    local total_supply=0
    local temp_height=$current_height
    local reward=50
    
    for ((i=0; i<current_era; i++)); do
        total_supply=$(echo "$total_supply + ($halving_interval * $reward)" | bc)
        reward=$(echo "scale=8; $reward / 2" | bc)
        temp_height=$((temp_height - halving_interval))
    done
    
    total_supply=$(echo "$total_supply + ($temp_height * $reward)" | bc)
    local remaining
    remaining=$(echo "$max_supply - $total_supply" | bc)
    local percent_mined
    percent_mined=$(echo "scale=6; $total_supply * 100 / $max_supply" | bc)
    
    # Next halving
    local next_halving blocks_to_halving days_to_halving
    next_halving=$(( ((current_height/halving_interval)+1)*halving_interval ))
    blocks_to_halving=$((next_halving - current_height))
    days_to_halving=$((blocks_to_halving * 10 / 1440))
    
    echo -e "Current Supply: ${WHITE}$(printf "%'.0f" "$total_supply")${NC} BTC (${percent_mined}%)"
    echo -e "Remaining: ${WHITE}$(printf "%'.0f" "$remaining")${NC} BTC"
    echo -e "Block Reward: ${WHITE}$current_reward${NC} BTC"
    echo -e "Next Halving: ${YELLOW}$(printf "%'d" $blocks_to_halving)${NC} blocks (~$(printf "%'d" $days_to_halving) days)"
    echo
}

# Function to display peer information summary
display_peer_summary() {
    echo -e "${BOLD}${GREEN}🌐 NETWORK CONNECTIONS${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    
    local peer_data
    peer_data=$(docker exec "$CONTAINER_NAME" bitcoin-cli getpeerinfo 2>/dev/null)
    
    if [[ $? -ne 0 ]]; then
        echo -e "${RED}❌ Failed to get peer information${NC}"
        return 1
    fi
    
    local peer_count
    peer_count=$(echo "$peer_data" | jq '. | length')
    
    echo -e "Connected Peers: ${WHITE}$peer_count${NC}"
    
    # Show top 5 peers with country information
    echo -e "${CYAN}Top Connections:${NC}"
    echo "$peer_data" | jq -r '.[:5] | .[] | .addr' | while read -r addr; do
        local clean_ip flag name
        clean_ip=$(echo "$addr" | cut -d':' -f1 | sed 's/\[//g' | sed 's/\]//g')
        
        # Get country info using library
        local country_info
        country_info=$(get_country_info_from_ip "$clean_ip")
        
        if [[ $? -eq 0 ]]; then
            flag=$(echo "$country_info" | jq -r '.flag // "🏳️"')
            name=$(echo "$country_info" | jq -r '.name // "Unknown"')
        else
            flag="🏳️"
            name="Unknown"
        fi
        
        echo -e "   $flag ${WHITE}$addr${NC} ${CYAN}($name)${NC}"
    done
    echo
}

# Main monitoring loop
main() {
    # Initialize libraries
    if ! init_currency_manager; then
        echo -e "${RED}❌ Failed to initialize currency manager${NC}"
        exit 1
    fi
    
    if ! init_node_info; then
        echo -e "${RED}❌ Failed to initialize node info manager${NC}"
        exit 1
    fi
    
    echo -e "${BOLD}${GREEN}Starting Professional Bitcoin Node Monitor...${NC}"
    sleep 1
    
    # Main monitoring loop
    while true; do
        clear
        
        # Display header
        display_header
        
        # Get node status
        local node_data
        node_data=$(get_node_status)
        
        # Display all sections
        display_node_status "$node_data"
        display_market_data
        display_supply_info "$node_data"
        display_peer_summary
        
        # Footer
        echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo -e "${WHITE}🔄 Auto-refresh in ${REFRESH_INTERVAL}s | Press ${BOLD}Ctrl+C${NC}${WHITE} to exit${NC}"
        echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        
        sleep $REFRESH_INTERVAL
    done
}

# Run main function
main "$@"
