#!/bin/bash
# Database Table Operations module

# Function to create a new table
create_table() {
    local db_name="$1"
    echo -e "${YELLOW}Enter table name:${NC}"
    read -r table_name

    # Validate table name
    if [[ ! $table_name =~ ^[a-zA-Z_][a-zA-Z0-9_]*$ ]]; then
        echo -e "${RED}Error: Invalid table name, table names must start with a letter or underscore and can only contain letters, numbers, and underscores.${NC}"
        return 1
    fi

    if [ -f "$DB_DIR/$db_name/$table_name" ]; then
        echo -e "${RED}Error: Table '$table_name' already exists in database '$db_name'.${NC}"
        return 1
    fi

    # Get number of columns
    echo -e "${YELLOW}Enter number of columns:${NC}"
    read -r col_count

    if ! [[ "$col_count" =~ ^[1-9][0-9]*$ ]] || [ "$col_count" -lt 1 ]; then
        echo -e "${RED}Error: Number of columns must be a positive integer and cannot exceed $MAX_COLUMNS.${NC}"
        return 1
    fi

    # Create metadata file to store column info
    local meta_file="$DB_DIR/$db_name/$table_name.meta"
    local primary_key=""
    local col_names=()
    local col_types=()

    for ((i = 1; i <= col_count; i++)); do
        echo -e "${YELLOW}Enter name for column $i:${NC}"
        read -r col_name

        # Validate column name
        if [[ ! $col_name =~ ^[a-zA-Z_][a-zA-Z0-9_]*$ ]]; then
            echo -e "${RED}Error: Invalid column name, column names must start with a letter or underscore and can only contain letters, numbers, and underscores.${NC}"
            return 1
        fi

        # Check for duplicate column names
        if [[ " ${col_names[*]} " == *" $col_name "* ]]; then
            echo -e "${RED}Error: Duplicate column name '$col_name'.${NC}"
            return 1
        fi

        col_names+=("$col_name")

        echo -e "${YELLOW}Enter data type for column '$col_name' (int/string):${NC}"
        read -r col_type

        if [[ "$col_type" != "int" && "$col_type" != "string" ]]; then
            echo -e "${RED}Error: Invalid data type. Only 'int' and 'string' are allowed.${NC}"
            return 1
        fi

        col_types+=("$col_type")

        if [ -z "$primary_key" ]; then
            echo -e "${YELLOW}Is this column the primary key? (y/n):${NC}"
            read -r is_pk
            if [[ "$is_pk" == "y" || "$is_pk" == "Y" ]]; then
                primary_key="$col_name"
            fi
        fi
    done

    # Ensure a primary key is set
    if [ -z "$primary_key" ]; then
        echo -e "${YELLOW}No Primary Key defined. Choose a column to be the Primary Key:${NC}"
        for col in "${col_names[@]}"; do
            echo -e "${YELLOW} - $col${NC}"
        done
        read -r pk_choice
        if [[ $pk_choice =~ ^[a-zA-Z_][a-zA-Z0-9_]*$ ]] && [[ " ${col_names[*]} " == *" $pk_choice "* ]]; then
            primary_key="$pk_choice"
        else
            echo -e "${RED}Error: Invalid primary key choice.${NC}"
            return 1
        fi
    fi
    
}