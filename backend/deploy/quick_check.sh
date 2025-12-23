#!/bin/bash
# Быстрая проверка доступности Synology и backend
# Запустите на VPS

echo "========================================"
echo "Quick Check: Synology & Backend"
echo "========================================"
echo ""

# Проверка VPN
echo "[1/3] VPN tunnel:"
if ip link show tun0 > /dev/null 2>&1; then
    echo "  ✓ VPN active (tun0)"
else
    echo "  ✗ VPN NOT active"
fi
echo ""

# Проверка доступности Synology
echo "[2/3] Synology connectivity (10.8.0.2):"
if timeout 2 bash -c "echo > /dev/tcp/10.8.0.2/22" 2>/dev/null; then
    echo "  ✓ Synology SSH accessible"
else
    echo "  ✗ Synology SSH NOT accessible"
fi
echo ""

# Проверка backend
echo "[3/3] Backend (10.8.0.2:8080):"
if timeout 2 bash -c "echo > /dev/tcp/10.8.0.2/8080" 2>/dev/null; then
    echo "  ✓ Backend is running!"
    echo "  Testing health endpoint..."
    HEALTH=$(curl -s -m 2 http://10.8.0.2:8080/health 2>/dev/null)
    if [ -n "$HEALTH" ]; then
        echo "  ✓ Health: $HEALTH"
    else
        echo "  ⚠ Health endpoint not responding"
    fi
else
    echo "  ✗ Backend is NOT running"
    echo "  → Deploy backend on Synology!"
fi
echo ""

echo "========================================"





