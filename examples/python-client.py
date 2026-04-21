#!/usr/bin/env python3
"""
Databricks Lakebase Data API - Python Client Example
====================================================
Demonstrates how to consume the Lakebase Data API from Python.

Prerequisites:
  pip install requests

Environment Variables:
  CLIENT_ID       - Service principal client ID
  CLIENT_SECRET   - Service principal client secret
  WORKSPACE_URL   - Databricks workspace URL
  API_URL         - Data API endpoint URL

Usage:
  export CLIENT_ID="your-client-id"
  export CLIENT_SECRET="your-client-secret"
  export WORKSPACE_URL="https://your-workspace.cloud.databricks.com"
  export API_URL="https://ep-example.../rest/databricks_postgres"
  python python-client.py
"""

import os
import sys
import json
import requests
from typing import Optional, Dict, List


def get_oauth_token(workspace_url: str, client_id: str, client_secret: str) -> str:
    """Get OAuth token using service principal credentials."""
    response = requests.post(
        f"{workspace_url}/oidc/v1/token",
        auth=(client_id, client_secret),
        headers={"Content-Type": "application/x-www-form-urlencoded"},
        data="grant_type=client_credentials&scope=all-apis"
    )
    response.raise_for_status()
    return response.json()["access_token"]


class DataAPIClient:
    """Client for Databricks Lakebase Data API."""
    
    def __init__(self, api_url: str, token: str, schema: str = "public"):
        self.base_url = f"{api_url.rstrip('/')}/{schema}"
        self.headers = {
            "Authorization": f"Bearer {token}",
            "Content-Type": "application/json"
        }
    
    def query(self, table: str, params: Optional[Dict] = None) -> List[Dict]:
        """
        Execute a query against a table.
        
        Args:
            table: Table name
            params: Query parameters (filters, ordering, etc.)
        
        Returns:
            List of records as dictionaries
        
        Examples:
            # Get all records
            client.query("products")
            
            # Filter by field
            client.query("products", {"category_id": "eq.1"})
            
            # Sort and limit
            client.query("products", {
                "order": "price.desc",
                "limit": 10
            })
        """
        url = f"{self.base_url}/{table}"
        response = requests.get(url, headers=self.headers, params=params or {})
        response.raise_for_status()
        return response.json()
    
    def get_by_id(self, table: str, id_column: str, id_value: any) -> List[Dict]:
        """Get record(s) by ID."""
        return self.query(table, {id_column: f"eq.{id_value}"})
    
    def search(self, table: str, column: str, pattern: str) -> List[Dict]:
        """Case-insensitive search."""
        return self.query(table, {column: f"ilike.*{pattern}*"})
    
    def filter_range(self, table: str, column: str, min_val: any, max_val: any) -> List[Dict]:
        """Filter by range."""
        return self.query(table, {
            column: f"gte.{min_val}",
            f"{column}.lte": max_val
        })


def main():
    """Demo: Query products and categories."""
    
    # Get configuration from environment
    client_id = os.getenv("CLIENT_ID")
    client_secret = os.getenv("CLIENT_SECRET")
    workspace_url = os.getenv("WORKSPACE_URL")
    api_url = os.getenv("API_URL")
    
    if not all([client_id, client_secret, workspace_url, api_url]):
        print("ERROR: Missing required environment variables")
        print("Required: CLIENT_ID, CLIENT_SECRET, WORKSPACE_URL, API_URL")
        sys.exit(1)
    
    print("=" * 70)
    print("Databricks Lakebase Data API - Python Client Demo")
    print("=" * 70)
    
    # Authenticate
    print("\n1. Authenticating...")
    token = get_oauth_token(workspace_url, client_id, client_secret)
    print("✓ Authentication successful")
    
    # Create client
    client = DataAPIClient(api_url, token)
    
    # Query examples
    print("\n2. Get all products:")
    products = client.query("products", {"limit": 5})
    for p in products:
        print(f"  {p['product_id']}: {p['name']} - ${p['price']}")
    
    print("\n3. Filter by category:")
    electronics = client.query("products", {
        "category_id": "eq.1",
        "order": "price.desc"
    })
    for p in electronics:
        print(f"  {p['name']}: ${p['price']}")
    
    print("\n4. Search products by name:")
    laptops = client.search("products", "name", "laptop")
    for p in laptops:
        print(f"  {p['name']}: ${p['price']}")
    
    print("\n5. Get expensive products (> $500):")
    expensive = client.query("products", {
        "price": "gte.500",
        "order": "price.desc"
    })
    for p in expensive:
        print(f"  {p['name']}: ${p['price']}")
    
    print("\n6. Join products with categories:")
    joined = client.query("products", {
        "select": "product_id,name,price,categories(name)",
        "limit": 5
    })
    print(json.dumps(joined, indent=2))
    
    print("\n" + "=" * 70)
    print("Demo completed!")


if __name__ == "__main__":
    main()
