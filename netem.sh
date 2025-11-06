#!/bin/bash
# Usage:
#   sudo ./netem.sh <add|del> <interface> [latency] [jitter] [bandwidth] [packet_loss]
#
# Examples:
#   sudo ./netem.sh add eth0 100ms 30ms 10mbit 2%
#   sudo ./netem.sh add eth0 200ms          # only change latency
#   sudo ./netem.sh del eth0
#
# Description:
#   - "add" applies network emulation (sets only specified params).
#   - "del" removes tc and iptables configurations.

set -e

ACTION=$1
IFACE=$2
LATENCY=$3
JITTER=$4
BANDWIDTH=$5
LOSS=$6

LOCAL_NETWORK="192.168.0.0/16"

if [[ -z "$ACTION" || -z "$IFACE" ]]; then
  echo "Usage: sudo $0 <add|del> <interface> [latency] [jitter] [bandwidth] [packet_loss]"
  exit 1
fi

case "$ACTION" in
  add)
    echo "[*] Applying network emulation on $IFACE..."

    # Clean up previous setup
    sudo tc qdisc del dev "$IFACE" root 2>/dev/null || true
    sudo iptables -t mangle -D OUTPUT -d "$LOCAL_NETWORK" -j MARK --set-mark 1 2>/dev/null || true

    # Add iptables mark for internal traffic
    echo "[*] Adding iptables mark..."
    sudo iptables -t mangle -A OUTPUT -d "$LOCAL_NETWORK" -j MARK --set-mark 1

    # Start with base hierarchy
    echo "[*] Setting up tc qdisc hierarchy..."
    sudo tc qdisc add dev "$IFACE" root handle 1: prio
    sudo tc qdisc add dev "$IFACE" parent 1:1 handle 10: sfq

    # Build netem command dynamically
    NETEM_CMD="sudo tc qdisc add dev $IFACE parent 1:2 handle 20: netem"
    [[ -n "$LATENCY" ]] && NETEM_CMD+=" delay ${LATENCY}"
    [[ -n "$JITTER" ]] && NETEM_CMD+=" ${JITTER}"
    [[ -n "$LOSS" ]] && NETEM_CMD+=" loss ${LOSS}"

    # If user provided any of these params, add netem
    if [[ -n "$LATENCY" || -n "$JITTER" || -n "$LOSS" ]]; then
      echo "[*] Adding netem: $NETEM_CMD"
      eval "$NETEM_CMD"
    else
      echo "[*] No latency/jitter/loss specified — skipping netem."
      sudo tc qdisc add dev "$IFACE" parent 1:2 handle 20: sfq
    fi

    # Add bandwidth limit if specified
    if [[ -n "$BANDWIDTH" ]]; then
      echo "[*] Applying bandwidth limit: ${BANDWIDTH}"
      sudo tc qdisc add dev "$IFACE" parent 20:1 handle 30: tbf rate ${BANDWIDTH} burst 32kbit latency 400ms
    fi

    # Filters: internal = normal, external = shaped
    sudo tc filter add dev "$IFACE" parent 1: protocol ip handle 1 fw flowid 1:1
    sudo tc filter add dev "$IFACE" parent 1: protocol ip handle 0 fw flowid 1:2

    echo
    echo "[+] Network emulation applied on $IFACE"
    tc qdisc show dev "$IFACE" -v
    tc filter show dev "$IFACE" -v"$IFACE"
    ;;

  del)
    echo "[*] Removing network emulation from $IFACE..."

    sudo tc qdisc del dev "$IFACE" root 2>/dev/null || true
    sudo iptables -t mangle -D OUTPUT -d "$LOCAL_NETWORK" -j MARK --set-mark 1 2>/dev/null || true

    echo "[+] Network emulation removed from $IFACE"
    ;;

  *)
    echo "Invalid action: $ACTION"
    echo "Usage: sudo $0 <add|del> <interface> [latency] [jitter] [bandwidth] [packet_loss]"
    exit 1
    ;;
esac
