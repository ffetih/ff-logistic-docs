#!/usr/bin/env bash
# Runs the spike: the clean build must pass, each of the three violations must fail verify().
# Needs ff-base-parent in ~/.m2 (ff-logistic-base: ./build.sh) and JDK 25.
set -uo pipefail
cd "$(dirname "$0")"
MVN=${MVN:-../../../base/mvnw}
P=app/src/main/java/com/siose/ff/logistics
ADAPTER=$P/beta/adapter/AlphaAnswerLookup.java
BETA=beta/src/main/java/com/siose/ff/logistics/beta/package-info.java
cp "$ADAPTER" /tmp/adapter.bak; cp "$BETA" /tmp/beta.bak
restore() { cp /tmp/adapter.bak "$ADAPTER"; cp /tmp/beta.bak "$BETA"; rm -rf "$P/alpha"; }
trap restore EXIT

check() { # $1 = expected outcome (pass|fail), $2 = case name
  "$MVN" -B -q install > build.log 2>&1; local status=$?
  local got=pass; [ $status -ne 0 ] && got=fail
  local mark=OK; [ "$got" != "$1" ] && mark=UNEXPECTED
  printf '%-11s %-62s expected %-4s got %s\n' "$mark" "$2" "$1" "$got"
  grep -oE '(^|: )- .*' build.log | sed 's/^: //' | head -2 | sed 's/^/            /'
  restore
}

check pass "clean: modules from jars, adapter in beta's package"
sed -i 's/return alpha.answer();/return com.siose.ff.logistics.alpha.internal.Secret.value();/' "$ADAPTER"
check fail "(a) the adapter reaches into alpha.internal"
sed -i 's/allowedDependencies = {"alpha"}/allowedDependencies = {}/' "$BETA"
check fail "(b) beta no longer allows alpha"
mkdir -p "$P/alpha/adapter"
printf 'package com.siose.ff.logistics.alpha.adapter;\npublic class BackRef { com.siose.ff.logistics.beta.AnswerLookup lookup; }\n' > "$P/alpha/adapter/BackRef.java"
check fail "(c) code under alpha uses beta: a cycle"
rm -f build.log
