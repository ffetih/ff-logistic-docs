#!/usr/bin/env bash
# Builds the documentation site into build/site. Needs Node.js 22 or newer.
set -euo pipefail
cd "$(dirname "$0")"
npm ci --no-audit --no-fund
npx antora --fetch antora-playbook.yml "$@"
echo "Site: build/site/index.html"
