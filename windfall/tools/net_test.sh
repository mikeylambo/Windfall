#!/bin/bash
# Two real Godot processes over localhost: host + client.
# Passes when the client receives snapshots and the host sees the remote
# player move from the client's network intents.
cd "$(dirname "$0")/.."
godot --headless -s res://tools/net_test_host.gd > /tmp/windfall_net_host.log 2>&1 &
godot --headless -s res://tools/net_test_client.gd 2>&1 | grep "^\[client\]"
wait
grep "^\[host\]" /tmp/windfall_net_host.log
