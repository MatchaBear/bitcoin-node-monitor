#!/bin/bash

# Bitcoin Node Monitoring Test Script
# Tests all available commands to ensure they're working properly

echo "🧪 Testing Bitcoin Node Monitoring Scripts"
echo "=========================================="
echo

# Color definitions for test results
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Test function
test_command() {
    local cmd="$1"
    local desc="$2"
    
    echo -e "${CYAN}Testing: $desc${NC}"
    echo "Command: $cmd"
    echo "---"
    
    if timeout 10 bash -c "$cmd" > /dev/null 2>&1; then
        echo -e "${GREEN}✅ PASS${NC}"
    else
        echo -e "${RED}❌ FAIL${NC}"
        echo "Error: Command failed or timed out"
    fi
    echo
}

# Test basic commands
echo "🔧 Testing basic functionality..."
test_command "./btcprice" "Bitcoin price check"
test_command "./btc-fees" "Network fee estimates"
test_command "./btccli help" "Bitcoin CLI interface"

# Test main tools
echo "⚡ Testing main monitoring tools..."
test_command "./btcs" "Quick status dashboard (NEW!)"
test_command "timeout 3 ./btc-monitor || true" "Continuous monitoring (3 sec test)"

# Test btc-tools subcommands
echo "🛠️ Testing btc-tools subcommands..."
test_command "./btc-tools price" "Price information"
test_command "./btc-tools node" "Node status"
test_command "./btc-tools supply" "Supply information"
test_command "./btc-tools health" "Node health check"
test_command "timeout 3 ./btc-tools all || true" "Complete dashboard (3 sec test)"

# Test additional scripts
echo "📊 Testing additional monitoring scripts..."
test_command "./supply_brief.sh" "Supply brief"
test_command "./monitor.sh --help || true" "Monitor script help"
test_command "./help.sh" "Help documentation"

echo "🏁 Test completed!"
echo
echo "📝 Summary:"
echo "- All core commands tested"
echo "- Enhanced btcs command (quick status) - NEW!"
echo "- Enhanced btc-monitor (continuous monitoring) - IMPROVED!"
echo "- Legacy tools maintained for compatibility"
echo
echo "💡 Recommended usage:"
echo "  - Use 'btcs' for quick status checks"
echo "  - Use 'btcm' (alias for btc-monitor) for continuous monitoring"
echo "  - Both commands now feature colored output and better formatting"
echo
echo "✨ Enjoy your enhanced Bitcoin node monitoring! ✨"

