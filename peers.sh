#!/bin/bash

# Ganti "bitcoin-node" dengan nama container lo kalau beda
CONTAINER_NAME="bitcoin-node"

# Eksekusi perintah di dalam container
peer_count=$(docker exec "$CONTAINER_NAME" bitcoin-cli getconnectioncount 2>/dev/null)

if [ $? -eq 0 ]; then
    echo "✅ Peers connected: $peer_count"
else
    echo "❌ Gagal mendapatkan data peer. Pastikan node sedang jalan dan container benar."
fi

