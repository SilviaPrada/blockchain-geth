#!/bin/bash

# Variables (Set these according to your configuration)
CHAIN_ID=120202
NETWORK_ID=120202
PASSWORD=12345

# Read the bootnode URL from the file
BOOTNODE_URL=$(cat enodeurl)

# Start bootnode and capture enode URL, logging output to bootnode.log
bootnode -nodekey boot.key -verbosity 7 -addr "127.0.0.1:30301" > bootnode.log 2>&1 &

# Wait for bootnode to start and log the enode URL
sleep 5

# Append discport if missing
if [[ $BOOTNODE_URL != *"discport"* ]]; then
  BOOTNODE_URL="${BOOTNODE_URL}?discport=30301"
fi

# Start Node 1 and redirect log to node1.log
geth --datadir "./node1/data" --port 30304 --bootnodes "$BOOTNODE_URL" --authrpc.port 8547 --ipcdisable --allow-insecure-unlock --http --http.corsdomain="https://remix.ethereum.org" --http.api web3,eth,debug,personal,net --networkid $NETWORK_ID --unlock 0x$(cat node1/data/keystore/* | grep -oP '(?<=address":").+?(?=")') --password password.txt --mine --miner.etherbase=0x$(cat node1/data/keystore/* | grep -oP '(?<=address":").+?(?=")') > node1.log 2>&1 &

# Start Node 2 and redirect log to node2.log
geth --datadir "./node2/data" --port 30306 --bootnodes "$BOOTNODE_URL" --authrpc.port 8546 --networkid $NETWORK_ID --unlock 0x$(cat node2/data/keystore/* | grep -oP '(?<=address":").+?(?=")') --password password.txt > node2.log 2>&1 &

echo "All nodes and bootnode have been started."
