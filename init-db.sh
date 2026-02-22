#!/bin/bash

# Function to run sqlcmd
run_sql() {
    local file=$1
    local db=$2
    local db_arg=""
    if [ -n "$db" ]; then
        db_arg="-d $db"
    fi
    echo "Executing $file..."
    /opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P "$MSSQL_SA_PASSWORD" -C $db_arg -i "$file"
    if [ $? -ne 0 ]; then
        echo "Error executing $file"
        # Don't exit here, some scripts might fail if objects already exist, 
        # but we should log it.
    fi
}

# Wait for SQL Server to be ready
echo "Waiting for SQL Server to be ready..."
for i in {1..60}; do
    /opt/mssql-tools18/bin/sqlcmd -S localhost -U sa -P "$MSSQL_SA_PASSWORD" -C -Q "SELECT 1" > /dev/null 2>&1
    if [ $? -eq 0 ]; then
        echo "SQL Server is ready."
        break
    fi
    echo "Still waiting..."
    sleep 2
done

if [ $i -eq 60 ]; then
    echo "SQL Server did not become ready in time."
    exit 1
fi

echo "Initializing database..."

# 1. Create DB and base schema
run_sql "/app/db/DB_Basculas.sql"

# 2. Procedures
find /app/db/procedures -name "*.sql" | while read file; do
    run_sql "$file" "Bascula"
done

# 3. Triggers
find /app/db/Triggers -name "*.sql" | while read file; do
    run_sql "$file" "Bascula"
done

# 4. Views
find /app/db/views -name "*.sql" | while read file; do
    run_sql "$file" "Bascula"
done

# 5. Initial Inserts (Only if DB was just created or if desired)
run_sql "/app/db/inserts.sql" "Bascula"

echo "Database initialization completed for service 'data'."
