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
# Try to get ngrok URL from the container (search by image name)
NGROK_CONTAINER=$(docker ps --filter "ancestor=ngrok/ngrok:latest" --format '{{.Names}}' | head -n 1)
if [ -n "$NGROK_CONTAINER" ]; then
    NGROK_URL=$(docker exec "$NGROK_CONTAINER" wget -qO- http://localhost:4040/api/tunnels 2>/dev/null | jq -r '.tunnels[] | select(.proto == "https") | .public_url' 2>/dev/null)
    if [ -n "$NGROK_URL" ]; then
        echo "  [OK] Active: $NGROK_URL"
    else
        echo "  [WARN] Container running but tunnel URL not found via API"
        # Try alternative: check if we can manually extract from docker logs
        echo "  [INFO] Checking docker logs for tunnel URL..."
        NGROK_URL=$(docker logs "$NGROK_CONTAINER" 2>&1 | grep -oP 'https://[a-z0-9-]+\.ngrok-free\.dev' | tail -1)
        if [ -n "$NGROK_URL" ]; then
            echo "  [OK] Found: $NGROK_URL"
        else
            echo "  [FAIL] Could not retrieve tunnel URL"
            echo ""
            exit 1
        fi
    fi
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
