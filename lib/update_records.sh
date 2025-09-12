#!/bin/bash

# Function to update records in a table
update_table() {
    local db_name=$1
    echo -e "${YELLOW}Enter table name:${NC}"
    read -r table_name

    if [ ! -f "$DB_DIR/$db_name/$table_name" ]; then
        echo -e "${RED}Table '$table_name' does not exist!${NC}"
        return 1
    fi

    local metadata_file="$DB_DIR/$db_name/$table_name.metadata"
    if [ ! -f "$metadata_file" ]; then
        echo -e "${RED}Metadata for table '$table_name' not found!${NC}"
        return 1
    fi

    local column_data=($(grep -v "^#" "$metadata_file"))
    local col_names=()
    local col_types=()

    for col in "${column_data[@]}"; do
        col_name=$(echo "$col" | cut -d':' -f1)
        col_type=$(echo "$col" | cut -d':' -f2)
        col_names+=("$col_name")
        col_types+=("$col_type")
    done

    # Check if table has data
    if [ ! -s "$DB_DIR/$db_name/$table_name" ]; then
        echo -e "${YELLOW}Table '$table_name' is empty.${NC}"
        return 0
    fi

    echo -e "${YELLOW}Select column to filter on:${NC}"
    for ((i=0; i<${#col_names[@]}; i++)); do
        echo "$((i+1)). ${col_names[i]}"
    done
    read -r filter_col_choice

    if ! [[ $filter_col_choice =~ ^[0-9]+$ ]] || [ "$filter_col_choice" -lt 1 ] || [ "$filter_col_choice" -gt "${#col_names[@]}" ]; then
        echo -e "${RED}Invalid column choice${NC}"
        return 1
    fi

    local filter_col=${col_names[$((filter_col_choice-1))]}
    local filter_col_index=$((filter_col_choice-1))
    local filter_col_type=${col_types[$filter_col_index]}

    echo -e "${YELLOW}Enter value to match in column '$filter_col':${NC}"
    read -r match_value

    if ! validate_data "$match_value" "$filter_col_type"; then
        echo -e "${RED}Error: '$match_value' is not a valid $filter_col_type${NC}"
        return 1
    fi

    # Ask for column to update
    echo -e "${YELLOW}Select column to update:${NC}"
    for ((i=0; i<${#col_names[@]}; i++)); do
        echo "$((i+1)). ${col_names[i]}"
    done
    read -r update_col_choice
    
    if ! [[ $update_col_choice =~ ^[0-9]+$ ]] || [ "$update_col_choice" -lt 1 ] || [ "$update_col_choice" -gt "${#col_names[@]}" ]; then
        echo -e "${RED}Invalid column choice${NC}"
        return 1
    fi
    
    local update_col=${col_names[$((update_col_choice-1))]}
    local update_col_index=$((update_col_choice-1))
    local update_col_type=${col_types[$update_col_index]}

    # Get primary key info
    local primary_key=$(grep "^# PrimaryKey:" "$metadata_file" | cut -d' ' -f3)
    local pk_index=-1
    
    for ((i=0; i<${#col_names[@]}; i++)); do
        if [ "${col_names[i]}" == "$primary_key" ]; then
            pk_index=$i
            break
        fi
    done

    # Check if updating primary key
    local check_pk_uniqueness=false
    if [ "$update_col" == "$primary_key" ]; then
        echo -e "${YELLOW}Warning: You are updating a primary key column. New values must be unique.${NC}"
        check_pk_uniqueness=true
    fi
    
    echo -e "${YELLOW}Enter new value for $update_col ($update_col_type):${NC}"
    read -r new_value

    # Validate new value
    if ! validate_data "$new_value" "$update_col_type"; then
        echo -e "${RED}Error: '$new_value' is not a valid $update_col_type${NC}"
        return 1
    fi

    # If updating primary key, check uniqueness
    if [ "$check_pk_uniqueness" == true ]; then
        while IFS='|' read -r line; do
            if [ -n "$line" ]; then
                local existing_fields=(${line//|/ })
                if [ "${existing_fields[$pk_index]}" == "$new_value" ]; then
                    echo -e "${RED}Error: Primary key value '$new_value' already exists!${NC}"
                    return 1
                fi
            fi
        done < "$DB_DIR/$db_name/$table_name"
    fi

    echo -e "${RED}Are you sure you want to update all records where $filter_col = '$match_value'? (y/n)${NC}"
    read -r confirm
    if [ "$confirm" != "y" ] && [ "$confirm" != "Y" ]; then
        echo -e "${BLUE}Operation cancelled.${NC}"
        return 0
    fi

    # Create a temporary file
    local temp_file=$(mktemp)
    local updated_count=0
    
    # Process each line
    while IFS='|' read -r line; do
        if [ -n "$line" ]; then
            IFS='|' read -ra fields <<< "$line"
            
            if [ "${fields[$filter_col_index]}" == "$match_value" ]; then
                
                fields[$update_col_index]=$new_value
                updated_count=$((updated_count + 1))
            fi
            
            local updated_line=$(printf "%s|" "${fields[@]}")
            updated_line=${updated_line%|}
            
            echo "$updated_line" >> "$temp_file"
        fi
    done < "$DB_DIR/$db_name/$table_name"

    mv "$temp_file" "$DB_DIR/$db_name/$table_name"

    echo -e "${GREEN}Updated $updated_count record(s) successfully!${NC}"
}