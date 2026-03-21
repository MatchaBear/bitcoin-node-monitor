#!/bin/bash

# Professional Currency Manager Library
# Handles dynamic currency data, flags, and symbols via APIs
# Author: Bitcoin Node Monitor Project
# Version: 3.1.0

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
readonly CURRENCIES_CONFIG="$CONFIG_DIR/currencies.json"
readonly CURRENCY_CACHE="$CACHE_DIR/currency_cache.json"

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

# Initialize configuration
init_currency_manager() {
    if [[ ! -f "$CURRENCIES_CONFIG" ]]; then
        log_error "Currency configuration not found: $CURRENCIES_CONFIG"
        return 1
    fi
    
    # Load API configuration
    COUNTRY_API_BASE=$(jq -r '.api_config.country_api' "$CURRENCIES_CONFIG")
    API_TIMEOUT=$(jq -r '.api_config.timeout' "$CURRENCIES_CONFIG")
    MAX_RETRIES=$(jq -r '.api_config.max_retries' "$CURRENCIES_CONFIG")
    CACHE_DURATION=$(jq -r '.api_config.cache_duration' "$CURRENCIES_CONFIG")
    
    log_debug "Currency manager initialized with API: $COUNTRY_API_BASE"
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
is_cache_valid() {
    [[ -f "$CURRENCY_CACHE" ]] || return 1
    
    local cache_timestamp
    cache_timestamp=$(jq -r '.timestamp // 0' "$CURRENCY_CACHE" 2>/dev/null)
    local current_timestamp=$(date +%s)
    local cache_age=$((current_timestamp - cache_timestamp))
    
    [[ $cache_age -lt $CACHE_DURATION ]]
}

# Fetch country data from REST Countries API
fetch_country_data() {
    local country_code="$1"
    local retries=0
    
    while [[ $retries -lt $MAX_RETRIES ]]; do
        local result
        result=$(curl -s --connect-timeout "$API_TIMEOUT" --max-time "$API_TIMEOUT" \
                     "$COUNTRY_API_BASE/alpha/$country_code?fields=flag,currencies" 2>/dev/null)
        
        if [[ $? -eq 0 ]] && echo "$result" | jq . >/dev/null 2>&1; then
            echo "$result"
            return 0
        fi
        
        ((retries++))
        log_debug "Retry $retries/$MAX_RETRIES for country $country_code"
        sleep 1
    done
    
    log_error "Failed to fetch country data for $country_code after $MAX_RETRIES attempts"
    return 1
}

# Get supported currencies list
get_supported_currencies() {
    jq -r '.supported_currencies | keys[]' "$CURRENCIES_CONFIG" | sort
}

# Get currency configuration
get_currency_config() {
    local currency="$1"
    jq -r --arg currency "$currency" '.supported_currencies[$currency]' "$CURRENCIES_CONFIG"
}

# Get currency flag (with caching)
get_currency_flag() {
    local currency="$1"
    
    # Check cache first
    if is_cache_valid; then
        local cached_flag
        cached_flag=$(jq -r --arg currency "$currency" '.currencies[$currency].flag // null' "$CURRENCY_CACHE" 2>/dev/null)
        if [[ "$cached_flag" != "null" && "$cached_flag" != "" ]]; then
            echo "$cached_flag"
            return 0
        fi
    fi
    
    # Fetch from API
    local country_code
    country_code=$(jq -r --arg currency "$currency" '.supported_currencies[$currency].country_code' "$CURRENCIES_CONFIG")
    
    if [[ "$country_code" == "null" ]]; then
        echo "🏳️"
        return 1
    fi
    
    local country_data
    country_data=$(fetch_country_data "$country_code")
    
    if [[ $? -eq 0 ]]; then
        local flag
        flag=$(echo "$country_data" | jq -r '.flag // "🏳️"')
        
        # Update cache
        update_currency_cache "$currency" "flag" "$flag"
        echo "$flag"
        return 0
    fi
    
    # Fallback
    echo "🏳️"
    return 1
}

# Get currency symbol (with caching)
get_currency_symbol() {
    local currency="$1"
    
    # Check cache first
    if is_cache_valid; then
        local cached_symbol
        cached_symbol=$(jq -r --arg currency "$currency" '.currencies[$currency].symbol // null' "$CURRENCY_CACHE" 2>/dev/null)
        if [[ "$cached_symbol" != "null" && "$cached_symbol" != "" ]]; then
            echo "$cached_symbol"
            return 0
        fi
    fi
    
    # Fetch from API
    local country_code
    country_code=$(jq -r --arg currency "$currency" '.supported_currencies[$currency].country_code' "$CURRENCIES_CONFIG")
    
    if [[ "$country_code" == "null" ]]; then
        echo "$currency"
        return 1
    fi
    
    local country_data
    country_data=$(fetch_country_data "$country_code")
    
    if [[ $? -eq 0 ]]; then
        local symbol
        symbol=$(echo "$country_data" | jq -r ".currencies.${currency}.symbol // \"${currency}\"")
        
        # Update cache
        update_currency_cache "$currency" "symbol" "$symbol"
        echo "$symbol"
        return 0
    fi
    
    # Fallback to hardcoded symbols
    case "$currency" in
        "USD") echo "\$" ;;
        "EUR") echo "€" ;;
        "GBP") echo "£" ;;
        "SGD") echo "S\$" ;;
        "CHF") echo "CHF" ;;
        "JPY") echo "¥" ;;
        "KRW") echo "₩" ;;
        "IDR") echo "IDR" ;;
        *) echo "$currency" ;;
    esac
}

# Update currency cache
update_currency_cache() {
    local currency="$1"
    local field="$2"
    local value="$3"
    
    # Create cache structure if it doesn't exist
    if [[ ! -f "$CURRENCY_CACHE" ]]; then
        echo '{"timestamp": 0, "currencies": {}}' > "$CURRENCY_CACHE"
    fi
    
    # Update cache with new data
    local current_timestamp=$(date +%s)
    jq --arg currency "$currency" \
       --arg field "$field" \
       --arg value "$value" \
       --arg timestamp "$current_timestamp" \
       '.timestamp = ($timestamp | tonumber) | 
        .currencies[$currency][$field] = $value' \
       "$CURRENCY_CACHE" > "${CURRENCY_CACHE}.tmp" && \
    mv "${CURRENCY_CACHE}.tmp" "$CURRENCY_CACHE"
}

# Get exchange rate for currency
get_exchange_rate() {
    local currency="$1"
    jq -r --arg currency "$currency" '.supported_currencies[$currency].exchange_rate_base' "$CURRENCIES_CONFIG"
}

# Get display format for currency
get_display_format() {
    local currency="$1"
    jq -r --arg currency "$currency" '.supported_currencies[$currency].display_format' "$CURRENCIES_CONFIG"
}

# Get ATH fallback value
get_ath_fallback() {
    local currency="$1"
    jq -r --arg currency "$currency" '.supported_currencies[$currency].ath_fallback' "$CURRENCIES_CONFIG"
}

# Format price with currency symbol and proper formatting
format_currency_price() {
    local currency="$1"
    local price="$2"
    local symbol
    local format
    
    symbol=$(get_currency_symbol "$currency")
    format=$(get_display_format "$currency")
    
    printf "${symbol}${format}" "$price"
}

# Get all currency data at once (optimized for batch operations)
get_all_currency_data() {
    local currencies=()
    mapfile -t currencies < <(get_supported_currencies)
    
    local output="{}"
    for currency in "${currencies[@]}"; do
        local flag symbol exchange_rate format ath_fallback
        flag=$(get_currency_flag "$currency")
        symbol=$(get_currency_symbol "$currency")
        exchange_rate=$(get_exchange_rate "$currency")
        format=$(get_display_format "$currency")
        ath_fallback=$(get_ath_fallback "$currency")
        
        output=$(echo "$output" | jq --arg currency "$currency" \
                                     --arg flag "$flag" \
                                     --arg symbol "$symbol" \
                                     --arg exchange_rate "$exchange_rate" \
                                     --arg format "$format" \
                                     --arg ath_fallback "$ath_fallback" \
                 '.[$currency] = {
                   "flag": $flag,
                   "symbol": $symbol,
                   "exchange_rate": ($exchange_rate | tonumber),
                   "format": $format,
                   "ath_fallback": ($ath_fallback | tonumber)
                 }')
    done
    
    echo "$output"
}

# Cleanup old cache files
cleanup_cache() {
    find "$CACHE_DIR" -name "*.json" -mtime +7 -delete 2>/dev/null || true
    log_info "Cache cleanup completed"
}

# Export functions for use in other scripts
if [[ "${BASH_SOURCE[0]}" != "${0}" ]]; then
    # Script is being sourced
    init_currency_manager || exit 1
fi
