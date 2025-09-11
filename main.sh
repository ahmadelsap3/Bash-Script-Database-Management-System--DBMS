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


create_database() {
    echo -e "${YELLOW}Enter Database Name:${NC}"
    read -r db_name

    if [[ ! $db_name =~ ^[a-zA-Z0-9_]+$ ]]; then
        echo -e "${RED}Error: Database name must contain only letters, numbers, and underscores${NC}"
        return 1
    fi

    if [ -d "$DB_DIR/$db_name" ]; then
        echo -e "${RED}Database '$db_name' already exists!${NC}"
    else
        mkdir -p "$DB_DIR/$db_name"
        echo -e "${GREEN}Database '$db_name' created successfully!${NC}"
    fi
}

# Main menu function
main_menu() {
    while true; do
        echo -e "\n${BLUE}======= DBMS Main Menu =======${NC}"
        echo "1. Create Database"
        #echo "2. List Databases"
        #echo "3. Connect To Database"
        #echo "4. Drop Database"
        echo "5. Exit"
        echo -e "${YELLOW}Enter your choice:${NC}"
        read -r choice

        case $choice in
            1) create_database ;;
            5)echo -e "${GREEN}Thank you for using Bash DBMS. Goodbye!${NC}"
              exit 0 ;;
            *) echo -e "${RED}Invalid option${NC}" ;;
        esac
    done
}

initialize
main_menu