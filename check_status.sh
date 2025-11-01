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

# Check ngrok - Multiple detection methods
echo "ngrok Tunnel:"
NGROK_URL=""

# Method 1: Check for ngrok container by image name
NGROK_CONTAINER=$(docker ps --filter "ancestor=ngrok/ngrok:latest" --format '{{.Names}}' 2>/dev/null | head -n 1)
if [ -z "$NGROK_CONTAINER" ]; then
    # Try alternative image names
    NGROK_CONTAINER=$(docker ps --format '{{.Names}}\t{{.Image}}' 2>/dev/null | grep -i ngrok | awk '{print $1}' | head -n 1)
fi

if [ -n "$NGROK_CONTAINER" ]; then
    echo "  [INFO] Found ngrok container: $NGROK_CONTAINER"
    
    # Try API endpoint
    NGROK_URL=$(docker exec "$NGROK_CONTAINER" wget -qO- http://localhost:4040/api/tunnels 2>/dev/null | jq -r '.tunnels[] | select(.proto == "https") | .public_url' 2>/dev/null)
    
    if [ -z "$NGROK_URL" ]; then
        # Try curl instead of wget
        NGROK_URL=$(docker exec "$NGROK_CONTAINER" curl -s http://localhost:4040/api/tunnels 2>/dev/null | jq -r '.tunnels[] | select(.proto == "https") | .public_url' 2>/dev/null)
    fi
    
    if [ -z "$NGROK_URL" ]; then
        # Try docker logs
        echo "  [INFO] Checking docker logs..."
        NGROK_URL=$(docker logs "$NGROK_CONTAINER" 2>&1 | grep -oP 'https://[a-z0-9-]+\.ngrok[^.]*\.(?:dev|io|app)' | tail -1)
    fi
fi

# Method 2: Check for ngrok running on host
if [ -z "$NGROK_URL" ] && command -v ngrok &> /dev/null; then
    echo "  [INFO] Checking local ngrok installation..."
    NGROK_URL=$(curl -s http://localhost:4040/api/tunnels 2>/dev/null | jq -r '.tunnels[] | select(.proto == "https") | .public_url' 2>/dev/null)
fi

# Method 3: Check common ngrok ports
if [ -z "$NGROK_URL" ]; then
    echo "  [INFO] Scanning common ports..."
    for PORT in 4040 4041 4042 4043; do
        URL=$(curl -s "http://localhost:$PORT/api/tunnels" 2>/dev/null | jq -r '.tunnels[] | select(.proto == "https") | .public_url' 2>/dev/null)
        if [ -n "$URL" ]; then
            NGROK_URL="$URL"
            echo "  [INFO] Found tunnel on port $PORT"
            break
        fi
    done
fi

# Method 4: Check environment file for existing tunnel URL
if [ -z "$NGROK_URL" ] && [ -f ".env" ]; then
    echo "  [INFO] Checking .env file..."
    NGROK_URL=$(grep -oP '(?<=VITE_API_URL=|API_URL=|NGROK_URL=)https://[a-z0-9-]+\.ngrok[^.]*\.(?:dev|io|app)[^\s]*' .env 2>/dev/null | head -1 | sed 's|/api/v1||')
fi

# Method 5: Check if Dokploy or production URL is in use
if [ -z "$NGROK_URL" ] && [ -f ".env" ]; then
    echo "  [INFO] Checking for production/remote URLs..."
    REMOTE_URL=$(grep -oP '(?<=VITE_API_URL=|API_URL=)https://[^\s]+' .env 2>/dev/null | head -1 | sed 's|/api/v1||')
    if [ -n "$REMOTE_URL" ] && [[ ! "$REMOTE_URL" =~ localhost|127.0.0.1 ]]; then
        NGROK_URL="$REMOTE_URL"
        echo "  [INFO] Using remote URL (not ngrok)"
    fi
fi

# Method 6: Try to detect tunnel by inspecting container environment
if [ -z "$NGROK_URL" ] && [ -n "$NGROK_CONTAINER" ]; then
    echo "  [INFO] Inspecting container configuration..."
    # Get the forwarding information from ngrok
    NGROK_URL=$(docker exec "$NGROK_CONTAINER" sh -c 'if command -v curl >/dev/null 2>&1; then curl -s http://127.0.0.1:4040/api/tunnels | grep -oP "\"public_url\":\"https://[^\"]+\"" | head -1 | cut -d\" -f4; fi' 2>/dev/null)
fi

# Fallback: Use localhost if Docker is running and no tunnel detected
if [ -z "$NGROK_URL" ]; then
    if docker ps | grep -q commerceapp-commerceappbe; then
        echo "  [INFO] No tunnel found, checking localhost..."
        # Try to find the port from docker (improved regex)
        LOCAL_PORT=$(docker ps | grep commerceapp-commerceappbe | grep -oP '0\.0\.0\.0:\K[0-9]+(?=->)' | head -1)
        if [ -z "$LOCAL_PORT" ]; then
            # Try common ports
            for PORT in 3000 3001 3002 3003; do
                if curl -s -o /dev/null -w "%{http_code}" "http://localhost:$PORT/up" 2>/dev/null | grep -q "200"; then
                    LOCAL_PORT="$PORT"
                    break
                fi
            done
        fi
        if [ -n "$LOCAL_PORT" ]; then
            NGROK_URL="http://localhost:$LOCAL_PORT"
            echo "  [INFO] Using localhost:$LOCAL_PORT"
        fi
    fi
fi

# Display result
if [ -n "$NGROK_URL" ]; then
    echo "  [OK] Active: $NGROK_URL"
else
    echo "  [WARN] No tunnel detected"
    echo "  [INFO] You may be using localhost or a different tunneling solution"
    echo ""
    echo "If you have a tunnel running, update VITE_API_URL in .env"
    echo ""
fi
echo ""

# Check API Health (only if we have a URL)
if [ -n "$NGROK_URL" ]; then
    echo "API Health:"
    STATUS=$(curl -s -o /dev/null -w "%{http_code}" -H "ngrok-skip-browser-warning: true" "$NGROK_URL/up" 2>/dev/null)
    if [ "$STATUS" = "200" ]; then
        echo "  [OK] Healthy (Status: $STATUS)"
    elif [ -z "$STATUS" ]; then
        echo "  [WARN] Could not connect"
    else
        echo "  [FAIL] Unhealthy (Status: $STATUS)"
    fi
    echo ""

    # Quick endpoint test
    echo "Quick Test (Countries):"
    RESULT=$(curl -s -H "ngrok-skip-browser-warning: true" "$NGROK_URL/api/v1/countries" 2>/dev/null | jq -r '.data | length' 2>/dev/null)
    if [ -n "$RESULT" ] && [ "$RESULT" -gt 0 ]; then
        echo "  [OK] Working ($RESULT countries)"
    else
        echo "  [WARN] Could not fetch data (may need authentication)"
    fi
    echo ""
else
    echo "Skipping API health check (no URL detected)"
    echo ""
    echo "Tip: If running locally, try: http://localhost:3003"
    echo ""
fi

echo "Status check complete!"
