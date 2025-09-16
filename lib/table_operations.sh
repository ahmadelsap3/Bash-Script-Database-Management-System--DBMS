# Function to list all tables in a database
list_tables() {
    local db_name="$1"
    local db_path="$DB_DIR/$db_name"
    echo -e "${BLUE}Tables in database '$db_name':${NC}"
    if [ -d "$db_path" ]; then
        local tables=( $(ls "$db_path" 2>/dev/null | grep -v ".meta$") )
        if [ ${#tables[@]} -eq 0 ]; then
            echo -e "${YELLOW}No tables found.${NC}"
        else
            local i=1
            for t in "${tables[@]}"; do
                echo "$i. $t"
                i=$((i+1))
            done
        fi
    else
        echo -e "${RED}Database directory not found!${NC}"
    fi
}
#!/bin/bash
# Database Table Operations module

MAX_COLUMNS=50

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

    if ! [[ "$col_count" =~ ^[1-9][0-9]*$ ]] || [ "$col_count" -lt 1 ] || [ "$col_count" -gt "$MAX_COLUMNS" ]; then
        echo -e "${RED}Error: Number of columns must be a positive integer and cannot exceed $MAX_COLUMNS.${NC}"
        return 1
    fi

    # Create metadata file to store column info
    local metadata_file="$DB_DIR/$db_name/$table_name.meta"
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

    # Create metadata file
    echo "Table: $table_name" > "$metadata_file"
    echo "Primary Key: $primary_key" >> "$metadata_file"
    echo "Columns:" >> "$metadata_file"

    for ((i = 0; i < col_count; i++)); do
        echo " - ${col_names[i]}: ${col_types[i]}" >> "$metadata_file"
    done

    # Create empty table file
    touch "$DB_DIR/$db_name/$table_name"
    echo -e "${GREEN}Table '$table_name' created successfully in database '$db_name'.${NC}"
    
    # Show table structure
    echo -e "${BLUE}Table Structure:${NC}"
    echo "-----------------------------------"
    echo -e "${BLUE}Primary Key: $primary_key${NC}"
    echo -e "${BLUE}Columns:${NC}"
    for ((i = 0; i < col_count; i++)); do
        echo -e "${BLUE}- ${col_names[i]} (${col_types[i]})${NC}"
    done
    echo "-----------------------------------"
}

#Function to drop a table from the database
drop_table() {
    local db_name="$1"
    echo -e "${YELLOW}Enter table name to drop:${NC}"
    read -r table_name

    if [ -f "$DB_DIR/$db_name/$table_name" ]; then
        echo -e "${RED}Are you sure you want to drop the table '$table_name'? This action cannot be undone. (y/n):${NC}"
        read -r confirm
        if [[ "$confirm" == "y" || "$confirm" == "Y" ]]; then
            rm -f "$DB_DIR/$db_name/$table_name"
            rm -f "$DB_DIR/$db_name/$table_name.meta"
            echo -e "${GREEN}Table '$table_name' dropped successfully from database '$db_name'.${NC}"
        else
            echo -e "${YELLOW}Drop table operation cancelled.${NC}"
        fi
    else
        echo -e "${RED}Error: Table '$table_name' does not exist in database '$db_name'.${NC}"
        return 1
    fi
}

# Function to validate data agains data type
validate_data() {
    local data="$1"
    local data_type="$2"

    case $data_type in
        "int")
            if ! [[ $data =~ ^-?[0-9]+$ ]]; then
                echo -e "${RED}Error: Invalid data for column '$col_name'. Expected integer.${NC}"
                return 1
            fi
            ;;
        "float")
            if ! [[ $data =~ ^-?[0-9]+(\.[0-9]+)?$ ]]; then
                echo -e "${RED}Error: Invalid data for column '$col_name'. Expected float.${NC}"
                return 1
            fi
            ;;
        "string")
            if [[ -z $data ]]; then
                echo -e "${RED}Error: Invalid data for column '$col_name'. Expected non-empty string.${NC}"
                return 1
            fi
            ;;
        *)
            echo -e "${RED}Error: Unknown data type '$data_type'.${NC}"
            return 1
            ;;
    esac

    return 0
}

# Function to insert a new record into a table
insert_record() {
    local db_name="$1"
    echo -e "${YELLOW}Enter table name to insert record into:${NC}"
    read -r table_name

    if [ ! -f "$DB_DIR/$db_name/$table_name" ]; then
        echo -e "${RED}Error: Table '$table_name' does not exist in database '$db_name'.${NC}"
        return 1
    fi

    local metadata_file="$DB_DIR/$db_name/$table_name.meta"
    if [ ! -f "$metadata_file" ]; then
        echo -e "${RED}Error: Metadata file for table '$table_name' is missing.${NC}"
        return 1
    fi


    # Parse metadata: only lines starting with ' - ' are columns
    local primary_key=$(grep "^Primary Key:" "$metadata_file" | awk -F': ' '{print $2}')
    local col_names=()
    local col_types=()
    while IFS= read -r line; do
        if [[ "$line" == " - "* ]]; then
            local col_line="${line# - }"
            local col_name="$(echo "$col_line" | awk -F': ' '{print $1}')"
            local col_type="$(echo "$col_line" | awk -F': ' '{print $2}')"
            col_names+=("$col_name")
            col_types+=("$col_type")
        fi
    done < "$metadata_file"

    # Get values for each column
    local values=()
    local pk_value=""
    local pk_index=-1

    for ((i = 0; i < ${#col_names[@]}; i++)); do
        local col_name="${col_names[i]}"
        local col_type="${col_types[i]}"

        echo -e "${YELLOW}Enter value for column '$col_name' (type: $col_type):${NC}"
        read -r value

        # Validate data type
        if ! validate_data "$value" "$col_type"; then
            echo -e "${RED}Error: Invalid data for column '$col_name'.${NC}"
            return 1
        fi

        # Store primary key value and index
        if [ "$col_name" == "$primary_key" ]; then
            pk_value="$value"
            pk_index="$i"
        fi

        values+=("$value")
    done

    # Check for primary key uniqueness
    if [ -n "$primary_key" ] && [ $pk_index -ge 0 ]; then
        while IFS='|' read -r -a row; do
            if [ "${row[$pk_index]}" == "$pk_value" ]; then
                echo -e "${RED}Error: Duplicate entry for primary key '$primary_key': $pk_value.${NC}"
                return 1
            fi
        done < "$DB_DIR/$db_name/$table_name"
    fi

    # Join values with delimiter and append to table file
    local record=$(printf "%s|" "${values[@]}")
    record=${record%|}  # Remove trailing delimiter
    echo "$record" >> "$DB_DIR/$db_name/$table_name"
    echo -e "${GREEN}Record inserted successfully into table '$table_name'.${NC}"
    
}

# Function to select data from a table
select_from_table() {
    local db_name="$1"
    echo -e "${YELLOW}Enter table name to select from:${NC}"
    read -r table_name
    if [ ! -f "$DB_DIR/$db_name/$table_name" ]; then
        echo -e "${RED}Error: Table '$table_name' does not exist in database '$db_name'.${NC}"
        return 1
    fi

    local metadata_file="$DB_DIR/$db_name/$table_name.meta"
    if [ ! -f "$metadata_file" ]; then
        echo -e "${RED}Error: Metadata file for table '$table_name' is missing.${NC}"
        return 1
    fi

    # Parse metadata: only lines starting with ' - ' are columns, trim whitespace
    local col_names=()
    while IFS= read -r line; do
        # Match any line with dash after optional whitespace
        if [[ "$line" =~ ^[[:space:]]*-[[:space:]] ]]; then
            local col_line="${line#*- }"
            local col_name="$(echo "$col_line" | awk -F':' '{print $1}' | xargs)"
            col_names+=("$col_name")
        fi
    done < "$metadata_file"
    echo -e "[DEBUG] Parsed columns: ${col_names[*]}" 1>&2

    # Check if table is empty
    if [ ! -s "$DB_DIR/$db_name/$table_name" ]; then
        echo -e "${YELLOW}Table '$table_name' is empty.${NC}"
        return 0
    fi

    # Print header
    local header=""
    local separator=""

    for col in "${col_names[@]}"; do
        header+="$col | "
        separator+="--------"
    done
    header=${header% | }  # Remove trailing delimiter
    echo -e "${BLUE}$header${NC}"
    echo -e "${BLUE}$separator${NC}"

    # Print each record
    while IFS='|' read -r -a row; do
        if [ -n "$row" ]; then
            local row_output=""
            for value in "${row[@]}"; do
                row_output+="$value | "
            done
            row_output=${row_output% | }  # Remove trailing delimiter
            echo -e "${BLUE}$row_output${NC}"
        fi
    done < "$DB_DIR/$db_name/$table_name"
}

# Function to delete records from a table based on a condition
delete_from_table() {
    local db_name="$1"
    echo -e "${YELLOW}Enter table name to delete records from:${NC}"
    read -r table_name

    if [ ! -f "$DB_DIR/$db_name/$table_name" ]; then
        echo -e "${RED}Error: Table '$table_name' does not exist in database '$db_name'.${NC}"
        return 1
    fi

    local metadata_file="$DB_DIR/$db_name/$table_name.meta"
    if [ ! -f "$metadata_file" ]; then
        echo -e "${RED}Error: Metadata file for table '$table_name' is missing.${NC}"
        return 1
    fi  

    # Print raw metadata file for debugging
    echo -e "[DEBUG RAW METADATA]:"
    cat "$metadata_file" 1>&2
    echo -e "[END DEBUG]"

    # Extract column names using direct line extraction
    echo -e "[DEBUG] Extracting columns from $metadata_file" 1>&2
    local col_names=()
    while IFS= read -r line; do
        # If line contains a dash and colon, it's probably a column definition
        if [[ "$line" == *"-"* && "$line" == *":"* ]]; then
            # Extract column name (part before the colon, after any dash)
            local col_part="${line#*-}"  # Remove everything up to dash
            local col_part="$(echo "$col_part" | xargs)"  # Trim whitespace
            local col_name="${col_part%%:*}"  # Keep only part before colon
            col_name="$(echo "$col_name" | xargs)"  # Trim whitespace
            echo -e "[DEBUG] Found column: '$col_name'" 1>&2
            col_names+=("$col_name")
        fi
    done < "$metadata_file"
    
    # If no columns found, try alternate method
    if [ ${#col_names[@]} -eq 0 ]; then
        echo -e "[DEBUG] No columns found, trying alternate method" 1>&2
        # Try a simple awk extraction looking for column pattern
        col_names=($(awk -F':' '/^[[:space:]]*-/ {gsub(/^[[:space:]]*-[[:space:]]*/, "", $1); print $1}' "$metadata_file"))
    fi
    
    echo -e "[DEBUG] All parsed columns: ${col_names[*]}" 1>&2
    
    # check if table has data
    if [ ! -s "$DB_DIR/$db_name/$table_name" ]; then
        echo -e "${YELLOW}Table '$table_name' is empty. No records to delete.${NC}"
        return 0
    fi

    # ask for column to match
    echo -e "${YELLOW}Enter column name to match for deletion:${NC}"
    read -r col_name
    if [[ ! " ${col_names[*]} " == *" $col_name "* ]]; then
        echo -e "${RED}Error: Column '$col_name' does not exist in table '$table_name'.${NC}"
        return 1
    fi
    local col_index=-1
    for i in "${!col_names[@]}"; do
        if [ "${col_names[i]}" == "$col_name" ]; then
            col_index=$i
            break
        fi
    done
    if [ $col_index -eq -1 ]; then
        echo -e "${RED}Error: Column '$col_name' not found in table '$table_name'.${NC}"
        return 1
    fi
    echo -e "${YELLOW}Enter value to match for deletion in column '$col_name':${NC}"
    read -r match_value
    local temp_file="$DB_DIR/$db_name/$table_name.tmp"
    local deleted_count=0
    while IFS='|' read -r -a row; do
        if [ "${row[$col_index]}" == "$match_value" ]; then
            ((deleted_count++))
            continue  # Skip this record (delete)
        fi
        echo "${row[*]}" | tr ' ' '|' >> "$temp_file"
    done < "$DB_DIR/$db_name/$table_name"
    mv "$temp_file" "$DB_DIR/$db_name/$table_name"
    echo -e "${GREEN}Deleted $deleted_count record(s) from table '$table_name' where '$col_name' = '$match_value'.${NC}"

}