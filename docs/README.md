# dnsmasq-lease-notifier

Is a daemon that watches dnsmasq log for `DHCPACK` for unknown hosts and notifies you via [gotify](https://gotify.net).

## Dependencies:
* [choose](https://github.com/theryangeary/choose)
* [ripgrep](https://github.com/BurntSushi/ripgrep)
* [gotify/cli](https://github.com/gotify/cli) (optional, for mobile notifications)
* `http://standards-oui.ieee.org/oui/oui.txt` or [nmap](https://nmap.org) (optional, for vendor identification)
* systemd (it watches `journalctl -f`) and `dnsmasq` (obviously)

## Options:

The script is quite short, so i expect you to edit it appropriately if needed.
However, you can set custom path to mac vendors files.

### `DNS_LEASE_WATCHER_OUI_DB`

This is a path to the copy of http://standards-oui.ieee.org/oui/oui.txt, defaults to /usr/local/share/oui.txt

```sh
curl 'http://standards-oui.ieee.org/oui/oui.txt' | sudo tee /usr/local/share/oui.txt
```

### `DNS_LEASE_WATCHER_NMAP_DB`

Defaults to `/usr/share/nmap/nmap-mac-prefixes`

If both present, `oui.txt` is preferred since it should be more up to date.

## Service

Download and install the script

```sh
curl -L \
  'https://raw.githubusercontent.com/MahouShoujoMivutilde/dnsmasq-lease-notifier/master/dnsmasq-lease-notifier.sh' |
  sudo tee /usr/local/bin/dnsmasq-lease-notifier.sh
```

Download and install the service file

```sh
curl -L \
  'https://raw.githubusercontent.com/MahouShoujoMivutilde/dnsmasq-lease-notifier/master/dnsmasq-lease-notifier.service' |
  sudo tee /etc/systemd/system/dnsmasq-lease-notifier.service
```

(Just in case)

```
systemctl daemon-reload
```

Enable and start the service

```

systemctl enable --now dnsmasq-lease-notifier.service
```

## Mobile notifications

In short:
1. setup [gotify/server](https://github.com/gotify/server) somewhere
2. in its webui create `dnsmasq watcher` app for your user, get its auth token
3. setup [gotify/cli](https://github.com/gotify/cli) with said token on your dnsmasq server
4. login in gotify on your phone

<details>
  <summary>Here is how it should look when you're done</summary>
  ![gotify](docs/gotify.png)
</details>


