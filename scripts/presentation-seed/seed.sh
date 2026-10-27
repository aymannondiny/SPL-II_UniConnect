#!/usr/bin/env bash
set -euo pipefail

mode="${1:-}"
if [[ "$mode" != "dry-run" && "$mode" != "apply" && "$mode" != "verify" ]]; then
  echo "Usage: PRESENTATION_DB_URL=... PRESENTATION_DB_USERNAME=... PRESENTATION_DB_PASSWORD=... $0 {dry-run|apply|verify}" >&2
  exit 64
fi

: "${PRESENTATION_DB_URL:?PRESENTATION_DB_URL is required}"
: "${PRESENTATION_DB_USERNAME:?PRESENTATION_DB_USERNAME is required}"
: "${PRESENTATION_DB_PASSWORD:?PRESENTATION_DB_PASSWORD is required}"

case "$PRESENTATION_DB_URL" in
  jdbc:postgresql://*) psql_url="postgresql://${PRESENTATION_DB_URL#jdbc:postgresql://}" ;;
  postgresql://*|postgres://*) psql_url="$PRESENTATION_DB_URL" ;;
  *) echo "Only PostgreSQL JDBC/libpq URLs are supported." >&2; exit 64 ;;
esac

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd "$script_dir/../.." && pwd)"
private_dir="$(mktemp -d /tmp/uniconnect-presentation-seed.XXXXXXXX)"
chmod 700 "$private_dir"
cleanup() { rm -rf "$private_dir"; }
trap cleanup EXIT

export PGPASSWORD="$PRESENTATION_DB_PASSWORD"
psql_args=(--no-psqlrc --set=ON_ERROR_STOP=1 --username="$PRESENTATION_DB_USERNAME" --dbname="$psql_url")

if [[ "$mode" == "dry-run" ]]; then
  psql "${psql_args[@]}" --file="$script_dir/dry-run.sql"
  exit
fi
if [[ "$mode" == "verify" ]]; then
  psql "${psql_args[@]}" --file="$script_dir/verify.sql"
  exit
fi

backend_dir="$repo_root/code/backend"
if [[ ! -d "$backend_dir/target/classes" ]]; then
  (cd "$backend_dir" && ./mvnw -q -DskipTests package)
fi
(cd "$backend_dir" && ./mvnw -q dependency:build-classpath -Dmdep.outputFile="$private_dir/classpath")
java -cp "$backend_dir/target/classes:$(<"$private_dir/classpath")" \
  "$script_dir/PasswordHashGenerator.java" 'Seed!234' > "$private_dir/password-hash"
chmod 600 "$private_dir/password-hash"
password_hash="$(<"$private_dir/password-hash")"
if [[ ! "$password_hash" =~ ^\$2[aby]\$10\$ ]]; then
  echo "Configured password encoder did not produce an expected BCrypt strength-10 hash." >&2
  exit 1
fi

wrapper="$private_dir/apply.sql"
{
  printf '\\set password_hash '\''%s'\''\n' "$password_hash"
  printf '\\set failpoint '\''%s'\''\n' "${PRESENTATION_SEED_FAILPOINT:-none}"
  printf '\\ir %s\n' "$script_dir/seed.sql"
} > "$wrapper"
chmod 600 "$wrapper"
psql "${psql_args[@]}" --file="$wrapper"
