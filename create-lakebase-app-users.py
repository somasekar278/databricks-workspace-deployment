#!/usr/bin/env python3

"""
Create app_users table in Lakebase PostgreSQL
Uses Service Principal OAuth authentication
"""

import requests
import psycopg2
import os
import sys

def get_oauth_token(host, client_id, client_secret):
    """Get OAuth M2M token for Service Principal"""
    token_url = f"{host}/oidc/v1/token"
    response = requests.post(
        token_url,
        auth=(client_id, client_secret),
        data={"grant_type": "client_credentials", "scope": "all-apis"}
    )
    response.raise_for_status()
    return response.json()["access_token"]

def create_app_users_table(lakebase_host, lakebase_db, sp_uuid, oauth_token, sql_file):
    """Create app_users table in Lakebase using OAuth authentication"""
    
    print(f"🔗 Connecting to Lakebase: {lakebase_host}")
    print(f"   Database: {lakebase_db}")
    print(f"   User: {sp_uuid} (Service Principal)")
    print()
    
    # Connect to Lakebase PostgreSQL
    # Username: Service Principal UUID
    # Password: OAuth token
    try:
        conn = psycopg2.connect(
            host=lakebase_host,
            port=5432,
            database=lakebase_db,
            user=sp_uuid,
            password=oauth_token,
            sslmode='require'
        )
        
        print("✅ Connected to Lakebase")
        
        # Read SQL file
        with open(sql_file, 'r') as f:
            sql_script = f.read()
        
        # Execute SQL
        cursor = conn.cursor()
        
        print("\n📝 Creating app_users table...")
        cursor.execute(sql_script)
        conn.commit()
        
        print("✅ app_users table created successfully")
        
        # Verify table exists
        cursor.execute("""
            SELECT table_name, table_schema 
            FROM information_schema.tables 
            WHERE table_name = 'app_users'
        """)
        
        result = cursor.fetchone()
        if result:
            print(f"\n✅ Verified: app_users table exists in schema '{result[1]}'")
            
            # Show table structure
            cursor.execute("""
                SELECT column_name, data_type, is_nullable, column_default
                FROM information_schema.columns
                WHERE table_name = 'app_users'
                ORDER BY ordinal_position
            """)
            
            columns = cursor.fetchall()
            print(f"\n📊 Table structure ({len(columns)} columns):")
            for col in columns:
                nullable = "NULL" if col[2] == 'YES' else "NOT NULL"
                default = f" DEFAULT {col[3]}" if col[3] else ""
                print(f"   - {col[0]}: {col[1]} {nullable}{default}")
        else:
            print("\n⚠️  Warning: Could not verify table creation")
        
        cursor.close()
        conn.close()
        
        return True
        
    except psycopg2.Error as e:
        print(f"\n❌ PostgreSQL Error: {e}")
        return False
    except Exception as e:
        print(f"\n❌ Error: {e}")
        return False

def main():
    # Configuration
    workspace_url = os.environ.get("DATABRICKS_HOST", "https://one-env-som-workspace.cloud.databricks.com")
    client_id = os.environ.get("DATABRICKS_CLIENT_ID")
    client_secret = os.environ.get("DATABRICKS_CLIENT_SECRET")
    
    lakebase_host = "instance-bf1b47b2-e166-4fbd-b6f3-7ba3fe50921a.database.cloud.databricks.com"
    lakebase_db = "fraud_detection_db"
    sql_file = "sql/lakebase_app_users.sql"
    
    if not all([client_id, client_secret]):
        print("❌ Error: DATABRICKS_CLIENT_ID and DATABRICKS_CLIENT_SECRET must be set")
        sys.exit(1)
    
    print("════════════════════════════════════════════════════════════════")
    print("🔐 Creating app_users Table in Lakebase")
    print("════════════════════════════════════════════════════════════════")
    print()
    
    # Get OAuth token
    print("🔐 Getting OAuth token...")
    try:
        token = get_oauth_token(workspace_url, client_id, client_secret)
        print("✅ OAuth token obtained")
        print()
    except Exception as e:
        print(f"❌ Failed to get OAuth token: {e}")
        sys.exit(1)
    
    # Create table
    success = create_app_users_table(
        lakebase_host,
        lakebase_db,
        client_id,  # SP UUID is the username
        token,
        sql_file
    )
    
    print()
    print("════════════════════════════════════════════════════════════════")
    if success:
        print("✅ app_users table created successfully!")
        print()
        print("💡 Next steps:")
        print("   1. The table starts empty")
        print("   2. Users will be created via the fraud app admin settings")
        print("   3. Or seed test users manually if needed")
    else:
        print("❌ Failed to create app_users table")
        sys.exit(1)
    print("════════════════════════════════════════════════════════════════")

if __name__ == "__main__":
    main()

