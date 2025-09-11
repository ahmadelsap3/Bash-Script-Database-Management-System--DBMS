# Bash Shell Script Database Management System (DBMS)

A Command-Line Interface (CLI) Menu-based application that enables users to store and retrieve data from the hard disk.

## 🧑‍💻 Developed by

- Ahmad
- Kareem

## 📋 Features

### Main Menu

- Create Database
- List Databases
- Connect To Databases
- Drop Database

### Database Operations

- Create Table
- List Tables
- Drop Table
- Insert into Table
- Select From Table
- Delete From Table

## 🚀 How to Use

1. Make sure the script is executable:

   ```bash
   chmod +x main.sh
   ```

2. Run the script:

   ```bash
   ./main.sh
   ```

3. Follow the on-screen instructions to interact with the DBMS.

## 📝 Implementation Details

- Databases are stored as directories relative to the script file
- Tables are stored as files within the database directories
- Data types are validated during table creation and data insertion
- Primary keys ensure uniqueness during data insertion

## 📊 Project Structure

```text
.
├── main.sh                # Main script file
├── databases/             # Directory containing all databases
│   └── example_db/        # Example database
│       ├── table1         # Example table
│       └── table2         # Example table
└── README.md              # This file
```
