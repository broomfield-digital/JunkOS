#!/usr/bin/env bash
set -euo pipefail

# Bring up eth0 with static IP for OptConnect neo2.
#
# Usage (serial console, as root):
#   bash eth0-setup.sh
#
# Environment overrides:
#   ETH_IFACE        (default: eth0)
#   ETH_ADDRESS      (default: 192.168.1.11/24)
#   ETH_GATEWAY      (default: 192.168.1.90)
#   ETH_DNS          (default: 192.168.1.90 8.8.8.8)

ETH_IFACE="${ETH_IFACE:-eth0}"
ETH_ADDRESS="${ETH_ADDRESS:-192.168.1.11/24}"
ETH_GATEWAY="${ETH_GATEWAY:-192.168.1.90}"
ETH_DNS="${ETH_DNS:-192.168.1.90 8.8.8.8}"

log() { printf '[eth0-setup] %s\n' "$*"; }
warn() { log "WARN: $*"; }
die() { log "FATAL: $*"; exit 1; }

[ "$(id -u)" -eq 0 ] || die "must run as root"

# --- Bring up the link ---
log "bringing up $ETH_IFACE"
ip link set "$ETH_IFACE" up || die "failed to bring up $ETH_IFACE"
sleep 1

state="$(ip -o link show "$ETH_IFACE" | grep -oP 'state \K\S+')"
if [ "$state" = "DOWN" ] || [ "$state" = "NO-CARRIER" ]; then
	die "$ETH_IFACE link state: $state — check cable and OptConnect"
fi
log "$ETH_IFACE link state: $state"

# --- Flush any stale addresses/routes ---
ip addr flush dev "$ETH_IFACE" 2>/dev/null || true
ip route flush dev "$ETH_IFACE" 2>/dev/null || true

# --- Assign static IP ---
addr="${ETH_ADDRESS%/*}"
prefix="${ETH_ADDRESS#*/}"
log "assigning $ETH_ADDRESS to $ETH_IFACE"
ip addr add "$ETH_ADDRESS" dev "$ETH_IFACE"
ip route add default via "$ETH_GATEWAY" dev "$ETH_IFACE" || warn "default route may already exist"

# --- Write resolv.conf ---
if [ -L /etc/resolv.conf ]; then
	rm -f /etc/resolv.conf
fi
{
	printf '# Managed by eth0-setup.sh\n'
	for dns in $ETH_DNS; do
		printf 'nameserver %s\n' "$dns"
	done
} >/etc/resolv.conf
log "wrote /etc/resolv.conf: $ETH_DNS"

# --- Write persistent ifupdown config ---
case "$prefix" in
	24) netmask="255.255.255.0" ;;
	16) netmask="255.255.0.0" ;;
	8)  netmask="255.0.0.0" ;;
	*)  netmask="255.255.255.0"; warn "unknown prefix /$prefix; defaulting to /24" ;;
esac

mkdir -p /etc/network/interfaces.d
if [ -f /etc/network/interfaces ]; then
	if ! grep -Eq '^[[:space:]]*(source-directory|source)[[:space:]]+/etc/network/interfaces' /etc/network/interfaces; then
		printf '\nsource-directory /etc/network/interfaces.d\n' >>/etc/network/interfaces
	fi
else
	printf '# Managed by eth0-setup.sh\nsource-directory /etc/network/interfaces.d\n' >/etc/network/interfaces
fi

cat >"/etc/network/interfaces.d/${ETH_IFACE}.cfg" <<EOF
auto ${ETH_IFACE}
iface ${ETH_IFACE} inet static
    address ${addr}
    netmask ${netmask}
    gateway ${ETH_GATEWAY}
    dns-nameservers ${ETH_DNS}
EOF
log "wrote persistent config: /etc/network/interfaces.d/${ETH_IFACE}.cfg"

# --- Test connectivity ---
log "testing gateway ($ETH_GATEWAY)..."
if ping -c 2 -W 3 "$ETH_GATEWAY" >/dev/null 2>&1; then
	log "gateway reachable"
else
	die "cannot reach gateway $ETH_GATEWAY — check cable and OptConnect"
fi

log "testing internet (8.8.8.8)..."
if ping -c 2 -W 3 8.8.8.8 >/dev/null 2>&1; then
	log "internet reachable"
else
	warn "cannot reach 8.8.8.8 — OptConnect may not be routing yet"
fi

log "done — $ETH_IFACE is $addr via $ETH_GATEWAY"
