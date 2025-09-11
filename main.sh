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

# Function to list all databases
list_databases() {
    echo -e "${BLUE}Available Databases:${NC}"
    if [ -d "$DB_DIR" ] && [ "$(ls -A "$DB_DIR" 2>/dev/null)" ]; then
        ls -1 "$DB_DIR" | nl
    else
        echo -e "${YELLOW}No databases found.${NC}"
    fi
}

# Function to connect to a database
connect_to_database(){
    echo -e "${YELLOW}Enter database name to connect:${NC}"
    read -r db_name

    if [ -d "$DB_DIR/$db_name" ]; then
        echo -e "${GREEN}Connected to '$db_name' database.${NC}"
        database_menu "$db_name"
    else
        echo -e "${RED}Database '$db_name' does not exist!${NC}"
    fi
}

# Function to drop a database
drop_database() {
    echo -e "${YELLOW}Enter database name to drop:${NC}"
    read -r db_name

    if [ -d "$DB_DIR/$db_name" ]; then
        echo -e "${RED}Are you sure you want to drop '$db_name' database? (y/n)${NC}"
        read -r confirm
        if [ "$confirm" == "y" ] || [ "$confirm" == "Y" ]; then
            rm -rf "$DB_DIR/$db_name"
            echo -e "${GREEN}Database '$db_name' dropped successfully!${NC}"
        else
            echo -e "${BLUE}Operation cancelled.${NC}"
        fi
    else
        echo -e "${RED}Database '$db_name' does not exist!${NC}"
    fi
}

# Function to display the database menu
database_menu(){
    local db_name=$1
    while true; do
        echo -e "\n${BLUE}======= Database: $db_name =======${NC}"
        echo "1. Create Table"
        echo "2. List Tables"
        echo "3. Drop Table"
        echo "4. Insert into Table"
        echo "5. Select From Table"
        echo "6. Delete From Table"
        echo "7. Update Records (Bonus Feature)"
        echo "8. Back to Main Menu"
        echo -e "${YELLOW}Enter your choice:${NC}"
        read -r choice

        case $choice in
            1) create_table "$db_name" ;;
            2) list_tables "$db_name" ;;
            3) drop_table "$db_name" ;;
            4) insert_into_table "$db_name" ;;
            5) select_from_table "$db_name" ;;
            6) delete_from_table "$db_name" ;;
            7) update_table "$db_name" ;;
            8) return ;;
            *) echo -e "${RED}Invalid option${NC}" ;;
        esac
    done
}

# Main menu function
main_menu() {
    while true; do
        echo -e "\n${BLUE}======= DBMS Main Menu =======${NC}"
        echo "1. Create Database"
        echo "2. List Databases"
        echo "3. Connect To Database"
        echo "4. Drop Database"
        echo "5. Exit"
        echo -e "${YELLOW}Enter your choice:${NC}"
        read -r choice

        case $choice in
            1) create_database ;;
            2) list_databases ;;
            3) connect_to_database ;;
            4) drop_database ;;
            5)echo -e "${GREEN}Thank you for using Bash DBMS. Goodbye!${NC}"
              exit 0 ;;
            *) echo -e "${RED}Invalid option${NC}" ;;
        esac
    done
}

# Initialize and start the application
initialize
main_menu