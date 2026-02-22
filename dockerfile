FROM mcr.microsoft.com/mssql/server:2022-latest

USER root

# Create app directory and set ownership
WORKDIR /app/db

# Copy everything with correct ownership for the mssql user
COPY --chown=mssql:0 . .

# Ensure scripts have execution permissions
RUN chmod +x /app/db/entrypoint.sh /app/db/init-db.sh

# Ensure the mssql user has access to its own configuration folders
# This is crucial for SQL Server 2025 non-root stability
RUN chown -R mssql:0 /var/opt/mssql /app/db

USER mssql

EXPOSE 1433

ENTRYPOINT ["/app/db/entrypoint.sh"]