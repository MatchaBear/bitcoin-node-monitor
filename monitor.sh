#!/bin/bash

echo "Bitcoin Node Monitor (10-second intervals)"
echo "Press Ctrl+C to stop monitoring"
echo "----------------------------------------"

previous_height=0
start_time=$(date +%s)

# Initialize all-time high tracking
ath_blocks_per_minute=0
ath_received_mb=0
ath_peers=0
ath_progress=0

while true; do
    clear
    echo "Bitcoin Node Monitor (10-second intervals)"
    echo "Press Ctrl+C to stop monitoring"
    echo "----------------------------------------"
    
    # Get current status
    node_status=$(./btc-tools node)
    current_height=$(echo "$node_status" | grep "Block Height" | awk -F'[ /]' '{print $3}' | tr -d ',')
    target_height=$(echo "$node_status" | grep "Block Height" | awk -F'[ /]' '{print $5}' | tr -d ',')
    progress=$(echo "$node_status" | grep "Sync Progress" | awk '{print $3}' | tr -d '%')
    received_mb=$(echo "$node_status" | grep "Total Received" | awk '{print $3}')
    current_peers=$(echo "$node_status" | grep "Connected Peers" | awk '{print $3}')
    
    # Update ATH values
    if (( $(echo "$progress > $ath_progress" | bc -l) )); then
        ath_progress=$progress
    fi
    
    if [ "$current_peers" -gt "$ath_peers" ]; then
        ath_peers=$current_peers
    fi
    
    if (( $(echo "$received_mb > $ath_received_mb" | bc -l) )); then
        ath_received_mb=$received_mb
    fi
    
    # Calculate blocks processed since last check
    if [ $previous_height -ne 0 ]; then
        blocks_processed=$((current_height - previous_height))
        blocks_per_minute=$((blocks_processed * 6))
        blocks_remaining=$((target_height - current_height))
        
        # Update ATH blocks per minute
        if [ $blocks_per_minute -gt $ath_blocks_per_minute ]; then
            ath_blocks_per_minute=$blocks_per_minute
        fi
        
        # Estimate completion time
        if [ $blocks_per_minute -gt 0 ]; then
            minutes_remaining=$((blocks_remaining / blocks_per_minute))
            hours_remaining=$((minutes_remaining / 60))
            days_remaining=$(echo "scale=1; $hours_remaining / 24" | bc)
            
            echo "Current Performance:"
            echo "  Blocks processed (10s): $blocks_processed"
            echo "  Current speed: ~$blocks_per_minute blocks/minute"
            echo "  Estimated completion: ~$days_remaining days"
            echo ""
            echo "All-Time High Stats:"
            echo "  Fastest sync: $ath_blocks_per_minute blocks/minute"
            echo "  Highest progress: ${ath_progress}%"
            echo "  Most peers: $ath_peers"
            echo "  Peak download: $ath_received_mb MB"
            echo ""
        else
            echo "Waiting for block progress..."
            echo ""
        fi
    fi
    
    # Display current status
    echo "$node_status"
    
    # Calculate running time
    current_time=$(date +%s)
    runtime=$((current_time - start_time))
    hours=$((runtime / 3600))
    minutes=$(( (runtime % 3600) / 60 ))
    seconds=$((runtime % 60))
    echo ""
    echo "Monitor running for: ${hours}h ${minutes}m ${seconds}s"
    
    previous_height=$current_height
    sleep 10
done

