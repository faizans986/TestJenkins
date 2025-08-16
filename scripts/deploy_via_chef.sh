#!/usr/bin/env bash
set -euo pipefail
NODE_QUERY="${1:-name:webserver}"
if ! command -v knife >/dev/null 2>&1; then
  echo "Chef Workstation (knife) not found. Install it to deploy via Chef."
  exit 0
fi
echo "Running chef-client on: $NODE_QUERY"
knife ssh "$NODE_QUERY" "sudo chef-client" -x ec2-user || knife ssh "$NODE_QUERY" "sudo chef-client"
