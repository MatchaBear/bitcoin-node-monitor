#!/bin/bash

# Simple Bitcoin Monitor - Reliable Version
# Uses professional libraries but with simplified approach
# Version: 3.0.0

# Script directory
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
if [[ -f "$SCRIPT_DIR/.env" ]]; then
    set -a
    source "$SCRIPT_DIR/.env"
    set +a
fi

# Set environment for libraries
export BITCOIN_PROJECT_ROOT="$SCRIPT_DIR"

# Source libraries
source "$SCRIPT_DIR/lib/currency_manager.sh"

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
RPC_USER=${BTC_RPC_USER:-"bitcoinrpc"}
RPC_PASS=${BTC_RPC_PASS:-""}

bitcoin_cli() {
    docker exec "$CONTAINER_NAME" bitcoin-cli -rpcuser="$RPC_USER" -rpcpassword="$RPC_PASS" "$@"
}

# Function to display header
display_header() {
    echo -e "${BOLD}${CYAN}============================================${NC}"
    echo -e "${BOLD}${YELLOW}    🟠 Bitcoin Node Monitor (Simple)     ${NC}"
    echo -e "${BOLD}${CYAN}============================================${NC}"
    echo -e "${WHITE}📅 $(date '+%Y-%m-%d %H:%M:%S')${NC}"
    echo -e "${CYAN}============================================${NC}"
    echo
}

# Function to get node status - individual data for better reliability
get_blockchain_info() {
    bitcoin_cli getblockchaininfo 2>/dev/null
}

get_network_info() {
    bitcoin_cli getnetworkinfo 2>/dev/null
}

get_mempool_info() {
    bitcoin_cli getmempoolinfo 2>/dev/null
}

# Function to display node status
display_node_status() {
    echo -e "${BOLD}${GREEN}🔧 NODE STATUS${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    
    # Get individual data
    local sync_info network_info mempool_info
    sync_info=$(get_blockchain_info)
    network_info=$(get_network_info)
    mempool_info=$(get_mempool_info)
    
    if [[ -z "$sync_info" ]]; then
        echo -e "${RED}❌ Node connection failed${NC}"
        return 1
    fi
    
    local headers blocks connections mempool_size mempool_bytes
    headers=$(echo "$sync_info" | jq -r '.headers // 0')
    blocks=$(echo "$sync_info" | jq -r '.blocks // 0')
    connections=$(echo "$network_info" | jq -r '.connections // 0')
    mempool_size=$(echo "$mempool_info" | jq -r '.size // 0')
    mempool_bytes=$(echo "$mempool_info" | jq -r '.bytes // 0')
    
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

# Function to fetch simple price data with multiple APIs
fetch_simple_price() {
    local currency="$1"
    local currency_upper=$(echo "$currency" | tr '[:lower:]' '[:upper:]')
    local currency_lower=$(echo "$currency" | tr '[:upper:]' '[:lower:]')
    
    # API 1: CryptoCompare
    local result
    result=$(curl -s --connect-timeout 3 --max-time 8 \
        "https://min-api.cryptocompare.com/data/price?fsym=BTC&tsyms=$currency_upper" 2>/dev/null)
    
    if [[ ! -z "$result" ]] && echo "$result" | jq . >/dev/null 2>&1; then
        local price
        price=$(echo "$result" | jq -r ".$currency_upper // 0")
        if [[ "$price" != "0" && "$price" != "null" ]]; then
            echo "$price"
            return 0
        fi
    fi
    
    # API 2: Binance (for USD)
    if [[ "$currency_upper" == "USD" ]]; then
        result=$(curl -s --connect-timeout 3 --max-time 8 \
            "https://api.binance.com/api/v3/ticker/price?symbol=BTCUSDT" 2>/dev/null)
        
        if [[ ! -z "$result" ]] && echo "$result" | jq . >/dev/null 2>&1; then
            local price
            price=$(echo "$result" | jq -r '.price // 0')
            if [[ "$price" != "0" && "$price" != "null" ]]; then
                echo "$price"
                return 0
            fi
        fi
    fi
    
    # API 3: CoinGecko (rate limited but reliable)
    result=$(curl -s --connect-timeout 3 --max-time 8 \
        "https://api.coingecko.com/api/v3/simple/price?ids=bitcoin&vs_currencies=$currency_lower" 2>/dev/null)
    
    if [[ ! -z "$result" ]] && echo "$result" | jq . >/dev/null 2>&1; then
        local price
        price=$(echo "$result" | jq -r ".bitcoin.$currency_lower // 0")
        if [[ "$price" != "0" && "$price" != "null" ]]; then
            echo "$price"
            return 0
        fi
    fi
    
    # Fallback to configured fallback value
    get_ath_fallback "$currency_upper"
}

# Function to display simple market data
display_market_data() {
    echo -e "${BOLD}${PURPLE}💰 MARKET DATA${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    
    # Get current time
    local current_time
    current_time=$(date '+%Y-%m-%d %H:%M:%S UTC')
    echo -e "${CYAN}📡 Last fetched: $current_time${NC}"
    echo
    
    # Priority currencies only to avoid complexity
    local priority_currencies=("USD" "EUR" "SGD" "IDR")
    
    for currency in "${priority_currencies[@]}"; do
        local price flag symbol
        
        # Get currency metadata
        flag=$(get_currency_flag "$currency")
        symbol=$(get_currency_symbol "$currency")
        
        # Fetch current price
        price=$(fetch_simple_price "$currency")
        
        # Format display
        local formatted_price
        if [[ "$currency" == "JPY" || "$currency" == "KRW" || "$currency" == "IDR" ]]; then
            formatted_price=$(printf "%'.0f" "$price")
        else
            formatted_price=$(printf "%'.2f" "$price")
        fi
        
        echo -e "$flag ${currency}: ${WHITE}${symbol}${formatted_price}${NC}"
    done
    echo
}

# Function to display supply information
display_supply_info() {
    echo -e "${BOLD}${BLUE}⚡ SUPPLY INFO${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    
    local sync_info
    sync_info=$(get_blockchain_info)
    
    if [[ -z "$sync_info" ]]; then
        echo -e "${RED}❌ Supply data unavailable${NC}"
        return 1
    fi
    
    local blocks
    blocks=$(echo "$sync_info" | jq -r '.blocks // 0')
    
    # Simple supply calculation
    local current_height max_supply halving_interval current_era current_reward
    current_height=$blocks
    max_supply=21000000
    halving_interval=210000
    current_era=$((current_height / halving_interval))
    current_reward=$(echo "scale=8; 50 / (2 ^ $current_era)" | bc)
    
    # Efficient supply calculation
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

# Main monitoring loop
main() {
    # Initialize libraries
    if ! init_currency_manager; then
        echo -e "${RED}❌ Failed to initialize currency manager${NC}"
        exit 1
    fi
    
    echo -e "${BOLD}${GREEN}Starting Simple Bitcoin Node Monitor...${NC}"
    echo -e "${YELLOW}Press Ctrl+C to stop monitoring${NC}"
    sleep 2
    
    # Main monitoring loop
    while true; do
        clear
        
        # Display header
        display_header
        
        # Display all sections
        display_node_status
        display_market_data
        display_supply_info
        
        # Footer
        echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        echo -e "${WHITE}🔄 Auto-refresh in ${REFRESH_INTERVAL}s | Press ${BOLD}Ctrl+C${NC}${WHITE} to exit${NC}"
        echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
        
        sleep $REFRESH_INTERVAL
    done
}

# Run main function
main "$@"
