#!/bin/bash

# Node sync status
current_height=360101          # Updated to latest observed height
historical_year=2014           # Year of blocks being processed
current_year=2025             # Actual current year
current_month="May"           # Current month

# Constants
halving_interval=210000
blocks_per_day=144
blocks_per_year=52560
max_supply=21000000
target_height=897286          # Updated to latest target

# Network performance metrics
sync_speed=2400              # Observed blocks per minute
network_throughput=13137     # Peak download in MB
peer_connections=10          # Connected peers

# Calculate sync statistics
sync_remaining=$((target_height - current_height))
sync_percent=$(echo "scale=2; $current_height * 100 / $target_height" | bc)

# Calculate current era and reward
current_era=$((current_height / halving_interval))
current_reward=$(echo "scale=8; 50 / (2 ^ $current_era)" | bc)

# Calculate next halving
next_halving=$((((current_height / halving_interval) + 1) * halving_interval))
blocks_until_halving=$((next_halving - current_height))
days_until_halving=$((blocks_until_halving / blocks_per_day))

# Calculate supply
supply=0
for ((i=0; i<current_era; i++)); do
    era_reward=$(echo "scale=8; 50 / (2 ^ $i)" | bc)
    era_supply=$(echo "$era_reward * $halving_interval" | bc)
    supply=$(echo "$supply + $era_supply" | bc)
done

blocks_in_current_era=$((current_height - (current_era * halving_interval)))
current_era_supply=$(echo "scale=8; $current_reward * $blocks_in_current_era" | bc)
supply=$(echo "$supply + $current_era_supply" | bc)

# Round supply to whole numbers
supply=$(echo "($supply+0.5)/1" | bc)
remaining=$((max_supply - supply))
percent_mined=$(echo "scale=2; $supply * 100 / $max_supply" | bc)

# Calculate detailed era statistics
blocks_this_era=$blocks_in_current_era
blocks_until_era_end=$((next_halving - current_height))
coins_this_era=$(echo "scale=0; $current_reward * $blocks_this_era" | bc)
coins_remaining_era=$(echo "scale=0; $current_reward * $blocks_until_era_end" | bc)
total_era_coins=$(echo "scale=0; $current_reward * $halving_interval" | bc)
era_progress=$(echo "scale=2; $blocks_this_era * 100 / $halving_interval" | bc)

echo "===== Bitcoin Node Status and Supply Analysis ====="
echo "Current Date: ${current_month} ${current_year}"
echo ""
echo "Sync Status:"
echo "  Processing blocks from: ${historical_year}"
echo "  Current height: $(printf "%'d" $current_height)"
echo "  Target height: $(printf "%'d" $target_height)"
echo "  Progress: ${sync_percent}%"
echo "  Blocks remaining: $(printf "%'d" $sync_remaining)"
echo ""
echo "Network Performance Metrics:"
echo "  Sync speed: ~$sync_speed blocks/minute"
echo "  Network throughput: $network_throughput MB downloaded"
echo "  Connected peers: $peer_connections"
echo "  Estimated completion: ~$(echo "scale=1; ($target_height - $current_height) / ($sync_speed * 1440)" | bc) days"
echo ""
echo "Supply Information:"
echo "  Current supply: $(printf "%'d" $supply) BTC"
echo "  Remaining until max: $(printf "%'d" $remaining) BTC"
echo "  Percentage mined: ${percent_mined}%"
echo "  Block reward: $current_reward BTC"
echo ""
echo "Current Era (Era $current_era) Details:"
echo "  Era progress: ${era_progress}% (${blocks_this_era} of ${halving_interval} blocks)"
echo "  Current block subsidy: ${current_reward} BTC"
echo "  Coins mined this era: ${coins_this_era} BTC"
echo "  Coins remaining in era: ${coins_remaining_era} BTC"
echo "  Total possible era coins: ${total_era_coins} BTC"
echo "  Blocks until era end: ${blocks_until_era_end}"
echo ""
echo "Historical Era Summary:"

# Show historical eras
for ((i=0; i<current_era; i++)); do
    era_reward=$(echo "scale=8; 50 / (2 ^ $i)" | bc)
    era_total=$(echo "scale=0; $era_reward * $halving_interval" | bc)
    start_block=$((i * halving_interval))
    end_block=$(((i + 1) * halving_interval - 1))
    
    echo "  Era $i:"
    echo "    Blocks: ${start_block} to ${end_block}"
    echo "    Reward: ${era_reward} BTC"
    echo "    Total coins: ${era_total} BTC"
    echo ""
done
echo ""
echo "Next Halving:"
echo "  At block: $(printf "%'d" $next_halving)"
echo "  Blocks remaining: $(printf "%'d" $blocks_until_halving)"
echo "  Days until next halving: $days_until_halving"
echo ""
echo "Projected Schedule (from 2025):"

# Show next 5 halvings
network_height=$target_height
network_era=$((network_height / halving_interval))
next_network_halving=$((((network_height / halving_interval) + 1) * halving_interval))

for ((i=0; i<5; i++)); do
    halving_block=$((next_network_halving + (i * halving_interval)))
    era=$((network_era + i + 1))
    reward=$(echo "scale=8; 50 / (2 ^ $era)" | bc)
    blocks_to_halving=$((halving_block - network_height))
    years_to_halving=$(echo "scale=1; $blocks_to_halving / $blocks_per_year" | bc)
    target_year=$(echo "scale=0; $current_year + $years_to_halving" | bc)
    
    echo "Halving $((i+1)):"
    echo "  Block: $(printf "%'d" $halving_block)"
    echo "  Reward: $reward BTC"
    echo "  Expected: ~$target_year"
    echo ""
done

echo "Note: Processing historical blocks from ${historical_year}"
echo "      Current year is ${current_year}"
echo "      Final Bitcoin will be mined in 2140 (115 years from now)"

