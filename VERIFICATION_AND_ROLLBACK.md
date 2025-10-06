# Bitcoin Monitor: Verification and Contingency Plan

This document explains how to verify the updated monitor script, and how to recover quickly if anything breaks. It’s written for non-programmers.

## What changed in this update
- Peer list now shows:
  - Correct country even for IPv6 peers (e.g., `[2001:db8::1]:8333`)
  - Latency per peer (ms), using `minping` or `pingtime` from `getpeerinfo`
- Geolocation is cached and more resilient:
  - Provider order: ipinfo.io → ip-api.com → ipwho.is
  - Cached in: `peer_country_cache.txt` so repeat lookups don’t hit external APIs

Files affected:
- `btc-monitor` (main dashboard script)
- New cache file (runtime): `peer_country_cache.txt` in `~/bitcoin/`

---

## Post-implementation verification (10–15 minutes)

1) Sanity checks
- Ensure Docker container is running:
  - `docker ps --filter name=bitcoin-node`
- Quick node connectivity checks:
  - `docker exec bitcoin-node bitcoin-cli getnetworkinfo | jq '.connections'`
  - `docker exec bitcoin-node bitcoin-cli getpeerinfo | jq 'length'`

2) Script syntax check (no output means OK)
- `bash -n /Users/bermekbukair/bitcoin/btc-monitor`

3) Run the monitor for ~1 minute
- Start: `btcm` (Ctrl+C to exit)
- Expect under “Connected Peers”: each line shows `[flag] ip:port (Country)  N ms`
- Expect a new file: `/Users/bermekbukair/bitcoin/peer_country_cache.txt` that grows as peers are geolocated

4) Spot-check latency and country
- Compare latency roughly with geography (e.g., SG/SEA peers are usually lower ms; US/EU higher)
- Confirm that at least some peers show flags and readable country names

5) Price data still loads
- In the “MARKET DATA” section, each currency line shows a provider in parentheses, e.g. `(CryptoCompare)` or `(Binance 24hr)`

If the above all look good, the update is verified.

---

## How to recover (contingency)

If the script stops working or errors appear, use one of these safe options:

A) Revert only the monitor script to its previous version
- Show history: `git --no-pager -C /Users/bermekbukair/bitcoin log --oneline -n 5 -- btc-monitor`
- Restore the previous version (one commit back):
  - `git -C /Users/bermekbukair/bitcoin restore --source=HEAD~1 -- btc-monitor`
- Re-run: `btcm`

B) Revert the last commit entirely (if it was only this change)
- `git -C /Users/bermekbukair/bitcoin revert --no-edit HEAD`
- `git -C /Users/bermekbukair/bitcoin push`

C) Restore from the backup tarball we created
- Backups are stored under: `/Users/bermekbukair/backups/bitcoin/`
- Pick the timestamp you want, e.g. `bitcoin-YYYYmmdd-HHMMSS.tar.gz`
- Extract over the repo (this overwrites files to the saved state):
  - `tar -xzf /Users/bermekbukair/backups/bitcoin/bitcoin-YYYYmmdd-HHMMSS.tar.gz -C /Users/bermekbukair/bitcoin`

D) Temporary bypass of geolocation (quick workaround)
- If external geolocation APIs misbehave, the cache helps. If you still see issues, you can temporarily bypass the country lookup:
  - Open `/Users/bermekbukair/bitcoin/btc-monitor`
  - Find function `get_country_info_cached()`
  - Insert this line as the very first line after the opening `{`:
    - `echo ""; return 0`
  - Save and run `btcm` again
  - This disables geolocation (you’ll still see peers without country)
  - When things are stable, remove the two lines to re-enable

---

## Notes on avoiding issues
- API rate limits
  - The script queries multiple providers and caches results, so repeated refreshes shouldn’t re-hit external APIs for the same IPs
- Privacy considerations
  - Geolocating peers calls external services with peer IPs; the local cache reduces frequency, but if privacy is critical, consider using an offline GeoIP database later
- Secrets hygiene
  - Prefer exporting `BTC_RPC_USER` and `BTC_RPC_PASS` as environment variables before running `btcm`, rather than relying on defaults in the script
  - If you ever want, we can move secrets to a `.env` file and add it to `.gitignore`

---

## What to tell me if you need help
- A screenshot or copy-paste of any error you see
- Output of:
  - `docker exec bitcoin-node bitcoin-cli getnetworkinfo | jq '.connections'`
  - `docker exec bitcoin-node bitcoin-cli getpeerinfo | jq '.[0] | {addr, minping, pingtime}'`
  - `bash -n /Users/bermekbukair/bitcoin/btc-monitor && echo OK || echo FAIL`
