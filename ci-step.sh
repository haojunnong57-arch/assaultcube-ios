#!/bin/bash
# record one build step into build.log, never abort the job on failure
set -u
echo "========== STEP: $1 ==========" >> build.log
shift
"$@" >> build.log 2>&1
rc=$?
echo "EXIT_CODE=$rc" >> build.log
exit 0
