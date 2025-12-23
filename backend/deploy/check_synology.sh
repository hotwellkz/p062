#!/bin/bash
# Скрипт для проверки доступности Synology
# Запустите на VPS: bash check_synology.sh

echo "========================================"
echo "Checking Synology connectivity"
echo "========================================"
echo ""

# Проверка VPN туннеля
echo "[1/4] Checking VPN tunnel..."
if ip link show tun0 > /dev/null 2>&1; then
    echo "✓ VPN tunnel (tun0) is active"
    VPN_IP=$(ip addr show tun0 | grep "inet " | awk '{print $2}' | cut -d/ -f1)
    echo "  VPN interface IP: $VPN_IP"
else
    echo "✗ VPN tunnel (tun0) is NOT active"
    echo "  You may need to use direct connection (192.168.100.222)"
fi
echo ""

# Проверка доступности Synology через VPN
echo "[2/4] Checking Synology via VPN (10.8.0.2)..."
if ping -c 2 -W 2 10.8.0.2 > /dev/null 2>&1; then
    echo "✓ Synology is reachable via VPN (10.8.0.2)"
    PING_OK=true
else
    echo "✗ Synology is NOT reachable via VPN (10.8.0.2)"
    PING_OK=false
fi
echo ""

# Проверка порта 8080 на Synology
echo "[3/4] Checking port 8080 on Synology..."
if timeout 3 bash -c "echo > /dev/tcp/10.8.0.2/8080" 2>/dev/null; then
    echo "✓ Port 8080 is open on Synology"
    PORT_OK=true
else
    echo "✗ Port 8080 is closed on Synology"
    echo "  Backend is not running or not accessible"
    PORT_OK=false
fi
echo ""

# Проверка health endpoint
echo "[4/4] Checking health endpoint..."
if [ "$PORT_OK" = true ]; then
    HEALTH=$(curl -s -m 3 http://10.8.0.2:8080/health 2>/dev/null)
    if [ -n "$HEALTH" ]; then
        echo "✓ Health endpoint responds: $HEALTH"
    else
        echo "✗ Health endpoint does not respond"
    fi
else
    echo "⚠ Skipping (port 8080 is closed)"
fi
echo ""

echo "========================================"
echo "Summary:"
echo "========================================"
if [ "$PING_OK" = true ] && [ "$PORT_OK" = true ]; then
    echo "✅ Everything is OK! Backend is running."
elif [ "$PING_OK" = false ]; then
    echo "❌ VPN tunnel is not active or Synology is not connected"
    echo "   Check VPN connection on Synology"
elif [ "$PORT_OK" = false ]; then
    echo "❌ Backend is not running on Synology"
    echo "   You need to deploy backend on Synology"
    echo "   Run: bash /tmp/synology_deploy.sh on Synology"
fi
echo ""





