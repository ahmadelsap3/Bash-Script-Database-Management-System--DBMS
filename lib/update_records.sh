#!/bin/bash

# Function to update records in a table (metadata format aligned with table_operations.sh)
update_table() {
    local db_name=$1
    echo -e "${YELLOW}Enter table name:${NC}"
    read -r table_name

    if [ ! -f "$DB_DIR/$db_name/$table_name" ]; then
        echo -e "${RED}Table '$table_name' does not exist!${NC}"
        return 1
    fi

    local metadata_file="$DB_DIR/$db_name/$table_name.meta"
    if [ ! -f "$metadata_file" ]; then
        echo -e "${RED}Metadata for table '$table_name' not found!${NC}"
        return 1
    fi

    # Parse metadata
    local primary_key=$(grep "^Primary Key:" "$metadata_file" | awk -F': ' '{print $2}')
    local col_names=()
    local col_types=()
    
    # Parse metadata: only lines starting with ' - ' are columns
    while IFS= read -r line; do
        if [[ "$line" == " - "* ]]; then
            local col_line="${line# - }"
            local col_name="$(echo "$col_line" | awk -F': ' '{print $1}' | xargs)"
            local col_type="$(echo "$col_line" | awk -F': ' '{print $2}' | xargs)"
            col_names+=("$col_name")
            col_types+=("$col_type")
        fi
    done < "$metadata_file"

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
    local filter_col_index=$((filter_col_choice-1))
    local filter_col=${col_names[$filter_col_index]}
    local filter_col_type=${col_types[$filter_col_index]}

    echo -e "${YELLOW}Enter value to match in column '$filter_col':${NC}"
    read -r match_value
    if ! validate_data "$match_value" "$filter_col_type"; then
        echo -e "${RED}Error: '$match_value' is not a valid $filter_col_type${NC}"
        return 1
    fi

    echo -e "${YELLOW}Select column to update:${NC}"
    for ((i=0; i<${#col_names[@]}; i++)); do
        echo "$((i+1)). ${col_names[i]}"
    done
    read -r update_col_choice
    if ! [[ $update_col_choice =~ ^[0-9]+$ ]] || [ "$update_col_choice" -lt 1 ] || [ "$update_col_choice" -gt "${#col_names[@]}" ]; then
        echo -e "${RED}Invalid column choice${NC}"
        return 1
    fi
    local update_col_index=$((update_col_choice-1))
    local update_col=${col_names[$update_col_index]}
    local update_col_type=${col_types[$update_col_index]}

    # Determine primary key index
    local pk_index=-1
    for ((i=0; i<${#col_names[@]}; i++)); do
        if [ "${col_names[i]}" == "$primary_key" ]; then
            pk_index=$i; break
        fi
    done

    local check_pk_uniqueness=false
    if [ "$update_col" == "$primary_key" ]; then
        echo -e "${YELLOW}Warning: Updating primary key requires uniqueness.${NC}"
        check_pk_uniqueness=true
    fi

    echo -e "${YELLOW}Enter new value for $update_col ($update_col_type):${NC}"
    read -r new_value
    if ! validate_data "$new_value" "$update_col_type"; then
        echo -e "${RED}Error: '$new_value' is not a valid $update_col_type${NC}"
        return 1
    fi

    if [ "$check_pk_uniqueness" == true ]; then
        while IFS='|' read -r -a row; do
            if [ "${row[$pk_index]}" == "$new_value" ]; then
                echo -e "${RED}Error: Primary key value '$new_value' already exists!${NC}"
                return 1
            fi
        done < "$DB_DIR/$db_name/$table_name"
    fi

    echo -e "${RED}Confirm update all rows where $filter_col = '$match_value'? (y/n)${NC}"
    read -r confirm
    if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
        echo -e "${BLUE}Operation cancelled.${NC}"
        return 0
    fi

    local temp_file
    temp_file=$(mktemp)
    local updated_count=0
    while IFS='|' read -r -a fields; do
        [ -z "${fields[*]}" ] && continue
        if [ "${fields[$filter_col_index]}" == "$match_value" ]; then
            fields[$update_col_index]="$new_value"
            updated_count=$((updated_count+1))
        fi
        local new_line
        new_line=$(printf "%s|" "${fields[@]}")
        new_line=${new_line%|}
        echo "$new_line" >> "$temp_file"
    done < "$DB_DIR/$db_name/$table_name"
    mv "$temp_file" "$DB_DIR/$db_name/$table_name"
    echo -e "${GREEN}Updated $updated_count record(s) successfully!${NC}"
}