#!/bin/bash
# Скрипт для проверки настройки VPS и доступности Synology

echo "========================================"
echo "Checking VPS setup and Synology connectivity"
echo "========================================"
echo ""

# 1. Проверка VPN туннеля
echo "[1/5] Checking VPN tunnel..."
if ip link show tun0 > /dev/null 2>&1; then
    echo "✓ VPN tunnel (tun0) is active"
    VPN_IP=$(ip addr show tun0 | grep "inet " | awk '{print $2}' | cut -d/ -f1)
    echo "  VPN interface IP: $VPN_IP"
else
    echo "✗ VPN tunnel (tun0) is NOT active"
    echo "  You may need to use direct connection to Synology (192.168.100.222)"
fi
echo ""

# 2. Проверка доступности Synology через VPN
echo "[2/5] Checking Synology via VPN (10.8.0.2)..."
if ping -c 2 -W 2 10.8.0.2 > /dev/null 2>&1; then
    echo "✓ Synology is reachable via VPN (10.8.0.2)"
else
    echo "✗ Synology is NOT reachable via VPN (10.8.0.2)"
    echo "  VPN tunnel may not be active or Synology is not connected"
fi
echo ""

# 3. Проверка правил iptables
echo "[3/5] Checking iptables rules..."
if iptables -t nat -L PREROUTING -n | grep -q "5000.*10.8.0.2:8080"; then
    echo "✓ Port forwarding rule for 5000->8080 exists"
else
    echo "✗ Port forwarding rule for 5000->8080 NOT found"
fi
echo ""

# 4. Проверка доступности backend на Synology
echo "[4/5] Checking backend on Synology (10.8.0.2:8080)..."
if timeout 3 bash -c "echo > /dev/tcp/10.8.0.2/8080" 2>/dev/null; then
    echo "✓ Backend is running on Synology (10.8.0.2:8080)"
    echo "  Testing health endpoint..."
    curl -s -m 3 http://10.8.0.2:8080/health || echo "  Health endpoint not responding"
else
    echo "✗ Backend is NOT running on Synology (10.8.0.2:8080)"
    echo "  You need to deploy backend on Synology first"
fi
echo ""

# 5. Проверка публичного доступа
echo "[5/5] Checking public access (159.255.37.158:5000)..."
if timeout 3 bash -c "echo > /dev/tcp/159.255.37.158/5000" 2>/dev/null; then
    echo "✓ Port 5000 is open on VPS"
    echo "  Testing health endpoint..."
    curl -s -m 3 http://159.255.37.158:5000/health || echo "  Health endpoint not responding (backend may not be running)"
else
    echo "✗ Port 5000 is NOT accessible on VPS"
    echo "  Check firewall rules on VPS"
fi
echo ""

echo "========================================"
echo "Summary:"
echo "========================================"
echo "If backend is not accessible, you need to:"
echo "1. Deploy backend on Synology (run synology_deploy.sh)"
echo "2. Ensure VPN tunnel is active"
echo "3. Check that backend is running on port 8080 on Synology"
echo ""





