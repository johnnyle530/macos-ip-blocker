#!/bin/bash

# === Config ===
ABUSEIPDB_API_KEY="47ca96068c2fc4f2e593f95204cfc526418522ed4244090c09092bd0ddd8571fbe1f17e71189760e"
EMAIL_FROM="automation.test.johnny@gmail.com"
EMAIL_TO="automation.test.johnny@gmail.com"
EMAIL_PASSWORD="yhzn lyts hbcl avkw"
LOG_FILE="$HOME/ip_block_log.txt"
BLOCKLIST="$HOME/blocklist.conf"

# === Temp files ===
ABUSE_FILE=$(mktemp)
FIREHOL_FILE=$(mktemp)
SPAMHAUS_FILE=$(mktemp)

# === Fetch IPs from AbuseIPDB ===
curl -sG https://api.abuseipdb.com/api/v2/blacklist \
  --data-urlencode "confidenceMinimum=90" \
  --data-urlencode "limit=10000" \
  -H "Key: $ABUSEIPDB_API_KEY" \
  -H "Accept: application/json" | jq -r '.data[].ipAddress' > "$ABUSE_FILE"

# === Fetch IPs from FireHOL ===
curl -s https://raw.githubusercontent.com/firehol/blocklist-ipsets/master/firehol_level1.netset -o "$FIREHOL_FILE"

# === Fetch IPs from Spamhaus DROP List ===
curl -s https://www.spamhaus.org/drop/drop.txt | grep -v '^;' | awk '{print $1}' > "$SPAMHAUS_FILE"

# === Combine and deduplicate ===
echo "=== ABUSE FILE ==="
cat "$ABUSE_FILE"

echo "=== FIREHOL FILE ==="
cat "$FIREHOL_FILE"

echo "=== SPAMHAUS FILE ==="
cat "$SPAMHAUS_FILE"

cat "$ABUSE_FILE" "$FIREHOL_FILE" "$SPAMHAUS_FILE" | grep -Eo '([0-9]{1,3}\.){3}[0-9]{1,3}' | sort -u > "$BLOCKLIST"
cp "$BLOCKLIST" "$HOME/blocked_ips.txt"

# === Create PF config ===
echo "table <blocked_ips> persist file \"$BLOCKLIST\"" > "$HOME/pf_block.conf"
echo "block drop quick from <blocked_ips> to any" >> "$HOME/pf_block.conf"
echo "block drop quick from any to <blocked_ips>" >> "$HOME/pf_block.conf"

# === Load PF rules ===
sudo pfctl -f "$HOME/pf_block.conf"
sudo pfctl -e

# === Log the result ===
echo "$(date): Blocklist updated with $(wc -l < $BLOCKLIST) IPs" >> "$LOG_FILE"
cat "$BLOCKLIST" >> "$LOG_FILE"

# === Send Email Alert ===
python3 - <<EOF
import smtplib
import socket
from email.mime.text import MIMEText

hostname = socket.gethostname()
with open("$LOG_FILE") as f:
    msg = MIMEText(f.read())

msg['Subject'] = f'New IPs Blocked on {hostname}'
msg['From'] = "$EMAIL_FROM"
msg['To'] = "$EMAIL_TO"

s = smtplib.SMTP_SSL('smtp.gmail.com', 465)
s.login("$EMAIL_FROM", "$EMAIL_PASSWORD")
s.send_message(msg)
s.quit()
EOF

# === Cleanup temp files ===
rm "$ABUSE_FILE" "$FIREHOL_FILE" "$SPAMHAUS_FILE"

