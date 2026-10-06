#!/usr/bin/env bash
# usage: cmd.sh name 'json-actions'
rm -f ${OUT:-/tmp/web456/run}/done
printf '{"name":"%s","actions":%s%s}' "$1" "$2" "${3:+,\"exit\":true}" > ${OUT:-/tmp/web456/run}/command.json.tmp && mv ${OUT:-/tmp/web456/run}/command.json.tmp ${OUT:-/tmp/web456/run}/command.json
for i in $(seq 1 200); do [ -f ${OUT:-/tmp/web456/run}/done ] && break; sleep 0.5; done
cat ${OUT:-/tmp/web456/run}/done; echo
