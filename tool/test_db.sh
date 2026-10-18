#!/usr/bin/env bash
# Runs the database tests in supabase/tests/rls_test.sql.
#
#   DATABASE_URL=postgresql://postgres:postgres@127.0.0.1:54322/postgres tool/test_db.sh
#       → against a running local Supabase (`supabase start`); migrations must
#         already be applied (`supabase db reset`). Changes are rolled back.
#
#   tool/test_db.sh
#       → without DATABASE_URL: spins up a throwaway Postgres (needs initdb and
#         pg_ctl on PATH or in /usr/lib/postgresql/*/bin), loads a Supabase stub
#         plus all migrations, runs the tests, and deletes the cluster.
set -euo pipefail
cd "$(dirname "$0")/.."

TESTS=supabase/tests/rls_test.sql

if [[ -n "${DATABASE_URL:-}" ]]; then
  psql "$DATABASE_URL" -X -q -v ON_ERROR_STOP=1 -P tuples_only=on -o /dev/null -f "$TESTS"
  exit 0
fi

PG_BIN=$(dirname "$(command -v initdb 2>/dev/null || ls /usr/lib/postgresql/*/bin/initdb | tail -1)")
TMP=$(mktemp -d)
PORT=${PGPORT_TEST:-55432}
cleanup() { "$PG_BIN/pg_ctl" -D "$TMP/data" -m immediate stop >/dev/null 2>&1 || true; rm -rf "$TMP"; }
trap cleanup EXIT

"$PG_BIN/initdb" -D "$TMP/data" -U postgres -A trust >/dev/null
"$PG_BIN/pg_ctl" -D "$TMP/data" -o "-p $PORT -k $TMP -c listen_addresses=''" -l "$TMP/log" -w start >/dev/null

PSQL=(psql -h "$TMP" -p "$PORT" -U postgres -d postgres -X -q -v ON_ERROR_STOP=1 -P tuples_only=on -o /dev/null)
"${PSQL[@]}" -f supabase/tests/support/stub_supabase.sql
for f in supabase/migrations/*.sql; do
  # Needs Vault, pg_cron and pg_net, which only exist on real Supabase.
  [[ "$f" == *_revalidation_cron.sql ]] && continue
  "${PSQL[@]}" -f "$f"
done
"${PSQL[@]}" -f "$TESTS"
