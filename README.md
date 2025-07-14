# 🔒 IP Blocker for macOS (ZetaChain Work Trial)

A Bash-based solution to automatically detect and block known malicious IP addresses on macOS using the native `pf` (Packet Filter) firewall, with AbuseIPDB integration and optional Gmail alerts.

## 🚀 Features

- Fetches and blocks malicious IPs using [AbuseIPDB](https://www.abuseipdb.com/)
- Uses `pf` (Packet Filter) on macOS to enforce firewall rules
- Whitelists your trusted IPs (e.g., DNS, localhost, home network)
- Logs all blocked traffic using `tcpdump` and `pfctl`
- Sends **email alerts** when malicious IPs are blocked
- Auto-updates daily with a scheduled `cron` job

---

## 🛠️ Setup Instructions

### 1. Clone the repo
```bash
git clone https://github.com/YOUR_USERNAME/ip-blocker.git
cd ip-blocker
```

### 2. Add config to the script

Edit `block_malicious_ips.sh` and set your values at the top of the script:

```bash
ABUSEIPDB_API_KEY="YOUR_API_KEY_HERE"
EMAIL_FROM="youremail@gmail.com"
EMAIL_TO="yourdestination@gmail.com"
EMAIL_APP_PASSWORD="your_gmail_app_password"
```

### 3. Add whitelist IPs

Edit your `whitelist.txt` to include trusted IPs (one per line):

```
127.0.0.1
8.8.8.8
1.1.1.1
192.168.1.0/24
```

These are essential services and local traffic — they will never be blocked.

### 4. Update `/etc/pf.conf` to use your block/whitelist

Replace the bottom section of `/etc/pf.conf` with this:

```pf
# 🌐 Custom malicious IP blocking rules

table <malicious_ips> persist file "/etc/blocklist.conf"
table <whitelist_ips> persist file "/Users/YOUR_USERNAME/whitelist.txt"

pass quick from <whitelist_ips> to any
pass quick from any to <whitelist_ips>

block drop log quick from <malicious_ips> to any
block drop log quick to <malicious_ips>
```

### 5. Enable and reload PF

```bash
sudo pfctl -f /etc/pf.conf
sudo pfctl -e
```

### 6. Test logging

```bash
sudo ifconfig pflog0 create
sudo tcpdump -n -e -ttt -i pflog0
```

Optional: Capture to a `.pcap` file

```bash
sudo tcpdump -n -e -ttt -i pflog0 -w blocked_traffic.pcap
```

---

## 🕓 Setup Cron Job

To update your IP blocklist daily at 7:00 AM:

```bash
crontab -e
```

Add:
```
0 7 * * * /Users/YOUR_USERNAME/ip-blocker/block_malicious_ips.sh >> /Users/YOUR_USERNAME/ip-blocker/cron.log 2>&1
```

---

## 📄 Logging

Blocked IP attempts are logged and stored in:
```
/Users/YOUR_USERNAME/ip-blocker/cron.log
```

You can also view them live using:
```bash
sudo tcpdump -n -e -ttt -i pflog0
```

---

## 📧 Email Alerts (Optional)

If a blocked IP is detected, an email alert will be sent to `EMAIL_TO`. You must enable:
- Gmail 2FA
- Gmail App Passwords (generate one [here](https://myaccount.google.com/apppasswords))

---

## ✅ Demo Completed

This solution was created and demonstrated for the **ZetaChain Work Trial** project. It showcases:

- Bash scripting fundamentals
- Network security automation
- Real-world threat mitigation
- Email alerting + logging
- Custom PF firewall rule enforcement

---

## ✅ Final Notes

- Keep your API key and app password **private**
- You can expand this to pull from more sources or push alerts to Slack, SIEM, or a dashboard
- For production use, consider validating AbuseIPDB results or adding secondary reputation checks