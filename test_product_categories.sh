#!/bin/bash

# Load environment variables
export $(cat .env | grep -v '^#' | xargs)

echo "=== Testing Product Categories CRUD ==="
echo ""

# 1. Login as Management Admin
echo "1. Login as Management Admin..."
LOGIN_RESPONSE=$(curl -s -i -X POST http://localhost:3001/api/v1/admin_users/login \
  -H "Content-Type: application/json" \
  -d '{"admin_user": {"email": "'"${ADMIN_EMAIL}"'", "password": "'"${ADMIN_PASSWORD}"'"}}')

TOKEN=$(echo "$LOGIN_RESPONSE" | grep -i "^authorization:" | awk '{print $2}' | tr -d '\r')

if [ -z "$TOKEN" ]; then
  echo "❌ Failed to get token"
  exit 1
fi

echo "✅ Token obtained"
echo ""

# 2. GET all product categories
echo "2. GET /api/v1/product_categories - List all categories"
curl -s -X GET http://localhost:3001/api/v1/product_categories \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" | head -c 500
echo ""
echo ""

# 3. POST - Create a new category
echo "3. POST /api/v1/product_categories - Create new category"
CREATE_RESPONSE=$(curl -s -X POST http://localhost:3001/api/v1/product_categories \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"product_category": {"title": "test-category-'$(date +%s)'"}}')
echo "$CREATE_RESPONSE"
CATEGORY_ID=$(echo "$CREATE_RESPONSE" | grep -o '"id":[0-9]*' | head -1 | cut -d':' -f2)
echo ""
echo ""

# 4. GET single category
echo "4. GET /api/v1/product_categories/$CATEGORY_ID - Show single category"
curl -s -X GET http://localhost:3001/api/v1/product_categories/$CATEGORY_ID \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json"
echo ""
echo ""

# 5. PATCH - Update category
echo "5. PATCH /api/v1/product_categories/$CATEGORY_ID - Update category"
curl -s -X PATCH http://localhost:3001/api/v1/product_categories/$CATEGORY_ID \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"product_category": {"title": "updated-test-category"}}'
echo ""
echo ""

# 6. DELETE category
echo "6. DELETE /api/v1/product_categories/$CATEGORY_ID - Delete category"
curl -s -X DELETE http://localhost:3001/api/v1/product_categories/$CATEGORY_ID \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json"
echo ""
echo ""

echo "=== All tests completed! ==="
