FROM mcr.microsoft.com/mssql/server:2025-latest

WORKDIR /app/db

COPY . .

EXPOSE 1433