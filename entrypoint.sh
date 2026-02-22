#!/bin/bash

# Start the helper to setup the database
/app/db/init-db.sh &

# Start SQL Server
exec /opt/mssql/bin/sqlservr
