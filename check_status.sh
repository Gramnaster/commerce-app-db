#!/bin/bash
# ./check_status.sh

echo "Checking Server Status..."
echo ""

# Check Docker Container
echo "Docker Container:"
if docker ps | grep -q commerceapp-commerceappbe; then
    echo "  [OK] Running"
else
    echo "  [FAIL] Not running"
fi
echo ""

# Check ngrok
echo "ngrok Tunnel:"
NGROK_URL=$(curl -s http://localhost:4040/api/tunnels 2>/dev/null | jq -r '.tunnels[] | select(.proto == "https") | .public_url')
if [ -n "$NGROK_URL" ]; then
    echo "  [OK] Active: $NGROK_URL"
else
    echo "  [FAIL] Not running"
    echo ""
    exit 1
fi
echo ""

# Check API Health
echo "API Health:"
STATUS=$(curl -s -o /dev/null -w "%{http_code}" -H "ngrok-skip-browser-warning: true" "$NGROK_URL/up")
if [ "$STATUS" = "200" ]; then
    echo "  [OK] Healthy (Status: $STATUS)"
else
    echo "  [FAIL] Unhealthy (Status: $STATUS)"
fi
echo ""

# Quick endpoint test
echo "Quick Test (Countries):"
RESULT=$(curl -s -H "ngrok-skip-browser-warning: true" "$NGROK_URL/api/v1/countries" | jq -r '.data | length')
if [ -n "$RESULT" ] && [ "$RESULT" -gt 0 ]; then
    echo "  [OK] Working ($RESULT countries)"
else
    echo "  [FAIL] Failed"
fi
echo ""

echo "Status check complete!"
