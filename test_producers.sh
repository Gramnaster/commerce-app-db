#!/bin/bash

# Load environment variables
export $(cat .env | grep -v '^#' | xargs)

echo "========================================="
echo "   Testing Producers CRUD Operations"
echo "========================================="
echo ""

# 1. Login as Management Admin
echo "Step 1: Login as Management Admin..."
LOGIN_RESPONSE=$(curl -s -i -X POST http://localhost:3001/api/v1/admin_users/login \
  -H "Content-Type: application/json" \
  -d '{"admin_user": {"email": "'"${ADMIN_EMAIL}"'", "password": "'"${ADMIN_PASSWORD}"'"}}')

TOKEN=$(echo "$LOGIN_RESPONSE" | grep -i "^authorization:" | awk '{print $2}' | tr -d '\r')

if [ -z "$TOKEN" ]; then
  echo "❌ Failed to get token"
  echo "Response:"
  echo "$LOGIN_RESPONSE"
  exit 1
fi

echo "✅ Token obtained successfully"
echo ""

# 2. GET all producers
echo "========================================="
echo "Step 2: GET /api/v1/producers"
echo "List all existing producers"
echo "========================================="
GET_ALL=$(curl -s -X GET http://localhost:3001/api/v1/producers \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json")
echo "$GET_ALL" | python3 -m json.tool 2>/dev/null || echo "$GET_ALL"
echo ""
echo ""

# 3. GET specific producer (ID 1)
echo "========================================="
echo "Step 3: GET /api/v1/producers/1"
echo "Get details of producer with ID 1"
echo "========================================="
GET_ONE=$(curl -s -X GET http://localhost:3001/api/v1/producers/1 \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json")
echo "$GET_ONE" | python3 -m json.tool 2>/dev/null || echo "$GET_ONE"
echo ""
echo ""

# 4. POST - Create new producer with existing address
echo "========================================="
echo "Step 4: POST /api/v1/producers"
echo "Create new producer with existing address_id"
echo "========================================="
CREATE_WITH_EXISTING=$(curl -s -X POST http://localhost:3001/api/v1/producers \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "producer": {
      "title": "Test Producer Inc.",
      "address_id": 1
    }
  }')
echo "$CREATE_WITH_EXISTING" | python3 -m json.tool 2>/dev/null || echo "$CREATE_WITH_EXISTING"

# Extract the new producer ID
NEW_PRODUCER_ID=$(echo "$CREATE_WITH_EXISTING" | grep -o '"id":[0-9]*' | head -1 | cut -d':' -f2)
echo ""
echo "New Producer ID: $NEW_PRODUCER_ID"
echo ""
echo ""

# 5. POST - Create producer with nested address attributes
echo "========================================="
echo "Step 5: POST /api/v1/producers"
echo "Create new producer with nested address"
echo "========================================="
CREATE_WITH_NESTED=$(curl -s -X POST http://localhost:3001/api/v1/producers \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "producer": {
      "title": "Another Test Producer LLC",
      "address_attributes": {
        "unit_no": "500",
        "street_no": "Silicon Valley Blvd",
        "address_line1": "Tech Park",
        "city": "San Francisco",
        "region": "CA",
        "zipcode": "94105",
        "country_id": 1
      }
    }
  }')
echo "$CREATE_WITH_NESTED" | python3 -m json.tool 2>/dev/null || echo "$CREATE_WITH_NESTED"

# Extract the second new producer ID
NEW_PRODUCER_ID_2=$(echo "$CREATE_WITH_NESTED" | grep -o '"id":[0-9]*' | head -1 | cut -d':' -f2)
echo ""
echo "New Producer ID: $NEW_PRODUCER_ID_2"
echo ""
echo ""

# 6. PATCH - Update producer title only
if [ ! -z "$NEW_PRODUCER_ID" ]; then
  echo "========================================="
  echo "Step 6: PATCH /api/v1/producers/$NEW_PRODUCER_ID"
  echo "Update producer title"
  echo "========================================="
  UPDATE_TITLE=$(curl -s -X PATCH http://localhost:3001/api/v1/producers/$NEW_PRODUCER_ID \
    -H "Authorization: Bearer $TOKEN" \
    -H "Content-Type: application/json" \
    -d '{
      "producer": {
        "title": "Updated Test Producer Inc."
      }
    }')
  echo "$UPDATE_TITLE" | python3 -m json.tool 2>/dev/null || echo "$UPDATE_TITLE"
  echo ""
  echo ""
fi

# 7. PATCH - Update producer with new address_id
if [ ! -z "$NEW_PRODUCER_ID" ]; then
  echo "========================================="
  echo "Step 7: PATCH /api/v1/producers/$NEW_PRODUCER_ID"
  echo "Update producer with different address_id"
  echo "========================================="
  UPDATE_ADDRESS=$(curl -s -X PATCH http://localhost:3001/api/v1/producers/$NEW_PRODUCER_ID \
    -H "Authorization: Bearer $TOKEN" \
    -H "Content-Type: application/json" \
    -d '{
      "producer": {
        "address_id": 2
      }
    }')
  echo "$UPDATE_ADDRESS" | python3 -m json.tool 2>/dev/null || echo "$UPDATE_ADDRESS"
  echo ""
  echo ""
fi

# 8. PATCH - Update nested address attributes
if [ ! -z "$NEW_PRODUCER_ID_2" ]; then
  echo "========================================="
  echo "Step 8: PATCH /api/v1/producers/$NEW_PRODUCER_ID_2"
  echo "Update producer's address details"
  echo "========================================="
  
  # First get the address ID
  GET_PRODUCER=$(curl -s -X GET http://localhost:3001/api/v1/producers/$NEW_PRODUCER_ID_2 \
    -H "Authorization: Bearer $TOKEN" \
    -H "Content-Type: application/json")
  ADDRESS_ID=$(echo "$GET_PRODUCER" | grep -o '"id":[0-9]*' | head -2 | tail -1 | cut -d':' -f2)
  
  UPDATE_NESTED=$(curl -s -X PATCH http://localhost:3001/api/v1/producers/$NEW_PRODUCER_ID_2 \
    -H "Authorization: Bearer $TOKEN" \
    -H "Content-Type: application/json" \
    -d '{
      "producer": {
        "address_attributes": {
          "id": '"$ADDRESS_ID"',
          "city": "Los Angeles",
          "zipcode": "90001"
        }
      }
    }')
  echo "$UPDATE_NESTED" | python3 -m json.tool 2>/dev/null || echo "$UPDATE_NESTED"
  echo ""
  echo ""
fi

# 9. Test validation - Try to create producer without title
echo "========================================="
echo "Step 9: POST /api/v1/producers"
echo "Test validation - create without title (should fail)"
echo "========================================="
VALIDATION_TEST=$(curl -s -X POST http://localhost:3001/api/v1/producers \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "producer": {
      "address_id": 1
    }
  }')
echo "$VALIDATION_TEST" | python3 -m json.tool 2>/dev/null || echo "$VALIDATION_TEST"
echo ""
echo ""

# 10. Test validation - Try to create duplicate title
echo "========================================="
echo "Step 10: POST /api/v1/producers"
echo "Test validation - duplicate title (should fail)"
echo "========================================="
DUPLICATE_TEST=$(curl -s -X POST http://localhost:3001/api/v1/producers \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "producer": {
      "title": "Test Producer Inc.",
      "address_id": 1
    }
  }')
echo "$DUPLICATE_TEST" | python3 -m json.tool 2>/dev/null || echo "$DUPLICATE_TEST"
echo ""
echo ""

# 11. DELETE - Delete first test producer
if [ ! -z "$NEW_PRODUCER_ID" ]; then
  echo "========================================="
  echo "Step 11: DELETE /api/v1/producers/$NEW_PRODUCER_ID"
  echo "Delete first test producer"
  echo "========================================="
  DELETE_1=$(curl -s -X DELETE http://localhost:3001/api/v1/producers/$NEW_PRODUCER_ID \
    -H "Authorization: Bearer $TOKEN" \
    -H "Content-Type: application/json")
  echo "$DELETE_1" | python3 -m json.tool 2>/dev/null || echo "$DELETE_1"
  echo ""
  echo ""
fi

# 12. DELETE - Delete second test producer
if [ ! -z "$NEW_PRODUCER_ID_2" ]; then
  echo "========================================="
  echo "Step 12: DELETE /api/v1/producers/$NEW_PRODUCER_ID_2"
  echo "Delete second test producer"
  echo "========================================="
  DELETE_2=$(curl -s -X DELETE http://localhost:3001/api/v1/producers/$NEW_PRODUCER_ID_2 \
    -H "Authorization: Bearer $TOKEN" \
    -H "Content-Type: application/json")
  echo "$DELETE_2" | python3 -m json.tool 2>/dev/null || echo "$DELETE_2"
  echo ""
  echo ""
fi

# 13. Test authorization - Try with warehouse admin
echo "========================================="
echo "Step 13: Authorization Test"
echo "Try to access with warehouse admin (should fail)"
echo "========================================="
WAREHOUSE_LOGIN=$(curl -s -i -X POST http://localhost:3001/api/v1/admin_users/login \
  -H "Content-Type: application/json" \
  -d '{"admin_user": {"email": "'"${WAREHOUSE_EMAIL}"'", "password": "'"${WAREHOUSE_PASSWORD}"'"}}')

WAREHOUSE_TOKEN=$(echo "$WAREHOUSE_LOGIN" | grep -i "^authorization:" | awk '{print $2}' | tr -d '\r')

if [ ! -z "$WAREHOUSE_TOKEN" ]; then
  echo "Warehouse token obtained"
  AUTH_TEST=$(curl -s -X GET http://localhost:3001/api/v1/producers \
    -H "Authorization: Bearer $WAREHOUSE_TOKEN" \
    -H "Content-Type: application/json")
  echo "$AUTH_TEST" | python3 -m json.tool 2>/dev/null || echo "$AUTH_TEST"
else
  echo "Could not get warehouse token"
fi
echo ""
echo ""

echo "========================================="
echo "   All Tests Completed! ✅"
echo "========================================="
