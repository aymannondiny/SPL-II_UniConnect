#!/usr/bin/env bash
# Deliberate, localhost-only fixture installation. Does not start services or load .env files.
set -euo pipefail
if [[ $# -ne 4 || ( "$1" != "apply" && "$1" != "verify" ) ]]; then
    echo 'Usage: bash scripts/demo-seed/seed.sh apply|verify PORT DATABASE_USER uniconnect_demo' >&2
    exit 2
fi
operation=$1
port=$2
database_user=$3
database_name=$4
if [[ ! "$port" =~ ^[0-9]{1,5}$ ]] || (( 10#$port < 1024 || 10#$port > 65535 )); then
    echo 'Use a dedicated localhost PostgreSQL port between 1024 and 65535.' >&2
    exit 2
fi
if [[ "$database_name" != uniconnect_demo || ! "$database_user" =~ ^[a-zA-Z_][a-zA-Z0-9_]*$ ]]; then
    echo 'Database must be uniconnect_demo; user must be a simple PostgreSQL role name.' >&2
    exit 2
fi
command -v psql >/dev/null || { echo 'Install the PostgreSQL client first.' >&2; exit 2; }
script_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
file=seed.sql
[[ "$operation" == verify ]] && file=verify.sql
# Explicit connection arguments override PGHOST/PGDATABASE; -X ignores .psqlrc.
# A password prompt is allowed for a local role. Never put passwords into this command.
exec psql -X --host=127.0.0.1 --port="$port" --username="$database_user" \
    --dbname="$database_name" --set=ON_ERROR_STOP=1 --pset=pager=off --file="$script_dir/$file"
