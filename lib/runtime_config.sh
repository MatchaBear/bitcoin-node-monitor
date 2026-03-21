#!/bin/bash

# Shared runtime configuration for container name and host data directory.

init_runtime_config() {
    local default_data_dir

    if [[ -n "${SCRIPT_DIR:-}" ]]; then
        default_data_dir="$SCRIPT_DIR/data"
    elif [[ -n "${BITCOIN_PROJECT_ROOT:-}" ]]; then
        default_data_dir="$BITCOIN_PROJECT_ROOT/data"
    else
        default_data_dir="$(cd "$(dirname "$(dirname "${BASH_SOURCE[0]}")")" && pwd)/data"
    fi

    BITCOIN_CONTAINER_NAME="${BTC_CONTAINER_NAME:-bitcoin-node}"

    if [[ -n "${BTC_DATA_DIR:-}" ]]; then
        case "$BTC_DATA_DIR" in
            /*) BITCOIN_DATA_DIR="$BTC_DATA_DIR" ;;
            *) BITCOIN_DATA_DIR="${SCRIPT_DIR:-$default_data_dir}/$BTC_DATA_DIR" ;;
        esac
    else
        BITCOIN_DATA_DIR="$default_data_dir"
    fi
}

btc_node_cli() {
    docker exec "$BITCOIN_CONTAINER_NAME" bitcoin-cli -rpcuser="$RPC_USER" -rpcpassword="$RPC_PASS" "$@"
}
