# Bitcoin Node Monitoring Tools

A collection of shell scripts for monitoring Bitcoin node status, network fees, and market prices in real-time.

## Overview

This toolkit provides real-time monitoring of:
- Bitcoin node synchronization status
- Current Bitcoin price in multiple currencies
- Network fee estimates
- Bitcoin supply statistics
- Mempool transaction information
- Time until next halving
- Node health metrics

## Prerequisites

- Docker and Docker Compose
- A running Bitcoin Core node (configured via docker-compose.yml)
- Bash shell environment

## Installation & Configuration

1. Ensure your Bitcoin node is running:
```bash
docker-compose up -d
```

2. Make sure all scripts are executable:
```bash
chmod +x btc-* 
```

3. Configure authentication credentials in `credentials.txt` (already set up)

4. Optional: Check node configuration in the `config` directory

## Available Commands

### Main Monitoring Commands

| Command | Description |
|---------|-------------|
| `./btc-monitor` | Full monitoring dashboard that updates every 30 seconds |
| `./btc-tools all` | Comprehensive one-time snapshot of all information |
| `./btc-fees` | Current network fee estimates |
| `./btcprice` | Quick Bitcoin price check in USD |

### Advanced Options with btc-tools

The `btc-tools` script has several subcommands:

| Subcommand | Description |
|------------|-------------|
| `./btc-tools price` | Detailed price in USD, SGD, and IDR with 24h change |
| `./btc-tools node` | Node status, sync progress, peers, and mempool info |
| `./btc-tools supply` | Supply statistics, halving information, and block rewards |
| `./btc-tools health` | Quick node health check |

## Setting Up Convenient Aliases

Add these aliases to your shell configuration file (`~/.zshrc` or `~/.bashrc`):

```bash
# Bitcoin monitoring aliases
alias btcd="cd ~/bitcoin"              # Quick navigate to Bitcoin directory
alias btcm="~/bitcoin/btc-monitor"     # Full monitoring dashboard
alias btcp="~/bitcoin/btcprice"        # Quick price check
alias btcf="~/bitcoin/btc-fees"        # Network fees
alias btct="~/bitcoin/btc-tools"       # Tools with various options
```

After adding these aliases, reload your shell configuration:
```bash
source ~/.zshrc  # or source ~/.bashrc
```

## Example Usage

With aliases set up, you can use:

```bash
# Navigate to Bitcoin directory
btcd

# Launch the full monitoring dashboard
btcm

# Check current price
btcp

# Check current network fees
btcf

# Advanced tools
btct all      # Show everything
btct price    # Just price information
btct node     # Node status only
btct supply   # Supply and halving information
btct health   # Node health check
```

## Monitoring Details

### Node Status Metrics
- Sync progress percentage
- Current block height vs. network height
- Connected peers count
- Mempool transaction count and size
- Network traffic statistics

### Price Information
- Current price in USD, SGD, and IDR
- 24-hour price percentage change

### Network Fees
- Fast transaction fee (next block)
- Medium transaction fee (within 30 minutes)
- Slow transaction fee (within 1 hour)

### Supply Information
- Current Bitcoin supply
- Remaining supply
- Percent of total supply mined
- Current block reward
- Next halving block and estimated time
- Years until max supply reached

## Troubleshooting

1. If commands fail to connect to the node:
   - Verify the Docker container is running: `docker ps | grep bitcoin`
   - Check credentials in `credentials.txt`
   - Ensure proper network connectivity

2. If prices or fees are not displaying:
   - Check your internet connection
   - API endpoints might be rate-limited or temporarily unavailable

3. If aliases don't work:
   - Ensure you've reloaded your shell configuration
   - Verify the correct paths in your aliases

## File Descriptions

- `btc-monitor`: Continuous monitoring dashboard with auto-refresh
- `btc-tools`: Main utility script with multiple functions
- `btc-fees`: Network fee estimator
- `btcprice`: Simple price checker
- `btccli`: Simplified Bitcoin CLI interface
- `btc-monitor-alerts`: Monitoring with alert capabilities
- `docker-compose.yml`: Docker configuration for Bitcoin node
- `credentials.txt`: RPC credentials for node access
- `config/`: Configuration directory for Bitcoin node

## Credits

Custom Bitcoin monitoring scripts created for personal node monitoring.

