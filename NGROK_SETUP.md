# ngrok Setup Instructions

## Running ngrok for Both Services

You need **two separate ngrok tunnels** running simultaneously:

### 1. Rails API (Port 3001)
```bash
ngrok http 3001
```

### 2. Dokploy Dashboard (Port 3000)
```bash
ngrok http 3000
```

## Running Both in Background

### Option A: Separate Terminal Windows
- Terminal 1: `ngrok http 3001`
- Terminal 2: `ngrok http 3000`

### Option B: Background Processes
```bash
# Start API tunnel
ngrok http 3001 --log=stdout > /tmp/ngrok_api.log 2>&1 &

# Start Dokploy tunnel
ngrok http 3000 --log=stdout > /tmp/ngrok_dokploy.log 2>&1 &
```

## Check Active Tunnels

### View ngrok Dashboard
```bash
# Open in browser
http://localhost:4040
```

### Get URLs via API
```bash
curl -s http://localhost:4040/api/tunnels | jq -r '.tunnels[] | "\(.proto)://\(.public_url) -> \(.config.addr)"'
```

## Current Active Tunnel

- **API**: https://plumlike-ricarda-extravagantly.ngrok-free.dev -> http://localhost:3001

## Notes

- **Free tier limitation**: Can only run 1 tunnel at a time without paid plan
- **For multiple tunnels**: Need ngrok Pro ($10/month) or higher
- **Alternative**: Use public IP (180.191.170.229) with proper port forwarding instead of ngrok for one service
