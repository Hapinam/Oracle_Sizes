#!/usr/bin/env bash
#-----------------------------------------------------------------------------
# File      : tools/check_repo.sh
# Purpose   : Repository hygiene checks: every SQL script carries a header,
#             no CRLF line endings, and no credential looking values.
# Usage     : ./tools/check_repo.sh   (also run by .github/workflows/checks.yml)
# Requires  : bash, git, grep
#
# Copyright (c) 2026 Mohamed Dawood. MIT Licence; see LICENSE.
#-----------------------------------------------------------------------------
set -uo pipefail
cd "$(dirname "$0")/.."

status=0
fail() { echo "FAIL: $1"; status=1; }

# 1. Every .sql file must start with the standard header.
while IFS= read -r f; do
    head -n 3 "$f" | grep -q '^-- Script    :' || fail "missing header: $f"
done < <(git ls-files '*.sql')

# 2. No CRLF line endings.
while IFS= read -r f; do
    grep -qlU $'\r' "$f" && fail "CRLF line endings: $f"
done < <(git ls-files)

# 3. No credential looking values.
patterns=(
    'IDENTIFIED BY VALUES *.[0-9A-F]\{16\}'
    'USERID *= *[A-Za-z0-9_]\+/[A-Za-z0-9_]\+@'
    'CONNECT TO [A-Za-z0-9_]\+ *IDENTIFIED BY *[A-Za-z0-9_]\+'
)
for p in "${patterns[@]}"; do
    if git grep -nIi "$p" -- . ':!tools/check_repo.sh' >/dev/null; then
        git grep -nIi "$p" -- . ':!tools/check_repo.sh'
        fail "possible credential matching: $p"
    fi
done

# 4. No private IP addresses.
if git grep -nIE '(^|[^0-9.])(10\.[0-9]{1,3}|192\.168|172\.(1[6-9]|2[0-9]|3[01]))\.[0-9]{1,3}\.[0-9]{1,3}([^0-9.]|$)' \
     -- . ':!tools/check_repo.sh' >/dev/null; then
    git grep -nIE '(^|[^0-9.])(10\.[0-9]{1,3}|192\.168|172\.(1[6-9]|2[0-9]|3[01]))\.[0-9]{1,3}\.[0-9]{1,3}([^0-9.]|$)' \
      -- . ':!tools/check_repo.sh'
    fail "private IP address committed"
fi

[ $status -eq 0 ] && echo "All checks passed."
exit $status
