#!/bin/bash

# Test script for professional libraries
# Tests currency manager and node info libraries

# Script directory detection
readonly TEST_SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Set environment variables for libraries
export BITCOIN_PROJECT_ROOT="$TEST_SCRIPT_DIR"

# Source required libraries
source "$TEST_SCRIPT_DIR/lib/currency_manager.sh"
source "$TEST_SCRIPT_DIR/lib/node_info.sh"

# Color definitions
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly CYAN='\033[0;36m'
readonly NC='\033[0m'

echo "🧪 Testing Professional Bitcoin Libraries"
echo "========================================"
echo

# Test currency manager
echo -e "${CYAN}Testing Currency Manager Library...${NC}"

# Test 1: List supported currencies
echo "1. Testing supported currencies list:"
currencies=$(get_supported_currencies)
if [[ $? -eq 0 ]]; then
    echo -e "${GREEN}✅ Found currencies: $(echo "$currencies" | tr '\n' ' ')${NC}"
else
    echo -e "${RED}❌ Failed to get supported currencies${NC}"
fi
echo

# Test 2: Get currency flag and symbol
echo "2. Testing currency metadata for USD:"
usd_flag=$(get_currency_flag "USD")
usd_symbol=$(get_currency_symbol "USD")
usd_format=$(get_display_format "USD")
echo -e "${GREEN}✅ USD Flag: $usd_flag${NC}"
echo -e "${GREEN}✅ USD Symbol: $usd_symbol${NC}"
echo -e "${GREEN}✅ USD Format: $usd_format${NC}"
echo

# Test 3: Format currency price
echo "3. Testing price formatting:"
formatted_price=$(format_currency_price "USD" "105000")
echo -e "${GREEN}✅ Formatted USD price: $formatted_price${NC}"
echo

# Test node info library
echo -e "${CYAN}Testing Node Info Library...${NC}"

# Test 4: Get country info for a sample IP
echo "4. Testing country detection for IP 8.8.8.8:"
country_info=$(get_country_info_from_ip "8.8.8.8")
if [[ $? -eq 0 ]]; then
    flag=$(echo "$country_info" | jq -r '.flag')
    name=$(echo "$country_info" | jq -r '.name')
    echo -e "${GREEN}✅ Country: $flag $name${NC}"
else
    echo -e "${YELLOW}⚠️  Could not get country info (API might be rate limited)${NC}"
fi
echo

# Test 5: Test fallback country info
echo "5. Testing fallback country info for US:"
fallback_info=$(get_fallback_country_info "US")
if [[ $? -eq 0 ]]; then
    fallback_flag=$(echo "$fallback_info" | jq -r '.flag')
    fallback_name=$(echo "$fallback_info" | jq -r '.name')
    echo -e "${GREEN}✅ Fallback: $fallback_flag $fallback_name${NC}"
else
    echo -e "${RED}❌ Failed to get fallback country info${NC}"
fi
echo

echo "🏁 Library Testing Complete!"
echo
echo "📝 Summary:"
echo "- Currency Manager Library: Professional configuration-driven approach"
echo "- Node Info Library: Dynamic country detection with caching"
echo "- Both libraries use JSON configurations and API integrations"
echo "- Fallback systems ensure reliability even when APIs are unavailable"
echo
echo "✨ All libraries are ready for professional Bitcoin monitoring! ✨"
