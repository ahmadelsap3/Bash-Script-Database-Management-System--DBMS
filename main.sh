#!/bin/bash

# Colors for better UI
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

DB_DIR="./databases"  # Directory to store all databases

# Import table operations
source ./lib/table_operations.sh
source ./lib/update_records.sh

# Function to create the databases directory if it doesn't exist
initialize() {
    if [ ! -d "$DB_DIR" ]; then
        mkdir -p "$DB_DIR"
        echo -e "${GREEN}Initialized DBMS successfully!${NC}"
    fi
}


initialize
