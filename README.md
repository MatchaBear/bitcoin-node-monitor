# Bitcoin Node Monitoring Tools

[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](https://opensource.org/licenses/MIT)
[![Bitcoin Core](https://img.shields.io/badge/Bitcoin%20Core-24.0.1-orange.svg)](https://bitcoin.org/)
[![Docker](https://img.shields.io/badge/Docker-Required-blue.svg)](https://www.docker.com/)

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

## Quick Start Guide

1. **Initial Setup**
   ```bash
   # Clone the repository
   git clone git@github.com:MatchaBear/bitcoin-node-monitor.git
   cd bitcoin-node-monitor
   
   # Make scripts executable
   chmod +x btc-*
   
   # Create credentials file from template
   cp credentials.txt.template credentials.txt
   
   # Edit your credentials
   nano credentials.txt
   ```

2. **Configure Bitcoin Node**
   ```bash
   # Start Bitcoin node
   docker-compose up -d
   
   # Verify node is running
   docker ps | grep bitcoin
   ```

3. **Setup Monitoring**
   ```bash
   # Add aliases to your shell
   echo '# Bitcoin monitoring aliases
   alias btcd="cd ~/bitcoin"
   alias btcm="~/bitcoin/btc-monitor"     # 🔄 Enhanced continuous monitoring
   alias btcs="~/bitcoin/btcs"            # ⚡ Quick status check (NEW!)
   alias btcp="~/bitcoin/btcprice"
   alias btcf="~/bitcoin/btc-fees"
   alias btct="~/bitcoin/btc-tools"' >> ~/.zshrc
   
   # Reload shell configuration
   source ~/.zshrc
   ```

## Available Commands

### Main Monitoring Commands

| Command | Description |
|---------|-------------|
| `./btc-monitor` | **🔄 Enhanced continuous monitoring** - Full dashboard with colored output that updates every 30 seconds |
| `./btcs` | **⚡ Quick status check** - Single snapshot with colored output, perfect for quick checks |
| `./btc-tools all` | Comprehensive one-time snapshot of all information (legacy) |
| `./btc-fees` | Current network fee estimates |
| `./btcprice` | Quick Bitcoin price check in USD |

### 🎨 Enhanced Features (v2.0)

**New in this version:**
- **Colored output** with clear visual separation between titles and data
- **Emoji indicators** for quick status recognition
- **More efficient code** - single API calls instead of multiple scripts
- **Better error handling** and fallbacks
- **Two monitoring modes:**
  - `btcm` (alias for `btc-monitor`) - Continuous monitoring with auto-refresh
  - `btcs` - Quick one-shot status check

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
alias btcm="~/bitcoin/btc-monitor"     # 🔄 Enhanced continuous monitoring dashboard
alias btcs="~/bitcoin/btcs"            # ⚡ Quick status check (NEW!)
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

# 🔄 Launch the enhanced continuous monitoring dashboard (with colors!)
btcm

# ⚡ Quick status check (NEW! - single snapshot with colors)
btcs

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

### 🎨 Visual Output Example

The enhanced scripts now provide colored output with clear visual hierarchy:

```
============================================
    🟠 Bitcoin Status Dashboard           
============================================
📅 2025-06-02 02:44:16
============================================

🔧 NODE STATUS
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Status: ✅ Fully Synced
Height: 899,403 / 899,403
Peers: 11 (green color for healthy status)
Mempool: 1,393 tx (1.0 MB)

💰 MARKET DATA
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
USD: $104,752.00 ▲ 2.50% (green for positive change)
SGD: S$135,347.00
IDR: Rp.1,714,659,169

⚡ SUPPLY INFO
━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
Current Supply: 19873134 BTC (94.633973%)
Remaining: 1126866 BTC
Block Reward: 3.12500000 BTC
Next Halving: 150,597 blocks (~1045 days)
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

- `btc-monitor`: **🔄 Enhanced** continuous monitoring dashboard with colored output and auto-refresh
- `btcs`: **⚡ NEW!** Quick status check with colored output (one-shot version)
- `btc-tools`: Main utility script with multiple functions (legacy)
- `btc-fees`: Network fee estimator
- `btcprice`: Simple price checker
- `btccli`: Simplified Bitcoin CLI interface
- `btc-monitor-alerts`: Monitoring with alert capabilities
- `docker-compose.yml`: Docker configuration for Bitcoin node
- `credentials.txt`: RPC credentials for node access
- `config/`: Configuration directory for Bitcoin node

## Contributing

Contributions are welcome! Here's how you can help:

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'feat: add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

Please follow conventional commit messages:
- `feat:` for new features
- `fix:` for bug fixes
- `docs:` for documentation updates
- `chore:` for maintenance tasks

## Versioning

We use [SemVer](http://semver.org/) for versioning. For the versions available, see the [tags on this repository](https://github.com/MatchaBear/bitcoin-node-monitor/tags).

## Current Version: 2.0.0

### 🚀 Version 2.0.0 Changelog
- ✨ **Enhanced visual output** with colors and emojis
- ⚡ **New `btcs` command** for quick status checks
- 🔧 **Improved efficiency** - consolidated API calls
- 🎨 **Better UI/UX** with clear visual hierarchy
- 🛠️ **Better error handling** and fallbacks
- 📊 **More informative displays** with status indicators

## Credits

Custom Bitcoin monitoring scripts created for personal node monitoring.

