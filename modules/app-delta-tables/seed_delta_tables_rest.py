#!/usr/bin/env python3
"""
Seed Unity Catalog Delta tables using Databricks REST API.
Reliable for headless execution in Terraform provisioners.
"""

import sys
import os
import re
import time
import requests
import json

def get_oauth_token(host, client_id, client_secret):
    """Get OAuth M2M token from Databricks."""
    print("🔐 Obtaining OAuth token...")
    
    token_url = f"{host}/oidc/v1/token"
    data = {
        "grant_type": "client_credentials",
        "scope": "all-apis"
    }
    
    try:
        response = requests.post(
            token_url,
            auth=(client_id, client_secret),
            data=data,
            timeout=30
        )
        response.raise_for_status()
        token_data = response.json()
        print("✅ OAuth token obtained")
        return token_data['access_token']
    except Exception as e:
        print(f"❌ Failed to get OAuth token: {e}")
        sys.exit(1)

def poll_statement_status(host, token, statement_id, max_wait_seconds=120):
    """Poll statement status until completion."""
    api_url = f"{host}/api/2.0/sql/statements/{statement_id}"
    headers = {
        "Authorization": f"Bearer {token}"
    }
    
    start_time = time.time()
    while True:
        elapsed = time.time() - start_time
        if elapsed > max_wait_seconds:
            print(f"❌ Timeout after {elapsed:.0f}s")
            return False
        
        try:
            response = requests.get(api_url, headers=headers, timeout=30)
            response.raise_for_status()
            result = response.json()
            
            status = result.get('status', {}).get('state', 'UNKNOWN')
            
            if status == 'SUCCEEDED':
                print(f"✅ Success (took {elapsed:.1f}s)")
                return True
            elif status in ['FAILED', 'CANCELED', 'CLOSED']:
                error_info = result.get('status', {}).get('error', {})
                error_msg = error_info.get('message', f'Statement {status}')
                print(f"❌ {error_msg}")
                return False
            elif status in ['PENDING', 'RUNNING']:
                # Still executing, wait and poll again
                time.sleep(2)
                continue
            else:
                print(f"❌ Unknown status: {status}")
                return False
                
        except Exception as e:
            print(f"❌ Error polling status: {e}")
            return False

def execute_sql_statement(host, token, warehouse_id, statement, timeout_seconds=120):
    """Execute SQL statement using SQL Statement Execution API."""
    api_url = f"{host}/api/2.0/sql/statements"
    headers = {
        "Authorization": f"Bearer {token}",
        "Content-Type": "application/json"
    }
    payload = {
        "statement": statement,
        "warehouse_id": warehouse_id,
        "wait_timeout": "0s"  # Don't wait, return immediately
    }
    
    try:
        # Submit statement
        response = requests.post(
            api_url,
            headers=headers,
            json=payload,
            timeout=30
        )
        
        if response.status_code != 200:
            error_details = response.text
            print(f"❌ HTTP {response.status_code}: {error_details}")
            return False
            
        result = response.json()
        statement_id = result.get('statement_id')
        
        if not statement_id:
            print(f"❌ No statement_id in response")
            return False
        
        # Poll for completion
        return poll_statement_status(host, token, statement_id, timeout_seconds)
            
    except requests.Timeout:
        print(f"❌ Timeout submitting statement")
        return False
    except Exception as e:
        print(f"❌ Error: {e}")
        return False

def main():
    if len(sys.argv) < 4:
        print("Usage: seed_delta_tables_rest.py <workspace_url> <warehouse_id> <sql_file>")
        sys.exit(1)
    
    workspace_url = sys.argv[1]
    warehouse_id = sys.argv[2]
    sql_file = sys.argv[3]
    
    # Get credentials from environment
    client_id = os.environ.get('DATABRICKS_CLIENT_ID')
    client_secret = os.environ.get('DATABRICKS_CLIENT_SECRET')
    
    if not client_id or not client_secret:
        print("❌ Missing DATABRICKS_CLIENT_ID or DATABRICKS_CLIENT_SECRET")
        sys.exit(1)
    
    # Normalize host URL
    host = workspace_url.rstrip('/')
    if not host.startswith('http'):
        host = f"https://{host}"
    
    print(f"🔗 Connecting to {host}")
    print(f"   Warehouse ID: {warehouse_id}")
    print(f"   Service Principal: {client_id[:20]}...")
    
    # Get OAuth token
    token = get_oauth_token(host, client_id, client_secret)
    
    print(f"\n🌱 Seeding Delta tables from {sql_file}...\n")
    
    # Read and parse SQL file
    with open(sql_file, 'r') as f:
        sql_content = f.read()
    
    # Split by semicolon, filter INSERT statements
    statements = [stmt.strip() for stmt in sql_content.split(';') if stmt.strip()]
    insert_statements = [stmt for stmt in statements if 'INSERT INTO' in stmt.upper()]
    
    print(f"Found {len(insert_statements)} INSERT statements\n")
    
    success_count = 0
    for i, stmt in enumerate(insert_statements, 1):
        # Remove comments
        clean_stmt = re.sub(r'--.*$', '', stmt, flags=re.MULTILINE)
        # Remove USE statements
        clean_stmt = re.sub(r'USE\s+(CATALOG|SCHEMA)\s+[^;]+;?', '', clean_stmt, flags=re.IGNORECASE)
        # Normalize whitespace
        clean_stmt = ' '.join(clean_stmt.split())
        
        if clean_stmt and 'INSERT INTO' in clean_stmt.upper():
            # Extract table name for logging
            table_match = re.search(r'INSERT\s+INTO\s+`?(\w+)`?', clean_stmt, re.IGNORECASE)
            table_name = table_match.group(1) if table_match else f"table_{i}"
            
            # Add fully qualified table name
            qualified_stmt = re.sub(
                r'(INSERT\s+INTO\s+)`?(\w+)`?',
                r'\1`afc-mvp`.`fraud-investigation`.`\2`',
                clean_stmt,
                flags=re.IGNORECASE
            )
            
            print(f"[{i}/{len(insert_statements)}] Seeding table: {table_name}")
            if execute_sql_statement(host, token, warehouse_id, qualified_stmt + ';'):
                success_count += 1
            else:
                print(f"⚠️  Failed to seed {table_name}, continuing...")
    
    print(f"\n{'='*60}")
    print(f"✅ Seeded {success_count}/{len(insert_statements)} tables successfully")
    
    if success_count < len(insert_statements):
        print(f"⚠️  {len(insert_statements) - success_count} tables failed")
        sys.exit(1)
    
    print("🎉 All tables seeded successfully!")

if __name__ == "__main__":
    main()

