#!/bin/bash

# Variables (Set these according to your configuration)
CHAIN_ID=120202
ETHER_AMOUNT="1000000000000000000000000"  # 1 million Ether in Wei
NETWORK_ID=120202
PASSWORD=12345

# Function to kill any running bootnode process
kill_bootnode() {
  local pid
  pid=$(pgrep bootnode)
  if [[ -n $pid ]]; then
    echo "Stopping existing bootnode process (PID: $pid)..."
    kill -9 $pid
  fi
}

# Function to kill any running geth process
kill_geth() {
  local pid
  pid=$(pgrep geth)
  if [[ -n $pid ]]; then
    echo "Stopping existing geth process (PID: $pid)..."
    kill -9 $pid
  fi
}

# Kill any existing bootnode and geth processes
kill_bootnode
kill_geth

# Remove existing data directories to clear previous state
rm -rf ./node1/data
rm -rf ./node2/data

# Create directories for Node 1 and Node 2
mkdir -p ./node1/data
mkdir -p ./node2/data

# Create a password file
echo $PASSWORD > password.txt

# Create accounts for both nodes and capture addresses
echo "Creating account for Node 1."
FIRST_NODE_OUTPUT=$(geth --datadir "./node1/data" account new --password password.txt)
echo "$FIRST_NODE_OUTPUT"
FIRST_NODE_ADDRESS=$(echo "$FIRST_NODE_OUTPUT" | grep -oP '(?<=Public address of the key:   0x).*')

echo "Creating account for Node 2."
SECOND_NODE_OUTPUT=$(geth --datadir "./node2/data" account new --password password.txt)
echo "$SECOND_NODE_OUTPUT"
SECOND_NODE_ADDRESS=$(echo "$SECOND_NODE_OUTPUT" | grep -oP '(?<=Public address of the key:   0x).*')

# Initial signer address is the same as the first node address
INITIAL_SIGNER_ADDRESS=$FIRST_NODE_ADDRESS


# Create the Genesis file
cat <<EOF > genesis.json
{
  "config": {
    "chainId": $CHAIN_ID,
    "homesteadBlock": 0,
    "eip150Block": 0,
    "eip155Block": 0,
    "eip158Block": 0,
    "byzantiumBlock": 0,
    "constantinopleBlock": 0,
    "petersburgBlock": 0,
    "istanbulBlock": 0,
    "berlinBlock": 0,
    "clique": {
      "period": 5,
      "epoch": 30000
    }
  },
  "difficulty": "1",
  "gasLimit": "8000000",
  "extradata": "0x0000000000000000000000000000000000000000000000000000000000000000${INITIAL_SIGNER_ADDRESS}0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
  "alloc": {
    "${FIRST_NODE_ADDRESS}": { "balance": "${ETHER_AMOUNT}" },
    "${SECOND_NODE_ADDRESS}": { "balance": "${ETHER_AMOUNT}" }
  }
}
EOF

# Initialize both nodes with the Genesis file
geth --datadir "./node1/data" init genesis.json
geth --datadir "./node2/data" init genesis.json

# Create bootnode key
bootnode -genkey boot.key

# Start bootnode and capture enode URL, logging output to bootnode.log
bootnode -nodekey boot.key -verbosity 7 -addr "127.0.0.1:30301" > bootnode.log 2>&1 &

# Wait for bootnode to start and log the enode URL
sleep 5

# Extract enode URL from the bootnode log
BOOTNODE_URL=$(grep -oP 'enode:\/\/[a-zA-Z0-9@:.]+' bootnode.log)

# Append discport if missing
if [[ $BOOTNODE_URL != *"discport"* ]]; then
  BOOTNODE_URL="${BOOTNODE_URL}?discport=30301"
fi

# Check if the enode URL is valid
if [[ -z "$BOOTNODE_URL" ]]; then
  echo "Error: Failed to retrieve bootnode enode URL."
  exit 1
fi

# Save enode URL to file
echo $BOOTNODE_URL > enodeurl

# Start Node 1 and redirect log to node1.log
geth --datadir "./node1/data" --port 30304 --bootnodes "$BOOTNODE_URL" --authrpc.port 8547 --ipcdisable --allow-insecure-unlock --http --http.corsdomain="https://remix.ethereum.org" --http.api web3,eth,debug,personal,net --networkid $NETWORK_ID --unlock 0x$FIRST_NODE_ADDRESS --password password.txt --mine --miner.etherbase=0x$INITIAL_SIGNER_ADDRESS > node1.log 2>&1 &

# Start Node 2 and redirect log to node2.log
geth --datadir "./node2/data" --port 30306 --bootnodes "$BOOTNODE_URL" --authrpc.port 8546 --networkid $NETWORK_ID --unlock 0x$SECOND_NODE_ADDRESS --password password.txt > node2.log 2>&1 &
