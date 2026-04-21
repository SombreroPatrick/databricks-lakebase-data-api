#!/usr/bin/env bash
# ============================================================================
# Databricks Lakebase Data API - Bash Client Example
# ============================================================================
# Demonstrates how to query the Data API using curl.
#
# Prerequisites:
#   - curl
#   - jq (for pretty-printing JSON)
#
# Environment Variables:
#   CLIENT_ID       - Service principal client ID
#   CLIENT_SECRET   - Service principal client secret
#   WORKSPACE_URL   - Databricks workspace URL
#   API_URL         - Data API endpoint URL
#
# Usage:
#   export CLIENT_ID="your-client-id"
#   export CLIENT_SECRET="your-client-secret"
#   export WORKSPACE_URL="https://your-workspace.cloud.databricks.com"
#   export API_URL="https://ep-example.../rest/databricks_postgres"
#   bash bash-client.sh
# ============================================================================

set -euo pipefail

# Check required environment variables
if [[ -z "${CLIENT_ID:-}" ]] || [[ -z "${CLIENT_SECRET:-}" ]] || [[ -z "${WORKSPACE_URL:-}" ]] || [[ -z "${API_URL:-}" ]]; then
    echo "ERROR: Missing required environment variables"
    echo "Required: CLIENT_ID, CLIENT_SECRET, WORKSPACE_URL, API_URL"
    exit 1
fi

echo "========================================================================"
echo "Databricks Lakebase Data API - Bash Client Demo"
echo "========================================================================"

# Step 1: Get OAuth token
echo ""
echo "1. Authenticating with OAuth..."
TOKEN=$(curl -s -X POST "${WORKSPACE_URL}/oidc/v1/token" \
  -u "${CLIENT_ID}:${CLIENT_SECRET}" \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "grant_type=client_credentials&scope=all-apis" \
  | jq -r '.access_token')

if [[ -z "$TOKEN" ]] || [[ "$TOKEN" == "null" ]]; then
    echo "ERROR: Failed to get OAuth token"
    exit 1
fi

echo "✓ Authentication successful"

# Helper function to query API
query_api() {
    local endpoint="$1"
    curl -s -H "Authorization: Bearer $TOKEN" "${API_URL}${endpoint}"
}

# Step 2: Get all products
echo ""
echo "2. Get all products (limit 5):"
query_api "/public/products?limit=5" | jq -r '.[] | "  \(.product_id): \(.name) - $\(.price)"'

# Step 3: Filter by category
echo ""
echo "3. Get products in category 1 (Electronics):"
query_api "/public/products?category_id=eq.1&order=price.desc" | jq -r '.[] | "  \(.name): $\(.price)"'

# Step 4: Search by name
echo ""
echo "4. Search products containing 'laptop' (case-insensitive):"
query_api "/public/products?name=ilike.*laptop*" | jq -r '.[] | "  \(.name): $\(.price)"'

# Step 5: Filter by price
echo ""
echo "5. Get expensive products (price >= 500):"
query_api "/public/products?price=gte.500&order=price.desc" | jq -r '.[] | "  \(.name): $\(.price)"'

# Step 6: Pagination
echo ""
echo "6. Get products - page 1 (limit 3, offset 0):"
query_api "/public/products?limit=3&offset=0&order=name.asc" | jq -r '.[] | "  \(.name)"'

echo ""
echo "   Get products - page 2 (limit 3, offset 3):"
query_api "/public/products?limit=3&offset=3&order=name.asc" | jq -r '.[] | "  \(.name)"'

# Step 7: Select specific columns
echo ""
echo "7. Select specific columns (id, name, price):"
query_api "/public/products?select=product_id,name,price&limit=5" | jq '.'

# Step 8: Join with categories
echo ""
echo "8. Join products with categories:"
query_api "/public/products?select=name,price,categories(name)&limit=3" | jq '.'

# Step 9: Multiple filters
echo ""
echo "9. Multiple filters (category=1, price>=500, in_stock=true):"
query_api "/public/products?category_id=eq.1&price=gte.500&in_stock=eq.true" | jq -r '.[] | "  \(.name): $\(.price)"'

# Step 10: Get all categories
echo ""
echo "10. Get all categories:"
query_api "/public/categories" | jq -r '.[] | "  \(.category_id): \(.name) - \(.description)"'

echo ""
echo "========================================================================"
echo "Demo completed!"
