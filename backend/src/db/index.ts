import { Pool } from 'pg';
import dotenv from 'dotenv';
import fs from 'fs';
import path from 'path';

dotenv.config();

const pool = new Pool(
  process.env.DATABASE_URL
    ? {
      connectionString: process.env.DATABASE_URL,
      ssl: { rejectUnauthorized: false }
    }
    : {
      user: process.env.DB_USER || 'postgres',
      host: process.env.DB_HOST || 'localhost',
      database: process.env.DB_NAME || 'vasihat_nama',
      password: process.env.DB_PASSWORD || 'password',
      port: parseInt(process.env.DB_PORT || '5432'),
    }
);

pool.on('error', (err) => {
  console.error('Unexpected error on idle client', err);
  process.exit(-1);
});


export const initDb = async () => {
  const client = await pool.connect();
  try {
    const schema = `
-- 1. Users Table
CREATE TABLE IF NOT EXISTS users (
  id SERIAL PRIMARY KEY,
  firebase_uid VARCHAR(128) UNIQUE, 
  mobile_number VARCHAR(15) UNIQUE NOT NULL, 
  email VARCHAR(255) UNIQUE, 
  name VARCHAR(255), 
  public_key TEXT, 
  encrypted_private_key TEXT, 
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 2. Folders Table
CREATE TABLE IF NOT EXISTS folders (
  id SERIAL PRIMARY KEY,
  user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
  name VARCHAR(255) NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 3. Files Table
CREATE TABLE IF NOT EXISTS files (
  id SERIAL PRIMARY KEY,
  user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
  folder_id INTEGER REFERENCES folders(id),
  file_name VARCHAR(255) NOT NULL,
  storage_path VARCHAR(512) NOT NULL,
  file_size BIGINT,
  mime_type VARCHAR(100),
  encrypted_file_key TEXT NOT NULL, 
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 4. Vault Items Table (for notes, passwords, credit cards, etc.)
CREATE TABLE IF NOT EXISTS vault_items (
  id SERIAL PRIMARY KEY,
  user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
  folder_id INTEGER REFERENCES folders(id) ON DELETE CASCADE,
  item_type VARCHAR(50) NOT NULL, -- 'note', 'password', 'credit_card', 'file'
  title VARCHAR(255) NOT NULL,
  encrypted_data TEXT NOT NULL, -- JSON encrypted data containing item-specific fields
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);
CREATE INDEX IF NOT EXISTS idx_vault_items_user_folder ON vault_items (user_id, folder_id);
CREATE INDEX IF NOT EXISTS idx_vault_items_type ON vault_items (item_type);

-- 5. Nominees Table
CREATE TABLE IF NOT EXISTS nominees (
  id SERIAL PRIMARY KEY,
  user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
  name VARCHAR(255) NOT NULL,
  email VARCHAR(255) NOT NULL,
  relationship VARCHAR(100),
  nominee_public_key TEXT, 
  access_granted BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 6. File Permissions
CREATE TABLE IF NOT EXISTS file_permissions (
  id SERIAL PRIMARY KEY,
  file_id INTEGER REFERENCES files(id) ON DELETE CASCADE,
  nominee_id INTEGER REFERENCES nominees(id) ON DELETE CASCADE,
  encrypted_file_key_for_nominee TEXT NOT NULL,
  created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
  UNIQUE(file_id, nominee_id)
);

-- 7. OTP Verifications
CREATE TABLE IF NOT EXISTS otp_verifications (
    id SERIAL PRIMARY KEY,
    mobile VARCHAR(15) NOT NULL,
    otp_hash VARCHAR(255) NOT NULL,
    purpose VARCHAR(50) NOT NULL DEFAULT 'login',
    attempts INT DEFAULT 0,
    expires_at TIMESTAMP WITH TIME ZONE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);
CREATE INDEX IF NOT EXISTS idx_mobile_purpose ON otp_verifications (mobile, purpose);

-- 8. OTP Logs
CREATE TABLE IF NOT EXISTS otp_logs (
    id SERIAL PRIMARY KEY,
    mobile VARCHAR(15) NOT NULL,
    purpose VARCHAR(50) NOT NULL,
    status VARCHAR(20) NOT NULL,
    ip_address VARCHAR(45),
    details TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);

-- 9. Smart Docs Table (Stores extracted intelligence)
CREATE TABLE IF NOT EXISTS smart_docs (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
    file_id INTEGER REFERENCES files(id) ON DELETE SET NULL,
    doc_type VARCHAR(100) NOT NULL, -- 'Insurance', 'Passport', 'License', 'Warranty'
    doc_number VARCHAR(100), -- Extracted Policy/ID Number
    expiry_date TIMESTAMP WITH TIME ZONE,
    renewal_date TIMESTAMP WITH TIME ZONE,
    issuing_authority VARCHAR(255),
    reminder_enabled BOOLEAN DEFAULT TRUE,
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP
);
CREATE INDEX IF NOT EXISTS idx_smart_docs_user ON smart_docs (user_id);
CREATE INDEX IF NOT EXISTS idx_smart_docs_user ON smart_docs (user_id);
CREATE INDEX IF NOT EXISTS idx_smart_docs_expiry ON smart_docs (expiry_date);

-- 10. Update Users Table for Heartbeat (Dead Man's Switch)
ALTER TABLE users 
ADD COLUMN IF NOT EXISTS last_check_in TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
ADD COLUMN IF NOT EXISTS check_in_frequency_days INTEGER DEFAULT 30,
ADD COLUMN IF NOT EXISTS dead_mans_switch_active BOOLEAN DEFAULT FALSE;

-- 11. Heartbeat Logs
CREATE TABLE IF NOT EXISTS heartbeat_logs (
    id SERIAL PRIMARY KEY,
    user_id INTEGER REFERENCES users(id) ON DELETE CASCADE,
    checked_in_at TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    method VARCHAR(50) DEFAULT 'manual'
);
        `;
    await client.query(schema);
    console.log('Database initialized successfully');
  } catch (err) {
    console.error('Error initializing database', err);
  } finally {
    client.release();
  }
};

export default {
  query: (text: string, params?: any[]) => pool.query(text, params),
};
