# Bitcoin Node Monitoring Tools (Pruned Mode)

[![Bitcoin Core](https://img.shields.io/badge/Bitcoin%20Core-Pruned-orange.svg)](https://bitcoin.org/)
[![Docker](https://img.shields.io/badge/Docker-Required-blue.svg)](https://www.docker.com/)

A real-time Bitcoin node monitoring dashboard running on Docker in pruned mode (~20GB disk).
Type `btcm` and get a full-screen dashboard that auto-refreshes every 30 seconds.

## Quick Start

```bash
# First-time setup
cp .env.example .env
# Then edit .env with your RPC credentials

# Start monitoring (if Docker + node are already running)
btcm

# Stop monitoring
Ctrl+C
```

## After Reboot

Docker Desktop is set to auto-launch on login. The bitcoin-node container has
`restart: unless-stopped`, so it starts automatically. Just wait ~2 minutes and run `btcm`.

If Docker isn't running:
```bash
open -a Docker                          # Start Docker from CLI
# Wait ~60 seconds...
docker ps | grep bitcoin-node          # Verify node is up
btcm                                    # Start monitoring
```

## Command Map

| Command | Purpose |
|---------|---------|
| `btcm` | Main full-screen dashboard with 30-second auto-refresh |
| `btc` | Friendly launcher for test, peers, status, and monitor flows |
| `btc test` | Validate helper libraries and supporting files |
| `btc peers` | Show connected peers with country lookups |
| `btc status` | Quick environment and dependency check |
| `btc monitor` | Start the monitor via the launcher flow |
| `btccli` | Run Bitcoin Core RPC commands inside the Docker node |
| `btc-fees` | Fee-only snapshot |
| `btcprice` | Price-only snapshot |
| `btc-tools` | One-shot utility entrypoint for node, price, supply, and health views |
| `test-all.sh` | Broader script test pass |
| `test-libraries.sh` | Helper-library test runner |
| `install-shortcuts.sh` | Install convenient shell aliases and PATH shortcuts |

## Dashboard Sections

### NODE STATUS
Your node's health: sync state, block height, connected peers with country flags, and mempool size.

### FEE ESTIMATES
Real-time fee tiers from [mempool.space](https://mempool.space) + your local node's estimates.
Shows global vs. local mempool comparison.

### MARKET DATA
BTC price in 8 currencies (USD, EUR, GBP, SGD, CHF, JPY, KRW, IDR) with 24h change
and 30-second delta tracking. Multi-provider failover: CryptoCompare → CoinGecko → Binance.

### ALL-TIME HIGH (ATH)
Highest price ever recorded per currency with dates. Persistently cached so you never
lose track even if APIs are down.

### SUPPLY INFO
Mined supply, remaining BTC, current block reward, and next halving countdown.

### NETWORK & NODE STATS
Hashrate (EH/s), difficulty, next difficulty adjustment, node uptime, bandwidth usage,
and disk usage with prune limit warnings.

---

## Bitcoin Glossary for Beginners

If you're new to Bitcoin, here's what every term on the dashboard means.

### The Basics

| Term | What It Means | Real-World Analogy |
|------|---------------|-------------------|
| **Node** | A computer running Bitcoin software that stores and validates the blockchain | Your own copy of the bank's ledger. No middleman needed. |
| **Blockchain** | A chain of blocks, each containing transactions, going back to 2009 | An accounting book where each page (block) is sealed and linked to the previous one |
| **Block** | A batch of ~2,000-3,000 transactions, added roughly every 10 minutes | One page in the accounting book |
| **Block Height** | The total number of blocks since Bitcoin started (block #0 in Jan 2009) | Page number in the book. Height 940,000 = the 940,000th page |
| **Synced** | Your node has downloaded and verified all blocks up to the latest one | Your copy of the book is up to date |

### Network & Peers

| Term | What It Means | Real-World Analogy |
|------|---------------|-------------------|
| **Peers** | Other Bitcoin nodes your computer is connected to | Neighbors you exchange notes with to stay in sync |
| **Inbound/Outbound** | Outbound = you connected to them. Inbound = they connected to you | You called them vs. they called you |
| **Latency (ms)** | How long it takes to ping a peer, in milliseconds | Like the delay on a phone call — lower is better |

### Mempool & Transactions

| Term | What It Means | Real-World Analogy |
|------|---------------|-------------------|
| **Mempool** | The "memory pool" — all unconfirmed transactions waiting to be included in a block | A waiting room at the airport. Transactions sit here until a miner picks them up |
| **tx** | Short for "transaction" | A single Bitcoin payment from one address to another |
| **Confirmed** | A transaction that has been included in a block | Your package was picked up by the delivery truck |
| **Unconfirmed** | A transaction still in the mempool, not yet in a block | Still waiting at the post office |

### Fees & Virtual Bytes

| Term | What It Means | Real-World Analogy |
|------|---------------|-------------------|
| **Fee** | The amount you pay miners to include your transaction in a block | A tip to the delivery driver. Bigger tip = faster delivery |
| **Satoshi (sat)** | The smallest unit of Bitcoin. 1 BTC = 100,000,000 sats | Like cents to dollars, but there are 100 million sats in 1 BTC |
| **Byte (B)** | A unit of data size. A typical transaction is ~200-400 bytes | The "weight" of your envelope |
| **Virtual Byte (vB)** | A weighted measurement of transaction size introduced by SegWit (2017 upgrade). Signature data ("witness") gets a 75% discount, so SegWit transactions are cheaper | Imagine shipping charges where carry-on luggage is full price but checked bags get 75% off. Same total stuff, cheaper overall |
| **Weight Unit (WU)** | The raw measurement. Non-witness data = 4 WU per byte, witness data = 1 WU per byte. vB = total WU / 4 | The underlying formula behind the luggage discount |
| **sat/vB** | Fee rate — satoshis per virtual byte. This is what miners look at to prioritize transactions | Price per gram for express shipping. Higher rate = you cut the queue |
| **MvB** | Mega virtual bytes (millions of vB). Used to measure total mempool size. A block fits ~4 MvB, so if the mempool is 28 MvB, that's ~7 blocks worth of waiting transactions | The total weight of all packages in the post office |

**Example**: Your transaction is 140 vB. Fee rate is 5 sat/vB.
You pay: 140 × 5 = 700 sats = 0.000007 BTC ≈ $0.49 (at $70,000/BTC).

### Mining & Security

| Term | What It Means | Real-World Analogy |
|------|---------------|-------------------|
| **Mining** | Using computers to solve a math puzzle. The winner gets to add the next block and earns the block reward + fees | A global lottery every ~10 minutes. The winner writes the next page |
| **Hashrate** | Total computing power of all miners worldwide. Measured in EH/s (exahashes per second = quintillions of guesses per second) | The combined brainpower of every miner on Earth. Higher = more secure |
| **Difficulty** | How hard the math puzzle is. Adjusts every 2,016 blocks (~2 weeks) to keep block time at ~10 minutes | A thermostat for mining speed. Too many miners? Puzzle gets harder. Miners leave? Gets easier |
| **Difficulty Adjustment** | The automatic recalibration every 2,016 blocks | The thermostat checking and adjusting itself |
| **Block Reward** | New BTC created with each block, awarded to the miner who solved it. Currently 3.125 BTC | The miner's paycheck for writing the next page |

### Supply & Halving

| Term | What It Means | Real-World Analogy |
|------|---------------|-------------------|
| **Max Supply** | 21,000,000 BTC — the hard cap coded into Bitcoin. No one can change it | Like gold — there's a finite amount on Earth |
| **Current Supply** | How many BTC have been mined so far (~20M of 21M) | How much gold has been dug up so far |
| **Halving** | Every 210,000 blocks (~4 years), the block reward is cut in half. Started at 50 BTC (2009), now 3.125 BTC (2024). Next: 1.5625 BTC (~2028) | Your paycheck getting cut in half every 4 years. Fewer new coins = more scarcity = historically drives price up |
| **Remaining** | BTC that haven't been mined yet. The last BTC will be mined around the year 2140 | Gold still underground, waiting to be found |

### Price & Market

| Term | What It Means | Real-World Analogy |
|------|---------------|-------------------|
| **ATH (All-Time High)** | The highest price Bitcoin has ever reached in a given currency | A world record. Once broken, a new record is set |
| **24h Change (%)** | How much the price moved in the last 24 hours | Like "the stock is up 2% today" |
| **Δ~30s** | Price change since the last dashboard refresh (30 seconds ago) | The micro-movement, like watching a stock ticker update live |
| **Provider** | The exchange or API that supplied the price data (CryptoCompare, CoinGecko, Binance) | Different price sources, like checking multiple stores for the same item |
| **FX Rate** | Foreign exchange rate used to convert USD prices to other currencies | The currency conversion rate at the airport money changer |

### Pruned Mode & Disk

| Term | What It Means | Real-World Analogy |
|------|---------------|-------------------|
| **Pruned Node** | A full node that validates everything but deletes old block data to save disk space. Keeps only the most recent ~10GB of blocks | A library that reads and verifies every newspaper but only keeps the last 6 months on the shelf |
| **Full Node (unpruned)** | Keeps the entire blockchain history (~600GB+). Needed if you want to look up any historical transaction | A library that keeps every newspaper ever published |
| **Chainstate** | The UTXO set — a database of who owns what Bitcoin right now. This is never pruned | The current balance sheet. Even if you throw away old receipts, you still know who has what |
| **UTXO** | Unspent Transaction Output — the fundamental unit of Bitcoin ownership. Your "balance" is actually a collection of UTXOs | Individual bills in your wallet. You don't have "$100" — you have a $50 + two $20s + a $10 |
| **Prune Limit** | How much block data to keep before deleting old blocks (set to 10,000 MB in your config) | The shelf space allocated for newspapers |

### Your Node Specifically

| Term | What It Means |
|------|---------------|
| **bitcoin-node** | Your Docker container running Bitcoin Core |
| **RPC** | Remote Procedure Call — how the monitoring script talks to Bitcoin Core (like an internal API) |
| **docker-compose.yml** | Configuration file that defines how your Bitcoin container runs |
| **.env** | File containing your RPC credentials (username/password). Not committed to git |
| **btcm** | Shell alias for `~/bitcoin/btc-monitor` — your monitoring dashboard |

---

## Architecture

```
┌──────────────────────────────────────────────────────┐
│  btcm (btc-monitor script)                           │
│  ┌─────────────┐  ┌──────────────┐  ┌─────────────┐ │
│  │ Node Status  │  │ Fee Estimates │  │ Market Data │ │
│  │ (local RPC)  │  │ (mempool.space│  │ (CryptoComp │ │
│  │              │  │  + local RPC) │  │  CoinGecko  │ │
│  │              │  │              │  │  Binance)   │ │
│  └──────┬───────┘  └──────┬───────┘  └──────┬──────┘ │
│         │                 │                  │        │
│  ┌──────┴─────────────────┴──────────────────┴──────┐ │
│  │            FX: Frankfurter API                    │ │
│  │            ATH: CoinGecko + local cache           │ │
│  │            Geo/IP: ipinfo.io + ip-api + ipwho.is  │ │
│  └───────────────────────┬──────────────────────────┘ │
└──────────────────────────┼───────────────────────────┘
                           │
              ┌────────────┴────────────┐
              │  Docker: bitcoin-node    │
              │  Bitcoin Core (pruned)   │
              │  RPC port 8332          │
              │  P2P port 8333          │
              └─────────────────────────┘
```

## API Sources (all free)

| API | Purpose | Rate Limit |
|-----|---------|------------|
| [CryptoCompare](https://min-api.cryptocompare.com) | BTC price in 8 currencies (primary) | 100K calls/month free |
| [CoinGecko](https://api.coingecko.com) | ATH data with dates | Rate-limited, used sparingly |
| [Binance](https://api.binance.com) | BTC/USDT fallback | Unlimited, no key |
| [Frankfurter](https://api.frankfurter.app) | Live FX rates from ECB | Unlimited, no key |
| [mempool.space](https://mempool.space/api) | Fee estimates, global mempool | Unlimited, no key |
| [ipinfo.io](https://ipinfo.io) | Peer geolocation | Free tier with token |
| [ip-api.com](http://ip-api.com) | Geo fallback | Free, no key |
| [ipwho.is](https://ipwho.is) | Geo fallback | Free, no key |
| Local Bitcoin RPC | getblockchaininfo, getmininginfo, estimatesmartfee, getnettotals, uptime | Local, unlimited |

## Supporting Docs

| File | Purpose |
|------|---------|
| `README.md` | Main project guide and dashboard reference |
| `SIMPLE_GUIDE.md` | Shorter onboarding guide for day-to-day use |
| `MODERNIZATION_SUMMARY.md` | Upgrade notes and architecture evolution |
| `VERIFICATION_AND_ROLLBACK.md` | Validation and rollback procedures |

## File Map

```
~/bitcoin/
├── .env                     # Local RPC credentials (git-ignored)
├── .env.example             # Example RPC environment file
├── docker-compose.yml       # Docker container config
├── btc                      # Friendly launcher command
├── btc-monitor              # Main monitoring script (btcm alias)
├── btc-tools                # One-shot utility command collection
├── btc-fees                 # Fee snapshot helper
├── btcprice                 # Price snapshot helper
├── btccli                   # Bitcoin Core CLI wrapper
├── peers.sh                 # Peer inspection helper
├── install-shortcuts.sh     # Shell shortcut installer
├── SIMPLE_GUIDE.md          # Short onboarding guide
├── MODERNIZATION_SUMMARY.md # Upgrade / refactor summary
├── VERIFICATION_AND_ROLLBACK.md # Validation and rollback notes
├── btc_last_prices.txt      # Last known prices (auto-updated)
├── peer_country_cache.txt   # Peer country lookup cache
├── cache/
│   ├── fx_rates.json        # Frankfurter FX rates (10-min TTL)
│   └── ath_cache.json       # Persistent ATH cache
├── config/
│   ├── bitcoin.conf         # Reference config (actual runtime config is in Docker)
│   ├── currencies.json      # Currency metadata used by helpers
│   └── node_info.json       # Node metadata used by helpers
├── data/                    # Blockchain data (git-ignored)
│   ├── blocks/              # Pruned block data (~9.5GB)
│   └── chainstate/          # UTXO set (~10GB)
└── lib/                     # Helper libraries
    ├── currency_manager.sh  # Currency / FX helper functions
    ├── node_info.sh         # Node-info helper functions
    └── number_format.sh     # Locale-safe formatting helpers
```

## Resuming the Claude Code Conversation

This project was built and upgraded in a named Claude Code session. To continue:

```bash
claude -r btc-node-upgrade
```

Or browse all sessions: `claude -r`

## Version History

- **v3.0.0** (2026-03-12) — Major upgrade: .env credentials, live FX rates (Frankfurter), persistent ATH cache, fee estimation panel (mempool.space), network stats (hashrate/difficulty/uptime/bandwidth/disk), beginner-friendly hints, ATH dates for all 8 currencies
- **v2.0.0** — Enhanced visual output, colored dashboard, btcs quick status
- **v1.0.0** — Initial monitoring scripts
