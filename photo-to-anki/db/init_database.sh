#!/bin/bash

SCHEMA_PATH="$SCRIPT_DIR/db/schema.sql"

# if not exists, create the database
if ! [[ -f "$DATABASE_PATH" ]]; then
    sqlite3 "$DATABASE_PATH" < "$SCHEMA_PATH"
fi

