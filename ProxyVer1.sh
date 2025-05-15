#!/bin/bash

# === Cấu hình BOT TELEGRAM ===
BOT_TOKEN="YOUR_BOT_TOKEN"
CHAT_ID="YOUR_CHAT_ID"

# === Kiểm tra kết nối mạng ===
for i in {1..5}; do
  if curl -s --max-time 5 https://api.ipify.org > /dev/null; then
    break
  fi
  sleep 2
done

if ! curl -s --max-time 5 https://api.ipify.org > /dev/null; then
  curl -s -X POST "https://api.telegram.org/bot${BOT_TOKEN}/sendMessage" \
   -d chat_id="${CHAT_ID}" \
   -d text="❌ VPS KHÔNG CÓ MẠNG – DỪNG CÀI ĐẶT"
  exit 1
fi

# === Cập nhật hệ thống và cài đặt gói cần thiết ===
apt-get update -y
DEBIAN_FRONTEND=noninteractive apt-get install -y build-essential wget curl

# === Tạo người dùng proxy ===
PROXY_USER="anhtu"
PROXY_PASS="anhtuproxy"

# === Cài đặt 3proxy ===
cd /root
wget https://github.com/z3APA3A/3proxy/archive/refs/tags/0.9.4.tar.gz
tar -xzf 0.9.4.tar.gz
cd 3proxy-0.9.4
make -f Makefile.Linux

# === Cấu hình 3proxy ===
mkdir -p /etc/3proxy
mkdir -p /var/log/3proxy
cp src/3proxy /usr/bin/3proxy

cat <<EOF > /etc/3proxy/3proxy.cfg
daemon
maxconn 200
nscache 65536
timeouts 1 5 30 60 180 1800 15 60
log /var/log/3proxy/3proxy.log D
auth strong
users $PROXY_USER:CL:$PROXY_PASS
allow $PROXY_USER
socks -p23456
EOF

# === Tạo systemd service để tự khởi động lại khi reboot ===
cat <<EOF > /etc/systemd/system/3proxy.service
[Unit]
Description=3Proxy SOCKS5 Service
After=network.target

[Service]
ExecStart=/usr/bin/3proxy /etc/3proxy/3proxy.cfg
Restart=always

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable 3proxy
systemctl start 3proxy

# === Mở cổng tường lửa ===
ufw allow 23456/tcp

# === Gửi thông tin proxy về Telegram ===
IP=$(curl -s ipv4.icanhazip.com)
PORT=23456

curl -s -X POST "https://api.telegram.org/bot$BOT_TOKEN/sendMessage" \
 -d chat_id="$CHAT_ID" \
 -d text="🎯 Proxy Created!
➡️ $IP:$PORT
👤 $PROXY_USER
🔑 $PROXY_PASS

✅ Proxy đã sẵn sàng!"
