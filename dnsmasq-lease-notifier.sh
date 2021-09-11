#!/usr/bin/env bash
# A script that watches dnsmasq's log via journalctl for new unknown hosts,
# and sends notifications to stdout and gotify

# depends:
# - nmap (opt, for mac vendor lookup)
# - ripgrep
# - choose
# - gotify/cli (opt)

nmapdb="${DNS_LEASE_WATCHER_NMAP_DB:-/usr/share/nmap/nmap-mac-prefixes}"

# curl http://standards-oui.ieee.org/oui/oui.txt | sudo tee /usr/local/share/oui.txt
ouidb="${DNS_LEASE_WATCHER_OUI_DB:-/usr/local/share/oui.txt}"


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

# Aug 27 20:21:14 pi dnsmasq-dhcp[26306]: DHCPACK(lan0) <lan_ip> <MAC>
process() {
    local IP="$(echo "$1" | choose -2)"
    local mac="$(echo "$1" | choose -1)"
    local vendor="$(lookup_vendor "$mac")"
    local dt="$(echo "$1" | choose :2)"

    printf "%s: new unknown device: %s %s (%s)\n" \
        "$dt" \
        "$IP" \
        "$mac" \
        "$vendor"

    if command -v gotify >/dev/null; then
        printf "%s: new unknown device: %s %s (%s)\n" \
            "$dt" \
            "$IP" \
            "$mac" \
            "$vendor" | gotify push
    fi
}

journalctl -f -u dnsmasq |
    # ignores known hosts
    rg 'DHCPACK.+ \d+\.\d+\.\d+\.\d+\s([0-9A-Fa-f]{2}[:-]){5}([0-9A-Fa-f]{2})$' |
    while read -r unknown; do
        process "$unknown"
    done
