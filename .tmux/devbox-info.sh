#!/bin/bash
# Show devbox name in tmux status bar: provider-gpus-index [container-hash]
# Called from tmux.conf via #(~/.tmux/devbox-info.sh)

# Get container hash (first 7 chars of hostname inside container, or from docker)
container_hash=""
if [ -f /.dockerenv ]; then
  # Inside container - hostname is container ID
  container_hash=$(hostname | cut -c1-7)
else
  # On host - get from docker
  container_hash=$(docker ps -q -f name=dev 2>/dev/null | head -1 | cut -c1-7)
fi

# Check for custom display name first
if [ -f /etc/devbox/display_name ]; then
  display_name=$(cat /etc/devbox/display_name)
  [ -n "$container_hash" ] && echo "│ ${display_name} [${container_hash}]" || echo "│ ${display_name}"
  exit 0
fi

# Get DEVBOX_NAME
devbox=$(tmux show-environment DEVBOX_NAME 2>/dev/null | cut -d= -f2)
[ -z "$devbox" ] || [ "$devbox" = "-DEVBOX_NAME" ] && devbox="$DEVBOX_NAME"
[ -z "$devbox" ] && exit 0

# Get provider (gcp, pi, aws, neb)
provider=$(cat /etc/devbox/provider 2>/dev/null || echo "")

# Extract GPU info (e.g., 1xh100, 8xh200) from name
gpu=$(echo "$devbox" | grep -oE '[0-9]+x[hH][0-9]+' | head -1 | tr 'H' 'h' || true)

# Extract index - last number in name, or use 1
index=$(echo "$devbox" | grep -oE '[0-9]+' | tail -1 || echo "1")
[ -z "$index" ] && index="1"

# Build display name
if [ -n "$provider" ] && [ -n "$gpu" ]; then
  display_name="${provider}-${gpu}-${index}"
elif [ -n "$provider" ]; then
  # No GPU in name, just show provider-index
  display_name="${provider}-${index}"
else
  # Fallback: strip zone/username and show
  devbox="${devbox%%.*}"
  devbox="${devbox#*-}"
  display_name="$devbox"
fi

# Output with leading separator (session name comes before us in status-right)
[ -n "$container_hash" ] && echo "│ ${display_name} [${container_hash}]" || echo "│ ${display_name}"
