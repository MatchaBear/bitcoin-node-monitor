#!/bin/bash

# Professional Node Info Library
# Handles dynamic country/flag detection and peer information
# Author: Bitcoin Node Monitor Project
# Version: 3.0.0

# Configuration paths
if [[ -n "${BITCOIN_PROJECT_ROOT:-}" ]]; then
    # Use environment variable if set
    readonly LIB_SCRIPT_DIR="$BITCOIN_PROJECT_ROOT"
else
    # Detect project root from library location
    readonly LIB_SCRIPT_DIR="$(cd "$(dirname "$(dirname "${BASH_SOURCE[0]}")")" && pwd)"
fi

readonly CONFIG_DIR="$LIB_SCRIPT_DIR/config"
readonly CACHE_DIR="$LIB_SCRIPT_DIR/cache"
readonly NODE_CONFIG="$CONFIG_DIR/node_info.json"
readonly COUNTRY_CACHE="$CACHE_DIR/country_cache.json"

# Ensure cache directory exists
mkdir -p "$CACHE_DIR"

# Color definitions (only define if not already defined)
if [[ -z "${RED:-}" ]]; then
    readonly RED='\033[0;31m'
    readonly GREEN='\033[0;32m'
    readonly YELLOW='\033[1;33m'
    readonly BLUE='\033[0;34m'
    readonly PURPLE='\033[0;35m'
    readonly CYAN='\033[0;36m'
    readonly WHITE='\033[1;37m'
    readonly BOLD='\033[1m'
    readonly NC='\033[0m'
fi

# API configuration
COUNTRY_API_BASE=""
API_TIMEOUT=""
MAX_RETRIES=""
CACHE_DURATION=""

# Initialize node info manager
init_node_info() {
    if [[ ! -f "$NODE_CONFIG" ]]; then
        log_error "Node info configuration not found: $NODE_CONFIG"
        return 1
    fi
    
    # Load API configuration
    COUNTRY_API_BASE=$(jq -r '.api_config.country_api' "$NODE_CONFIG")
    API_TIMEOUT=$(jq -r '.api_config.timeout' "$NODE_CONFIG")
    MAX_RETRIES=$(jq -r '.api_config.max_retries' "$NODE_CONFIG")
    CACHE_DURATION=$(jq -r '.api_config.cache_duration' "$NODE_CONFIG")
    
    log_debug "Node info manager initialized with API: $COUNTRY_API_BASE"
    return 0
}

# Logging functions
log_error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
}

log_debug() {
    [[ "${DEBUG:-0}" == "1" ]] && echo -e "${CYAN}[DEBUG]${NC} $1" >&2
}

log_info() {
    echo -e "${GREEN}[INFO]${NC} $1" >&2
}

# Check if cache is valid
is_country_cache_valid() {
    [[ -f "$COUNTRY_CACHE" ]] || return 1
    
    local cache_timestamp
    cache_timestamp=$(jq -r '.timestamp // 0' "$COUNTRY_CACHE" 2>/dev/null)
    local current_timestamp=$(date +%s)
    local cache_age=$((current_timestamp - cache_timestamp))
    
    [[ $cache_age -lt $CACHE_DURATION ]]
}

# Fetch country data from IP
fetch_country_from_ip() {
    local ip="$1"
    local retries=0
    
    while [[ $retries -lt $MAX_RETRIES ]]; do
        # Try ipinfo.io first
        local result
        result=$(curl -s --connect-timeout "$API_TIMEOUT" --max-time "$API_TIMEOUT" \
                     "https://ipinfo.io/$ip/country" 2>/dev/null)
        
        if [[ $? -eq 0 ]] && [[ ! -z "$result" ]] && [[ ${#result} -eq 2 ]]; then
            echo "$result"
            return 0
        fi
        
        # Fallback to ip-api.com
        result=$(curl -s --connect-timeout "$API_TIMEOUT" --max-time "$API_TIMEOUT" \
                     "http://ip-api.com/json/$ip?fields=countryCode" 2>/dev/null)
        
        if [[ $? -eq 0 ]] && echo "$result" | jq . >/dev/null 2>&1; then
            local country_code
            country_code=$(echo "$result" | jq -r '.countryCode // ""')
            if [[ ! -z "$country_code" ]]; then
                echo "$country_code"
                return 0
            fi
        fi
        
        ((retries++))
        log_debug "Retry $retries/$MAX_RETRIES for IP $ip"
        sleep 1
    done
    
    log_error "Failed to fetch country for IP $ip after $MAX_RETRIES attempts"
    return 1
}

# Get country flag from REST Countries API
get_country_flag_from_api() {
    local country_code="$1"
    local retries=0
    
    while [[ $retries -lt $MAX_RETRIES ]]; do
        local result
        result=$(curl -s --connect-timeout "$API_TIMEOUT" --max-time "$API_TIMEOUT" \
                     "$COUNTRY_API_BASE/alpha/$country_code?fields=flag" 2>/dev/null)
        
        if [[ $? -eq 0 ]] && echo "$result" | jq . >/dev/null 2>&1; then
            local flag
            flag=$(echo "$result" | jq -r '.flag // "🏳️"')
            echo "$flag"
            return 0
        fi
        
        ((retries++))
        log_debug "Retry $retries/$MAX_RETRIES for country flag $country_code"
        sleep 1
    done
    
    log_error "Failed to fetch flag for country $country_code after $MAX_RETRIES attempts"
    return 1
}

# Get country name from REST Countries API
get_country_name_from_api() {
    local country_code="$1"
    local retries=0
    
    while [[ $retries -lt $MAX_RETRIES ]]; do
        local result
        result=$(curl -s --connect-timeout "$API_TIMEOUT" --max-time "$API_TIMEOUT" \
                     "$COUNTRY_API_BASE/alpha/$country_code?fields=name" 2>/dev/null)
        
        if [[ $? -eq 0 ]] && echo "$result" | jq . >/dev/null 2>&1; then
            local name
            name=$(echo "$result" | jq -r '.name.common // "Unknown"')
            echo "$name"
            return 0
        fi
        
        ((retries++))
        log_debug "Retry $retries/$MAX_RETRIES for country name $country_code"
        sleep 1
    done
    
    log_error "Failed to fetch name for country $country_code after $MAX_RETRIES attempts"
    return 1
}

# Get country info with caching
get_country_info() {
    local country_code="$1"
    
    # Check cache first
    if is_country_cache_valid; then
        local cached_info
        cached_info=$(jq -r ".countries.${country_code}" "$COUNTRY_CACHE" 2>/dev/null)
        if [[ "$cached_info" != "null" && "$cached_info" != "" ]]; then
            echo "$cached_info"
            return 0
        fi
    fi
    
    # Fetch from API
    local flag name
    flag=$(get_country_flag_from_api "$country_code")
    name=$(get_country_name_from_api "$country_code")
    
    if [[ $? -eq 0 ]]; then
        local info
        info=$(jq -n --arg flag "$flag" --arg name "$name" \
               '{"flag": $flag, "name": $name}')
        
        # Update cache
        update_country_cache "$country_code" "$info"
        echo "$info"
        return 0
    fi
    
    # Fallback to static data
    get_fallback_country_info "$country_code"
}

# Update country cache
update_country_cache() {
    local country_code="$1"
    local info="$2"
    
    # Create cache structure if it doesn't exist
    if [[ ! -f "$COUNTRY_CACHE" ]]; then
        echo '{"timestamp": 0, "countries": {}}' > "$COUNTRY_CACHE"
    fi
    
    # Update cache with new data
    local current_timestamp=$(date +%s)
    jq --arg country_code "$country_code" \
       --argjson info "$info" \
       --arg timestamp "$current_timestamp" \
       '.timestamp = ($timestamp | tonumber) | 
        .countries[$country_code] = $info' \
       "$COUNTRY_CACHE" > "${COUNTRY_CACHE}.tmp" && \
    mv "${COUNTRY_CACHE}.tmp" "$COUNTRY_CACHE"
}

# Fallback country info (static)
get_fallback_country_info() {
    local country_code="$1"
    
    # Read from configuration file
    local fallback_info
    fallback_info=$(jq -r ".fallback_countries.${country_code}" "$NODE_CONFIG" 2>/dev/null)
    
    if [[ "$fallback_info" != "null" && "$fallback_info" != "" ]]; then
        echo "$fallback_info"
        return 0
    fi
    
    # Ultimate fallback
    echo '{"flag": "🏳️", "name": "Unknown"}'
}

# Get country info from IP with full caching
get_country_info_from_ip() {
    local ip="$1"
    
    # Check if IP is cached
    if is_country_cache_valid; then
        local cached_country
        cached_country=$(jq -r ".ip_cache.\"${ip}\"" "$COUNTRY_CACHE" 2>/dev/null)
        if [[ "$cached_country" != "null" && "$cached_country" != "" ]]; then
            get_country_info "$cached_country"
            return 0
        fi
    fi
    
    # Fetch country code from IP
    local country_code
    country_code=$(fetch_country_from_ip "$ip")
    
    if [[ $? -eq 0 && ! -z "$country_code" ]]; then
        # Cache the IP -> country mapping
        update_ip_cache "$ip" "$country_code"
        
        # Get country info
        get_country_info "$country_code"
        return 0
    fi
    
    # Fallback
    echo '{"flag": "🏳️", "name": "Unknown"}'
}

# Update IP cache
update_ip_cache() {
    local ip="$1"
    local country_code="$2"
    
    # Create cache structure if it doesn't exist
    if [[ ! -f "$COUNTRY_CACHE" ]]; then
        echo '{"timestamp": 0, "countries": {}, "ip_cache": {}}' > "$COUNTRY_CACHE"
    fi
    
    # Update cache with new data
    local current_timestamp=$(date +%s)
    jq --arg ip "$ip" \
       --arg country_code "$country_code" \
       --arg timestamp "$current_timestamp" \
       '.timestamp = ($timestamp | tonumber) | 
        .ip_cache[$ip] = $country_code' \
       "$COUNTRY_CACHE" > "${COUNTRY_CACHE}.tmp" && \
    mv "${COUNTRY_CACHE}.tmp" "$COUNTRY_CACHE"
}

# Cleanup old cache files
cleanup_country_cache() {
    find "$CACHE_DIR" -name "*_cache.json" -mtime +7 -delete 2>/dev/null || true
    log_info "Country cache cleanup completed"
}

# Export functions for use in other scripts
if [[ "${BASH_SOURCE[0]}" != "${0}" ]]; then
    # Script is being sourced
    init_node_info || exit 1
fi
