#!/bin/bash

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

echo "All nodes and bootnode have been stopped."
