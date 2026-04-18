# Arch + GNOME physical paper network printer setup

## Commands
Install the bits:
```bash
sudo pacman -S cups avahi nss-mdns system-config-printer
```
Enable printing + network discovery:


```bash
sudo systemctl enable --now cups.service avahi-daemon.service
```
Fix .local printer discovery in /etc/nsswitch.conf

Change the hosts: line to:
hosts: mymachines mdns [NOTFOUND=return] resolve [!UNAVAIL=return] files myhostname dns

Restart services:
```bash
sudo systemctl restart avahi-daemon.service cups.service
```

Check if the printer is visible:
```bash
ippfind
```

That should show something like:
```text
ipp://PRINTERNAME.local:631/ipp/print
```

## In GNOME
Open Settings → Printers → Add / Unlock / Search
and the printer should appear.

If GNOME still acts stupid, add it manually with the URI from ippfind:

```bash
sudo lpadmin -p brother -E -v 'ipp://PRINTERNAME.local:631/ipp/print' -m everywhere
```

Optional test:
```bash
lp -d brother /etc/hosts
```

the printer was broadcasting fine, but the system could not resolve .local names because mdns was missing from nsswitch.conf.
