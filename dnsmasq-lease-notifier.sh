#!/usr/bin/env bash
# A script that should be executed by dnsmsaq via `--dhcp-script` option.
# It looks for unknown devices and sends notifications via gotify

# depends:
# - nmap (opt, for mac vendor lookup)
# - gotify/cli

set -e

# options:
nmapdb="${DNS_LEASE_WATCHER_NMAP_DB:-/usr/share/nmap/nmap-mac-prefixes}"

# curl http://standards-oui.ieee.org/oui/oui.txt | sudo tee /usr/local/share/oui.txt
ouidb="${DNS_LEASE_WATCHER_OUI_DB:-/usr/local/share/oui.txt}"


# see man dnsmasq, `dhcp-script`
cmd="$1"
mac="$2"
IP="$3"
hostname="$4" # relevant only for `known`

# special tag `known` is set when the host matches one of the `dhcp-host` entries or is in /etc/ethers
# hence we are looking for its absence
echo "$DNSMASQ_TAGS" | grep -i -v -q 'known' || exit 0

# we only care about `add` or `old`
[ "$cmd" = 'del' ] && exit 0

dt="$(date '+%b %d %H:%M:%S')"

# ---

search_nmap(){
    if [ ! -f "$nmapdb" ]; then
        echo "no nmap db" 1>&2
        return
    fi

    sed '/^\s*#/d' "$nmapdb" | rg -i "^$1" | choose 1:
}

search_oui(){
    if [ ! -f "$ouidb" ]; then
        echo "no oui db" 1>&2
        return
    fi

    rg -i "^$1" "$ouidb" | choose -f $'\t' 1:
}

lookup_vendor() {
    # get rid of : separators
    local mac="${1//:/}"
    local prefix="$(echo "$mac" | head -c 6)"

    local vendors=(
        "$(search_nmap "$prefix")"
        "$(search_oui "$prefix")"
    )

    vendor='Unknown'
    for v in "${vendors[@]}"; do
        if [ -n "$v" ]; then
            vendor="$v"
        fi
    done

    echo "$vendor"
}

vendor="$(lookup_vendor "$mac")"

out="$dt: new device: $IP"

if [ -n "$DNSMASQ_SUPPLIED_HOSTNAME" ]; then
    out="$out supplied host: $DNSMASQ_SUPPLIED_HOSTNAME;"
fi

if [ -n "$DNSMASQ_VENDOR_CLASS" ]; then
    out="$out class: $DNSMASQ_VENDOR_CLASS;"
fi

out="$out $mac ($vendor)"


echo "$out"

if command -v gotify >/dev/null; then
    echo "$out" | gotify push
fi
