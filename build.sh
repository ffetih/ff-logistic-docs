#!/usr/bin/env bash
# Builds the documentation site into build/site. Needs Node.js 22 or newer, and the other
# five repositories checked out next to this one (../runtime, ../base, ../shared, ../modulith,
# ../services), as in D:\dev\workspace\ff-logistic.
set -euo pipefail
cd "$(dirname "$0")"
npm ci --no-audit --no-fund
npx antora --fetch antora-playbook.yml "$@"
echo "Site: build/site/index.html"
