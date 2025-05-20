#!/bin/bash

# Format angka
format_number() {
    printf "%'.0f" "$1"
}

# Ambil block height
get_block_height() {
    height=$(bitcoin-cli getblockcount 2>/dev/null)
    if [ -z "$height" ]; then
        height=$(curl -s https://blockstream.info/api/blocks/tip/height)
    fi
    echo "$height"
}

# Ambil tahun block saat ini
get_block_year() {
    block_hash=$(curl -s "https://blockstream.info/api/block-height/$1")
    timestamp=$(curl -s "https://blockstream.info/api/block/$block_hash" | jq -r .timestamp)
    date -r "$timestamp" "+%Y"
}

# --- Konstanta ---
MAX_SUPPLY=21000000
HALVING_INTERVAL=210000
AVG_BLOCK_TIME_SEC=600
CURRENT_YEAR=$(date +%Y)
CURRENT_HEIGHT=$(get_block_height)

# --- Hitung total mined supply berdasarkan era ---
total_mined=0
rewards=(50 25 12.5 6.25 3.125 1.5625 0.78125 0.390625 0.1953125)
height_left=$CURRENT_HEIGHT

for (( era=0; era<${#rewards[@]}; era++ )); do
    if (( height_left >= HALVING_INTERVAL )); then
        total_mined=$(echo "$total_mined + ${HALVING_INTERVAL} * ${rewards[$era]}" | bc)
        height_left=$((height_left - HALVING_INTERVAL))
    else
        total_mined=$(echo "$total_mined + $height_left * ${rewards[$era]}" | bc)
        break
    fi
done

# --- Hitung remaining & percent ---
remaining_supply=$(echo "$MAX_SUPPLY - $total_mined" | bc)
percent_mined=$(echo "scale=8; $total_mined / $MAX_SUPPLY * 100" | bc)

# --- Halving info ---
next_halving_block=$(( ((CURRENT_HEIGHT / HALVING_INTERVAL) + 1) * HALVING_INTERVAL ))
blocks_to_halving=$((next_halving_block - CURRENT_HEIGHT))
eta_halving_days=$((blocks_to_halving * AVG_BLOCK_TIME_SEC / 86400))

# --- CETAK OUTPUT ---
echo "=== Bitcoin Supply Information ==="
echo "Current Block Height: $CURRENT_HEIGHT"
echo "Current Supply: $(format_number "$total_mined") BTC"
echo "Remaining Supply: $(format_number "$remaining_supply") BTC"
echo "Percent Mined: ${percent_mined}%"
echo "Current Block Reward: ${rewards[$era]} BTC"
echo ""
echo "Halving Information:"
echo "Next halving at block: $next_halving_block"
echo "Time until next halving: approximately $eta_halving_days days"
echo "Current block is from around year: $(get_block_year "$CURRENT_HEIGHT")"
echo "Estimated max supply reached: Year 2140 (in ~$((2140 - CURRENT_YEAR)) years)"
