#!/bin/bash

# Script to seed chats via API endpoint
# Usage: ./seed-chats.sh [API_URL] [AUTH_TOKEN]

API_URL=${1:-"http://localhost:5284"}
ENDPOINT="$API_URL/api/admin/seed-chats"
AUTH_TOKEN=${2:-""}

echo "💬 Seeding chats and messages..."
echo "📡 API URL: $ENDPOINT"

if [ -z "$AUTH_TOKEN" ]; then
    echo "⚠️  No auth token provided. Trying without authentication..."
    RESPONSE=$(curl -s -X POST "$ENDPOINT" \
        -H "Content-Type: application/json" \
        -w "\n%{http_code}")
else
    RESPONSE=$(curl -s -X POST "$ENDPOINT" \
        -H "Content-Type: application/json" \
        -H "Authorization: Bearer $AUTH_TOKEN" \
        -w "\n%{http_code}")
fi

HTTP_CODE=$(echo "$RESPONSE" | tail -n1)
BODY=$(echo "$RESPONSE" | sed '$d')

if [ "$HTTP_CODE" -eq 200 ]; then
    echo "✅ Chats and messages seeded successfully!"
    echo "$BODY"
else
    echo "❌ Failed to seed chats. HTTP Status: $HTTP_CODE"
    echo "$BODY"
    exit 1
fi

